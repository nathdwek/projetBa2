-- Put your global variables here
BASE_SPEED=5
SYM_SPEED_COEFF = 0.3 --When a footbot "hits" something, he will pick a temporary speed between 1+this coeff and 1-this coeff time BASE_SPEED
RANDOM_SPEED_TIME = 5 --The number of steps during which the footbot keeps this new random speed
PI=math.pi
abs=math.abs
CONVERGENCE=1 --A number between 0 and 2 (0 means no convergence at all, 2 means strongest convergence possible)
--maximum and minimum value for both are subject to discussion.
OBSTACLE_DIRECTION_DEPENDANCE=0.1
OBSTACLE_PROXIMITY_DEPENDANCE=0.2
MAX_STEPS_BEFORE_LEAVING=150 --At the start of the experiment, each robot will randomly wait for a number of steps between 0 and this number
BATT_BY_STEP = 0.01
RESSOURCEX=400
RESSOURCEY=350
SCANNER_RPM=150














--This function is executed every time you press the 'execute' button
function init()
   speed=BASE_SPEED
   steps_before_leaving=robot.random.uniform(1,MAX_STEPS_BEFORE_LEAVING)
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
   robot.distance_scanner.enable()
   robot.distance_scanner.set_rpm(SCANNER_RPM)
end





--This function is executed at each time step. It must contain the logic of your controller
function step()
   posX, posY, alpha, currentStep=odometry(posX, posY, alpha, currentStep)
   if currentStep>steps_before_leaving then
      batt_rest = batt_rest - BATT_BY_STEP
      obstaclesTable = updateObstaclesTable(obstaclesTable or -1)
      local obstacleProximity, obstacleDirection=closestObstacleDirection(obstaclesTable)
      travels, goalX, goalY=checkGoalReached(posX, posY, goalX, goalY,travels)
      speed, lastHit = move(obstacleProximity, obstacleDirection, posX, posY, alpha, goalX, goalY, speed, lastHit)
      if batt_rest<=0 then
         log(robot.id, ": battery empty")
      end
   end
end

function updateObstaclesTable(obstaclesTable)
   if obstaclesTable == -1 then
      log("hello")
      obstaclesTable={}
   end
   for sensor, reading in pairs(robot.distance_scanner.short_range) do
      obstaclesTable[reading.angle] = reading.distance
   end
   return obstaclesTable
end

function checkGoalReached(posX, posY, goalX, goalY, travels)
   if floorIsBlack() and travels%2==0 and math.sqrt((posX)^2+(posY)^2)>=90 then
      travels=travels+1
      goalX=0
      goalY=0
      log(robot.id, ": travels done so far: ", travels)
      log(robot.id, ": Next Goal is (", goalX, ", ", goalY, ")")
   elseif floorIsBlack() and travels%2==1 and math.sqrt((posX)^2+(posY)^2)<=70 then
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
   if obstacleProximity==30 or abs(obstacleDirection)>2*PI/3 then
      getToGoal(posX, posY, alpha, goalX, goalY, speed)
   else
      speed, lastHit = newRandomSpeed(speed, lastHit)
      obstacleAvoidance(obstacleProximity, obstacleDirection, speed)
   end
   return speed, lastHit
end

function newRandomSpeed(speed, lastHit)
   if currentStep-lastHit > RANDOM_SPEED_TIME then
      speed=robot.random.uniform(1-SYM_SPEED_COEFF,1+SYM_SPEED_COEFF)*BASE_SPEED
   end
   lastHit=currentStep
   return speed, lastHit
end

function odometry(x, y, angle, currentStep)
   x=100*robot.positioning.position.x
   y=100*robot.positioning.position.y
   angle=robot.positioning.orientation.axis.z*robot.positioning.orientation.angle
   return x,y,angle, currentStep+1
end

function closestObstacleDirection(obstaclesTable)
   local obstacleDirection, obstacleProximity, angle, distance
   obstacleProximity=30
   for angle, distance in pairs(obstaclesTable) do
      if (distance<obstacleProximity) and distance>-2 then
         obstacleDirection = angle
         obstacleProximity = distance
      end
   end
   if obstacleProximity==30 then
      obstacleDirection=-1
   end
   if obstacleProximity == -1 then
      obstacleProximity = 0
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
   if obstacleDirection >=0 then --Obstacle is to the left
      vRight=speed*(obstacleDirection/(2*PI/3))^OBSTACLE_DIRECTION_DEPENDANCE
      vRight=vRight*(obstacleProximity/30)^OBSTACLE_PROXIMITY_DEPENDANCE
      vLeft=2*speed-vRight
   else --Obstacle is to the right
      vLeft=speed*(abs(obstacleDirection)/(2*PI/3))^OBSTACLE_DIRECTION_DEPENDANCE
      vLeft=vLeft*(obstacleProximity/30)^OBSTACLE_PROXIMITY_DEPENDANCE
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
   steps_before_leaving=robot.random.uniform(1,MAX_STEPS_BEFORE_LEAVING)
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
   robot.distance_scanner.enable()
   robot.distance_scanner.set_rpm(SCANNER_RPM)
end



--This function is executed only once, when the robot is removedfrom the simulation
function destroy()
   -- put your code here
end
