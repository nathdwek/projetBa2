-- Put your global variables here
BASE_SPEED=5
PI=math.pi
abs=math.abs
CONVERGENCE=1.5
MAX_STEPS_BEFORE_LEAVING=150 --At the start of the experiment, each robot will randomly wait for a number of steps between 0 and this number
BATT_BY_STEP = 0.01
RESSOURCEX=400
RESSOURCEY=350
SCANNER_RPM=75


--This function is executed every time you press the 'execute' button
function init()
   speed=BASE_SPEED
   steps_before_leaving=robot.random.uniform(1,MAX_STEPS_BEFORE_LEAVING)
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
   obstaclesTable={}
   for i=-PI+PI/DIR_NUMBER, PI-PI/DIR_NUMBER, 2*PI/DIR_NUMBER do
      obstaclesTable[i]=151
   end
end





--This function is executed at each time step. It must contain the logic of your controller
function step()
   posX, posY, alpha, currentStep=odometry(currentStep)
   if currentStep>steps_before_leaving then
      batt_rest = batt_rest - BATT_BY_STEP
      obstaclesTable = updateObstaclesTable(obstaclesTable)
      travels, goalX, goalY=checkGoalReached(posX, posY, goalX, goalY,travels)
      move(obstaclesTable, posX, posY, alpha, goalX, goalY)
      if batt_rest<=0 then
         log(robot.id, ": battery empty")
      end
   end
end

function updateObstaclesTable(obstaclesTable)
   local sensor, reading, angle, value, rAngle, rDistance
   for angle, value in pairs(obstaclesTable) do
      newValue=false
      for sensor, reading in pairs(robot.distance_scanner.long_range) do
         rAngle = reading.angle
         rDistance=reading.distance
         if rDistance == -2 then rDistance=151 end
         if abs(angle-rAngle)<PI/DIR_NUMBER then
            if value>rDistance or not newValue then
               obstaclesTable[angle]=rDistance
            end
            newValue = true
         end
      end
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

function move(obstaclesTable, posX, posY, alpha, goalX, goalY)
   local goalDirection=findGoalDirection(posX, posY, goalX, goalY)
   local goalAngle=findGoalAngle(goalDirection, alpha)
   obstacleAvoidance(goalAngle, obstaclesTable)
end

function odometry(currentStep)
   local x=100*robot.positioning.position.x
   local y=100*robot.positioning.position.y
   local angle=robot.positioning.orientation.axis.z*robot.positioning.orientation.angle
   if angle >PI then
      angle = angle - 2*PI
   end
   if angle < -PI then
      angle = angle + 2*PI
   end
   return x,y,angle, currentStep+1
end

function getToGoal(goalAngle)
   if goalAngle>=0 then --goal is to the left
      vLeft=speed*((PI-goalAngle)/PI)^CONVERGENCE
      vRight = 2*speed-vLeft
   else --goal is to the right
      vRight=speed*((PI+goalAngle)/PI)^CONVERGENCE
      vLeft = 2*speed - vRight
   end
   robot.wheels.set_velocity(vLeft, vRight)
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

function findGoalAngle(goalDirection,alpha)
   local goalAngle=goalDirection-alpha
   if goalAngle>PI then
      goalAngle=goalAngle-2*PI
   end
   return goalAngle
end

function obstacleAvoidance(goalAngle, obstaclesTable)
   local bestAngle, bestDistance, angle, distance
   bestDistance = -1
   for angle, distance in pairs(obstaclesTable) do
      if distance>bestDistance or (distance==bestDistance and not bestAngle) or (distance==bestDistance and abs(angle-goalAngle)<abs(bestAngle-goalAngle)) then
         bestDistance = distance
         bestAngle = angle
      end
   end
   getToGoal(bestAngle)
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
   obstaclesTable={}
   for i=-PI+PI/DIR_NUMBER, PI-PI/DIR_NUMBER, 2*PI/DIR_NUMBER do
      obstaclesTable[i]=151
   end
end



--This function is executed only once, when the robot is removedfrom the simulation
function destroy()
   -- put your code here
end
