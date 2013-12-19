-- Put your global variables here
SPEED=5
PI=math.pi
CONVERGENCE=0.7 --A number between 0 and 2 (0 means no convergence at all, 2 means strongest convergence possible)
AVOIDANCE=2 --A number between 1 and 12 (1 means minimum sufficient avoidance, 12 means strongest avoidance)
--maximum and minimum value for both are subject to discussion.
OBSTACLE_PROXIMITY_DEPENDANCE=3
XMIN=-400
XMAX=400
YMIN=-400
YMAX=400
TOLERANCE=50
TRAVELS_MAX=10
BATT_BY_STEP = 0.01
RESSOURCEX=400
RESSOURCEY=350



--Randomize avoidance and convergence (multiply by number between 0.9 and 1.1) to prevent cyclic problems.




--This function is executed every time you press the 'execute' button
function init()
   posX=STARTINGPOSITIONSTABLE[robot.id].posX
   posY=STARTINGPOSITIONSTABLE[robot.id].posY
   alpha=STARTINGPOSITIONSTABLE[robot.id].alpha
   goalX=RESSOURCEX
   goalY=RESSOURCEY
   log("Next Goal is (", goalX, ", ", goalY, ")")
   AXIS_LENGTH=robot.wheels.axis_length
   travels=0
   steps=0
   batt_rest=100
end





--This function is executed at each time step. It must contain the logic of your controller
function step()
   batt_rest = batt_rest - BATT_BY_STEP
   posX, posY, alpha, steps=odometry(posX, posY, alpha, steps)
   local obstacleProximity, obstacleDirection=closestObstacleDirection()
   travels, goalX, goalY=checkGoalReached(posX, posY, goalX, goalY)
   move(obstacleProximity, obstacleDirection, posX, posY, alpha, goalX, goalY)
   if batt_rest<=0 then
      log(robot.id, ": battery empty")
   end
end

function checkGoalReached(posX, posY, goalX, goalY)
   if math.sqrt((posX-goalX)^2+(posY-goalY)^2)<=TOLERANCE then
      goalX, goalY, travels=travelEndHandler(travels)
   end
   return travels, goalX, goalY
end

function travelEndHandler(travels)
   travels=travels+1
   if travels%2==0 then
      batt_rest=100
      goalX=RESSOURCEX
      goalY=RESSOURCEY
   else
      goalX=0
      goalY=0
   end
   log(robot.id, ": travels done so far: ", travels)
   log(robot.id, ": Next Goal is (", goalX, ", ", goalY, ")")
   return goalX, goalY, travels
end

function move(obstacleProximity, obstacleDirection, posX, posY, alpha, goalX, goalY)
   if obstacleProximity==0 then
      getToGoal(posX, posY, alpha, goalX, goalY)
   else
      obstacleAvoidance(obstacleProximity, obstacleDirection)
   end
end

function odometry(x, y, angle, steps)
   local deltaL=robot.wheels.distance_left
   local deltaR=robot.wheels.distance_right
   local deltaG=(deltaL+deltaR)/2
   local deltaAngle=(deltaR-deltaL)/AXIS_LENGTH
   if math.abs(deltaG-SPEED/10)>1E-7 then
      log(robot.id, ": problem: deltaG is: ", deltaG)
   end
   x=x+deltaG*math.cos(angle)
   y=y+deltaG*math.sin(angle)
   angle=angle+deltaAngle
   if angle>2*PI then
      angle=angle-2*PI
   end
   return x,y,angle, steps+1
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
   robot.wheels.set_velocity( (1-CONVERGENCE*coeff)*SPEED, (1+CONVERGENCE*coeff)*SPEED )
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
   if obstacleDirection <= 12 then
      vRight=((1-obstacleProximity)^OBSTACLE_PROXIMITY_DEPENDANCE*obstacleDirection-AVOIDANCE)*SPEED/11
      vLeft=2*SPEED-vRight
   else
      vLeft=((1-obstacleProximity)^OBSTACLE_PROXIMITY_DEPENDANCE*25-AVOIDANCE-obstacleDirection)*SPEED/11
      vRight=2*SPEED-vLeft
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
   posX=STARTINGPOSITIONSTABLE[robot.id].posX
   posY=STARTINGPOSITIONSTABLE[robot.id].posY
   alpha=STARTINGPOSITIONSTABLE[robot.id].alpha
   goalX=RESSOURCEX
   goalY=RESSOURCEY
   log("Next Goal is (", goalX, ", ", goalY, ")")
   travels=0
   steps=0
   batt_rest=100
end



--This function is executed only once, when the robot is removedfrom the simulation
function destroy()
   -- put your code here
end
