-- Put your global variables here
BASE_SPEED=5
MINIMUM_SPEED_COEFF = 0.5 --When a footbot "hits" something, he will pick a temporary speed between this coeff and one time BASE_SPEED
RANDOM_SPEED_TIME = 7 --The number of steps during which the footbot keeps this new random speed
PI=math.pi
CONVERGENCE=0.7 --A number between 0 and 2 (0 means no convergence at all, 2 means strongest convergence possible)
AVOIDANCE=2 --A number between 1 and 12 (1 means minimum sufficient avoidance, 12 means strongest avoidance)
--maximum and minimum value for both are subject to discussion.
OBSTACLE_PROXIMITY_DEPENDANCE=2
MAX_STEPS_BEFORE_LEAVING=150 --At the start of the experiment, each robot will randomly wait for a number of steps between 0 and this number
BATT_BY_STEP = 0.01
RESSOURCEX=400
RESSOURCEY=350



--This function is executed every time you press the 'execute' button
function init()
   speed=BASE_SPEED
   steps_before_leaving=robot.random.uniform(0,MAX_STEPS_BEFORE_LEAVING)
   posX=STARTINGPOSITIONSTABLE[robot.id].posX
   posY=STARTINGPOSITIONSTABLE[robot.id].posY
   alpha=STARTINGPOSITIONSTABLE[robot.id].alpha
   goalX=RESSOURCEX
   goalY=RESSOURCEY
   log("Next Goal is (", goalX, ", ", goalY, ")")
   AXIS_LENGTH=robot.wheels.axis_length
   travels=0
   currentStep=0
   batt_rest=100
   lastHit=0
end





--This function is executed at each time step. It must contain the logic of your controller
function step()
   batt_rest = batt_rest - BATT_BY_STEP
   posX, posY, alpha, currentStep=odometry(posX, posY, alpha, currentStep)
   if currentStep<steps_before_leaving then
      return
   end
   local obstacleProximity, obstacleDirection=closestObstacleDirection()
   travels, goalX, goalY=checkGoalReached(posX, posY, goalX, goalY,travels)
   speed, lastHit = move(obstacleProximity, obstacleDirection, posX, posY, alpha, goalX, goalY, speed, lastHit)
   if batt_rest<=0 then
      log(robot.id, ": battery empty")
   end
end

function checkGoalReached(posX, posY, goalX, goalY, travels)
   if floorIsBlack() and travels%2==1 and math.sqrt((posX)^2+(posY)^2)>=90 then
      travels=travels+1
      goalX=0
      goalY=0
      log(robot.id, ": travels done so far: ", travels)
      log(robot.id, ": Next Goal is (", goalX, ", ", goalY, ")")
   elseif floorIsBlack() and travels%2==0 and math.sqrt((posX)^2+(posY)^2)<=70 then
      travels=travels+1
      batt_rest=100
      goalX=RESSOURCEX
      goalY=RESSOURCEY
      log(robot.id, ": travels done so far: ", travels)
      log(robot.id, ": Next Goal is (", goalX, ", ", goalY, ")")
   end
   return travels, goalX, goalY
end

function floorIsBlack()
   for i=1,12 do
      if robot.base_ground[i].value==1 then
         return false
      end
   return true
   end
end

function move(obstacleProximity, obstacleDirection, posX, posY, alpha, goalX, goalY, speed, lastHit)
   if obstacleProximity==0 then
      getToGoal(posX, posY, alpha, goalX, goalY, speed)
   else
      speed, lastHit = newRandomSpeed(speed, lastHit)
      obstacleAvoidance(obstacleProximity, obstacleDirection, speed)
   end
   return speed, lastHit
end

function newRandomSpeed(speed, lastHit)
   if currentStep-lastHit > RANDOM_SPEED_TIME then
      speed=robot.random.uniform(MINIMUM_SPEED_COEFF,1)*BASE_SPEED
   end
   lastHit=currentStep
   return speed, lastHit
end

function odometry(x, y, angle, currentStep)
   local deltaL=robot.wheels.distance_left
   local deltaR=robot.wheels.distance_right
   local deltaG=(deltaL+deltaR)/2
   local deltaAngle=(deltaR-deltaL)/AXIS_LENGTH
   if math.abs(deltaG-speed/10)>1E-7 then
      log(robot.id, ": problem: deltaG is: ", deltaG)
   end
   x=x+deltaG*math.cos(angle)
   y=y+deltaG*math.sin(angle)
   angle=angle+deltaAngle
   if angle>2*PI then
      angle=angle-2*PI
   end
   return x,y,angle, currentStep+1
end

function closestObstacleDirection()
   local obstacleDirection = 1
   local obstacleProximity = robot.proximity[1].value
   for i=2,24 do
      if obstacleProximity < robot.proximity[i].value then
         obstacleDirection = i
         obstacleProximity = robot.proximity[i].value
      end
   end
   return obstacleProximity, obstacleDirection
end

function getToGoal(posX, posY, alpha, goalX, goalY)
   goalDirection=findGoalDirection(posX, posY, goalX, goalY)
   goalAngle=findGoalAngle(goalDirection, alpha)
   local coeff=goalAngle/PI
   robot.wheels.set_velocity( (1-CONVERGENCE*coeff)*speed, (1+CONVERGENCE*coeff)*speed )
end

function findGoalDirection(posX, posY, goalX, goalY)
   local deltaX=goalX-posX
   local deltaY=goalY-posY
   local goalDirection=math.atan(deltaY/deltaX)
   if deltaX<0 then
      goalDirection=goalDirection+PI
   end
   if goalDirection<0 then
      goalDirection=goalDirection+2*PI
   end
   return goalDirection
end

function findGoalAngle(posX, posY, goalX, goalY)
   local goalAngle=goalDirection-alpha
   if goalAngle>PI then
      goalAngle=goalAngle-2*PI
   end
   return goalAngle
end

function obstacleAvoidance(obstacleProximity,obstacleDirection)
   local vLeft, vRight
   if obstacleProximity==1 then
      logerr(robot.id, ": Odometry data might be offset")
   end
   if obstacleDirection <= 12 then --Obstacle is to the left
      vRight=((1-obstacleProximity)^OBSTACLE_PROXIMITY_DEPENDANCE*obstacleDirection-AVOIDANCE)*speed/11
      vLeft=2*speed-vRight
   else --Obstacle is to the right
      vLeft=((1-obstacleProximity)^OBSTACLE_PROXIMITY_DEPENDANCE*(25-obstacleDirection)-AVOIDANCE)*speed/11
      vRight=2*speed-vLeft
   end
   robot.wheels.set_velocity(vLeft, vRight)
end

--[[This function is executed every time you press the 'reset'
   button in the GUI. It is supposed to restore the state
   of the controller to whatever it was right after init() was
   called. The state of sensors and actuators is reset
   automatically by ARGoS.
]]
function reset()
   speed=BASE_SPEED
   steps_before_leaving=robot.random.uniform(0,MAX_STEPS_BEFORE_LEAVING)
   posX=STARTINGPOSITIONSTABLE[robot.id].posX
   posY=STARTINGPOSITIONSTABLE[robot.id].posY
   alpha=STARTINGPOSITIONSTABLE[robot.id].alpha
   goalX=RESSOURCEX
   goalY=RESSOURCEY
   log("Next Goal is (", goalX, ", ", goalY, ")")
   AXIS_LENGTH=robot.wheels.axis_length
   travels=0
   currentStep=0
   batt_rest=100
   lastHit=0
end



--This function is executed only once, when the robot is removedfrom the simulation
function destroy()
   -- put your code here
end
