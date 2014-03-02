-- Put your global variables here
BASE_SPEED=30
MIN_SPEED_COEFF = 0.6 --When a footbot "hits" something, he will pick a temporary speed between this coeff and 1 times BASE_SPEED
RANDOM_SPEED_TIME = 30 --The number of steps during which the footbot keeps this new random speed
PI=math.pi
abs=math.abs
CONVERGENCE=0.7
MAX_STEPS_BEFORE_LEAVING=150 --At the start of the experiment, each robot will randomly wait for a number of steps between 0 and this number
BATT_BY_STEP = .2
SCANNER_RPM=75
DIR_NUMBER = 15
EXPL_DIR_NUMBER = 24
OBSTACLE_PROXIMITY_DEPENDANCE=.5
OBSTACLE_DIRECTION_DEPENDANCE=3
RESSOURCEX=400
RESSOURCEY=350


--TODO:DO NOT RECEIVE THE SAME MESSAGE MULTIPLE TIMES


--This function is executed every time you press the 'execute' button
function init()
   speed=BASE_SPEED
   steps_before_leaving=robot.random.uniform(1,MAX_STEPS_BEFORE_LEAVING)
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
   shortObstaclesTable={}
   for i=-PI+PI/EXPL_DIR_NUMBER, PI-PI/EXPL_DIR_NUMBER, 2*PI/EXPL_DIR_NUMBER do
      shortObstaclesTable[i]=151
   end
   explore=true
   if explore then
      robot.wheels.set_velocity(BASE_SPEED,BASE_SPEED)
   end
   goalX=RESSOURCEX
   goalY=RESSOURCEY
   ressources={}
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
   if batt_rest==0 then
      BASE_SPEED=0
      logerr("batt empty")
   end
   if currentStep%200==0 then
      log(#ressources)
   end
end

function doMine(posX,posY,alpha,currentStep)
   local obstacleProximity, obstacleDirection
   if currentStep>steps_before_leaving then
      obstaclesTable = updateObstaclesTable("long_range",obstaclesTable)
      shortObstaclesTable = updateObstaclesTable("short_range",shortObstaclesTable)
      obstacleProximity, obstacleDirection=closestObstacleDirection(shortObstaclesTable)
      travels, goalX, goalY=checkGoalReached(posX, posY, goalX, goalY,travels)
      speed, lastHit = move(obstaclesTable, posX, posY, alpha, goalX, goalY, obstacleProximity, obstacleDirection, lastHit)
      local msg
      for i=1,#robot.range_and_bearing do
         if robot.range_and_bearing[i].data[1]==1 then
            msg=robot.range_and_bearing[i].data
            ressources[#ressources+1]={msg[2]*(100*msg[4]+msg[6]),msg[3]*(100*msg[5]+msg[7])}
         end
      end
   end
end

function doExplore(posX,posY,alpha,currentStep)
   if floorIsBlack() and math.sqrt((posX)^2+(posY)^2)>=90 then
      ressources[#ressources+1]={posX,posY}
      explore=false
      wayBack=true
      goalX=0
      goalY=0
      robot.range_and_bearing.set_data({1,sgn(posX),sgn(posY),math.floor(abs(posX)/100),math.floor(abs(posY)/100),abs(posX)%100,abs(posY)%100,0,0,0})
   end
   local msg
   for i=1,#robot.range_and_bearing do
      if robot.range_and_bearing[i].data[1]==1 then
         msg=robot.range_and_bearing[i].data
         ressources[#ressources+1]={msg[2]*(100*msg[4]+msg[6]),msg[3]*(100*msg[5]+msg[7])}
         wayBack=true
         explore=false
         goalX=0
         goalY=0
      end
   end
   if floorIsBlack() and math.sqrt((posX)^2+(posY)^2)<=70 then
      batt_rest=100
   end
   local obstacleProximity, obstacleDirection
   shortObstaclesTable = updateObstaclesTable("short_range", shortObstaclesTable)
   obstacleProximity, obstacleDirection=closestObstacleDirection(shortObstaclesTable)
   if batt_rest-math.sqrt(posX^2+posY^2)/BASE_SPEED<=10 then --values to discuss
      obstaclesTable = updateObstaclesTable("long_range",obstaclesTable)
      speed, lastHit = move(obstaclesTable, posX, posY, alpha, 0, 0, obstacleProximity, obstacleDirection, lastHit)
   else
      gasLike(obstacleProximity, obstacleDirection, alpha)
   end
end

function sgn(n)
   local sgn
   if n==0 then
      sgn=0
   else
      if n==abs(n) then
         sgn=1
      else
         sgn=-1
      end
   end
   return sgn
end

function gasLike(obstacleProximity, obstacleDirection, alpha)
   local goalAngle
   if obstacleProximity < 20 and not(obstacleDirection<-PI/2 or obstacleDirection>PI/2) and not wasHit then
      wasHit = true
      newDirection = alpha+rebound(alpha,obstacleDirection)
      if newDirection<-PI then newDirection = newDirection+2*PI end
      if newDirection >PI then newDirection = newDirection-2*PI end
   end
   if wasHit then
      if abs(alpha-newDirection)<0.3 then
         robot.wheels.set_velocity(BASE_SPEED, BASE_SPEED)
         wasHit=false
      else
         goalAngle=newDirection-alpha
         if goalAngle<-PI then goalAngle = goalAngle+2*PI end
         if goalAngle >PI then goalAngle = goalAngle-2*PI end
         getToGoal(goalAngle)
      end
   end
end

function rebound(alpha, obstacleDirection)
   if obstacleDirection<=12 then --obstacle is to the left
      newAngle = -2*(PI/2-obstacleDirection)
   else
      newAngle = 2*(PI/2-obstacleDirection)
   end
   if newAngle>PI then newAngle = newAngle-2*PI end
   if newAngle<-PI then newAngle = newAngle+2*PI end
   return newAngle
end

function updateObstaclesTable(which, tabl)
   local sensor, reading, angle, value, rAngle, rDistance
   for angle, value in pairs(tabl) do
      newValue=false
      for sensor, reading in pairs(robot.distance_scanner[which]) do
         rAngle = reading.angle
         rDistance=reading.distance
         if rDistance == -2 then rDistance=151 end
         if rDistance == -1 then rDistance=0 end
         if abs(angle-rAngle)<PI/DIR_NUMBER then
            if value>rDistance or not newValue then
               tabl[angle]=rDistance
               newValue = true
            end
         end
      end
   end
   return tabl
end

function closestObstacleDirection(tabl)
   local obstacleDirection, obstacleProximity, dir, prox
   for dir, prox in pairs(tabl) do
      if not obstacleProximity or prox<obstacleProximity then
         obstacleDirection = dir
         obstacleProximity = prox
      end
   end
   return obstacleProximity, obstacleDirection
end

function checkGoalReached(posX, posY, goalX, goalY, travels)
   local pickSource
   if floorIsBlack() and not wayBack and math.sqrt((posX)^2+(posY)^2)>=90 then
      if math.sqrt((posX-goalX)^2+(posY-goalY)^2)>=25 then
         ressources[#ressources+1]={posX,posY}
         robot.range_and_bearing.set_data({1,sgn(posX),sgn(posY),math.floor(abs(posX)/100),math.floor(abs(posY)/100),abs(posX)%100,abs(posY)%100,0,0,0})
      end
      wayBack=true
      goalX=0
      goalY=0
      log(robot.id, ": travels done so far: ", travels)
      log(robot.id, ": Next Goal is (", goalX, ", ", goalY, ")")
   elseif floorIsBlack() and wayBack and math.sqrt((posX)^2+(posY)^2)<=70 then
      wayBack=false
      travels=travels+1
      batt_rest=100
      pickSource=robot.random.uniform_int(1,#ressources+1)
      goalX=ressources[pickSource][1]
      goalY=ressources[pickSource][2]
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
   if obstacleProximity >= 10 then
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

function closeObstacleAvoidance(prox, dir)
   local vLeft, vRight
   if dir >= 0 then --Obstacle is to the left
      vRight=(prox/30)^OBSTACLE_PROXIMITY_DEPENDANCE*(dir/PI)^OBSTACLE_DIRECTION_DEPENDANCE*speed
      vLeft=2*speed-vRight
   else --Obstacle is to the right
      vLeft=(prox/30)^OBSTACLE_PROXIMITY_DEPENDANCE*(-dir/PI)^OBSTACLE_DIRECTION_DEPENDANCE*speed
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
   shortObstaclesTable={}
   for i=-PI+PI/EXPL_DIR_NUMBER, PI-PI/EXPL_DIR_NUMBER, 2*PI/EXPL_DIR_NUMBER do
      shortObstaclesTable[i]=151
   end
   explore=true
   if explore then
      robot.wheels.set_velocity(BASE_SPEED,BASE_SPEED)
      wasHit=false
   end
   BASE_SPEED=30
   goalX=RESSOURCEX
   goalY=RESSOURCEY
   ressources={}
end



--This function is executed only once, when the robot is removedfrom the simulation
function destroy()
   -- put your code here
end
