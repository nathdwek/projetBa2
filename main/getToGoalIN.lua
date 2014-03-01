-- Put your global variables here
BASE_SPEED=30
MIN_SPEED_COEFF = 0.6 --When a footbot "hits" something, he will pick a temporary speed between this coeff and 1 times BASE_SPEED
RANDOM_SPEED_TIME = 30 --The number of steps during which the footbot keeps this new random speed
PI=math.pi
abs=math.abs
CONVERGENCE=0.7
MAX_STEPS_BEFORE_LEAVING=150 --At the start of the experiment, each robot will randomly wait for a number of steps between 0 and this number
BATT_BY_STEP = 0.2
SCANNER_RPM=75
DIR_NUMBER = 15
OBSTACLE_PROXIMITY_DEPENDANCE=1
AVOIDANCE=2


--This function is executed every time you press the 'execute' button
function init()
   speed=BASE_SPEED
   steps_before_leaving=robot.random.uniform(1,MAX_STEPS_BEFORE_LEAVING)
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
   explore=true
   if explore then
      robot.wheels.set_velocity(BASE_SPEED,BASE_SPEED)
   end
end





--This function is executed at each time step. It must contain the logic of your controller
function step()
   posX, posY, alpha, currentStep=odometry(currentStep)
   if explore then
      doExplore(posX,posY,alpha,currentStep)
   else
      doMine(posX,posY,alpha,currentStep)
   end
   if currentStep%5000==0 then
      log(travels)
   end
   batt_rest = batt_rest - BATT_BY_STEP
   if batt_rest<=0 then
      BASE_SPEED=0
   end
end

function doMine(posX,posY,alpha,currentStep)
   local obstacleProximity, obstacleDirection
   if currentStep>steps_before_leaving then
      obstaclesTable = updateObstaclesTable(obstaclesTable)
      obstacleProximity, obstacleDirection=closestObstacleDirection()
      travels, goalX, goalY=checkGoalReached(posX, posY, goalX, goalY,travels)
      speed, lastHit = move(obstaclesTable, posX, posY, alpha, goalX, goalY, obstacleProximity, obstacleDirection, lastHit)
   end
end

function doExplore(posX,posY,alpha,currentStep)
   if floorIsBlack() and math.sqrt((posX)^2+(posY)^2)>=90 then
      RESSOURCEX=posX
      RESSOURCEY=posY
      explore=false
      goalX=0
      goalY=0
   end
   if floorIsBlack() and math.sqrt((posX)^2+(posY)^2)<=70 then
      batt_rest=100
   end
   local obstacleProximity, obstacleDirection
   obstacleProximity, obstacleDirection=closestObstacleDirection()
   if batt_rest-5*math.sqrt(posX^2+posY^2)/BASE_SPEED<=10 then
      obstaclesTable = updateObstaclesTable(obstaclesTable)
      speed, lastHit = move(obstaclesTable, posX, posY, alpha, 0, 0, obstacleProximity, obstacleDirection, lastHit)
   else
      gasLike(obstacleProximity, obstacleDirection, alpha)
   end
end

function gasLike(obstacleProximity, obstacleDirection, alpha)
   if obstacleProximity > 0 and not(obstacleDirection>6 and obstacleDirection<18) and not wasHit then
      wasHit = true
      newAngle = rebound(alpha,obstacleDirection)
      newDirection = alpha+newAngle
      if newDirection<-PI then newDirection = newDirection+2*PI end
      if newDirection >PI then newDirection = newDirection-2*PI end
   end
   if wasHit then
      if abs(alpha-newDirection)<0.3 then
         robot.wheels.set_velocity(BASE_SPEED, BASE_SPEED)
         wasHit=false
      else
         getToGoal(newAngle)
      end
   end
end

function rebound(alpha, obstacleDirection)
   if obstacleDirection<=12 then --obstacle is to the left
      newAngle = -2*(PI/2-PI*(obstacleDirection-0.5)/12)
   else
      newAngle = 2*(PI/2-PI*(24.5-obstacleDirection)/12)
   end
   if newAngle>PI then newAngle = newAngle-2*PI end
   if newAngle<-PI then newAngle = newAngle+2*PI end
   return newAngle
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

function move(obstaclesTable, posX, posY, alpha, goalX, goalY, obstacleProximity, obstacleDirection, lastHit)
   if obstacleProximity == 0 then
      if not lastHit or currentStep-lastHit < RANDOM_SPEED_TIME then
         speed=BASE_SPEED
      end
      local goalDirection=findGoalDirection(posX, posY, goalX, goalY)
      local goalAngle=findGoalAngle(goalDirection, alpha)
      obstacleAvoidance(goalAngle, obstaclesTable)
   else
      speed, lastHit = newRandomSpeed(BASE_SPEED, lastHit)
      closeObstacleAvoidance(obstacleProximity, obstacleDirection)
   end
   return speed, lastHit
end

function newRandomSpeed(lastHit)
   if not lastHit or currentStep-RANDOM_SPEED_TIME > lastHit then
      speed=robot.random.uniform(MIN_SPEED_COEFF,1)*BASE_SPEED
   end
   lastHit=currentStep
   return speed, lastHit
end

function closeObstacleAvoidance(obstacleProximity,obstacleDirection)
   local vLeft, vRight
   if obstacleDirection <= 12 then --Obstacle is to the left
      vRight=((1-obstacleProximity)^OBSTACLE_PROXIMITY_DEPENDANCE*obstacleDirection-AVOIDANCE)*speed/11
      vLeft=2*speed-vRight
   else --Obstacle is to the right
      vLeft=((1-obstacleProximity)^OBSTACLE_PROXIMITY_DEPENDANCE*(25-obstacleDirection)-AVOIDANCE)*speed/11
      vRight=2*speed-vLeft
   end
   robot.wheels.set_velocity(vLeft, vRight)
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
   if explore then
      robot.wheels.set_velocity(BASE_SPEED,BASE_SPEED)
      wasHit=false
   end
end



--This function is executed only once, when the robot is removedfrom the simulation
function destroy()
   -- put your code here
end
