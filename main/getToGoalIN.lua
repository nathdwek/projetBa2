-- Put your global variables here
BASE_SPEED=30
MIN_SPEED_COEFF = 0.6 --When a footbot "hits" something, he will pick a temporary speed between this coeff and 1 times BASE_SPEED
RANDOM_SPEED_TIME = 30 --The number of steps during which the footbot keeps this new random speed
PI=math.pi
abs=math.abs
CONVERGENCE=1
BATT_BY_STEP = .2
SCANNER_RPM=75
DIR_NUMBER = 15
EXPL_DIR_NUMBER = 20
EXPL_CONV = 3
OBSTACLE_PROXIMITY_DEPENDANCE=.25
OBSTACLE_DIRECTION_DEPENDANCE=.25
MINE_PROB_WHEN_SRC_RECVD=.2
ORGN_SRC_DST=80
INIT_BATT_SEC=25
EMER_DIR_DEP=1
EMER_PROX_DEP=1

--TODO:DAT REFACTOR...


--This function is executed every time you press the 'execute' button
function init()
   speed=BASE_SPEED
   AXIS_LENGTH=robot.wheels.axis_length
   travels=0
   currentStep=0
   battery=100
   backForBattery=false
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
   ressources={}
   if explore then
      robot.wheels.set_velocity(BASE_SPEED,BASE_SPEED)
   else
      sourceId,goalX,goalY=chooseNewSource(ressources)
   end
   batterySecurity=INIT_BATT_SEC
end





--This function is executed at each time step. It must contain the logic of your controller
function step()
   --[[for key, value in pairs(ressources) do
      for key2, value2 in pairs(value) do
         log(key2)
         log(value2)
      end
   end]]
   local obstacleProximity, obstacleDirection, onSource, foundSource, backHome, gotSource, emerProx, emerDir
   obstacleProximity, obstacleDirection, onSource, foundSource, backHome, gotSource, emerProx, emerDir = doCommon()
   if emerProx>0 then
      emergencyAvoidance(emerProx, emerDir)
   elseif explore then
      doExplore(obstacleProximity, obstacleDirection, foundSource, gotSource)
   else
      doMine(obstacleProximity, obstacleDirection, onSource, backHome, foundSource)
   end
end

function doCommon()
   local obstacleProximity, obstacleDirection, onSource, foundSource, backHome, gotSource, emerProx, emerDir
   odometry()
   onSource, foundSource, backHome = checkGoalReached()
   gotSource = listen()
   shortObstaclesTable = updateObstaclesTable("short_range",shortObstaclesTable)
   obstacleProximity, obstacleDirection=closestObstacleDirection(shortObstaclesTable)
   battery=battery-BATT_BY_STEP
   backForBattery = backForBattery or battery-batterySecurity*BATT_BY_STEP*math.sqrt(posX^2+posY^2)/BASE_SPEED<10
   emerProx, emerDir=readProxSensor()
   if battery==0 then
      BASE_SPEED=0
      logerr("batt empty")
   end
   if currentStep%5000==0 then
      log(travels)
   end
   return obstacleProximity, obstacleDirection, onSource, foundSource, backHome,gotSource, emerProx, emerDir
end

function readProxSensor()
   local emerDir = 1
   local emerProx = robot.proximity[1].value
   for i=2,24 do
      if emerProx < robot.proximity[i].value or (emerProx == robot.proximity[i].value and abs(12-emerDir)<abs(12-i)) then
         emerDir = i
         emerProx = robot.proximity[i].value
      end
   end
   return emerProx, emerDir
end

function emergencyAvoidance(emerProx,emerDir)
   local vLeft, vRight
   if emerDir <= 12 then --Obstacle is to the left
      vRight=((1-emerProx)^EMER_PROX_DEP*emerDir-EMER_DIR_DEP)*speed/11
      vLeft=2*speed-vRight
   else --Obstacle is to the right
      vLeft=((1-emerProx)^EMER_PROX_DEP*(25-emerDir)-EMER_DIR_DEP)*speed/11
      vRight=2*speed-vLeft
   end
   robot.wheels.set_velocity(vLeft, vRight)
end

function doMine(obstacleProximity, obstacleDirection, onSource, backHome, foundSource)
   if foundSource then
      broadcastSource(posX,posY)
   end
   if onSource then
      if goalX~=0 and goalY~=0 then
         evalSource(sourceId, battery)
      end
      goalX=0
      goalY=0
   elseif backHome then
      sourceId,goalX,goalY=chooseNewSource(ressources)
      travels=travels+1
      log(robot.id, ": travels done so far: ", travels)
      log(robot.id, ": Next Goal is (", goalX, ", ", goalY, ")")
   end
   if backForBattery then
      move(obstaclesTable, obstacleProximity, obstacleDirection,0,0)
   else
      obstaclesTable = updateObstaclesTable("long_range",obstaclesTable)
      move(obstaclesTable, obstacleProximity, obstacleDirection,goalX,goalY)
   end
end

function evalSource(sourceId, battery)
   if battery>60 then
      ressources[sourceId].score=ressources[sourceId].score+(1-ressources[sourceId].score)*battery/100
   else
      ressources[sourceId].score=ressources[sourceId].score-ressources[sourceId].score*(100-battery)/100
   end
   log(ressources[sourceId].score)
end

function doExplore(obstacleProximity, obstacleDirection, foundSource, gotSource, enoughBatt)
   if foundSource then
      broadcastSource(posX,posY)
      explore=false
      goalX,goalY=0,0
   end
   if gotSource then
      explore,goalX,goalY=robot.random.uniform()>MINE_PROB_WHEN_SRC_RECVD,0,0
   end
   if not backForBattery then
      gasLike(obstacleProximity, obstacleDirection)
   else
      obstaclesTable = updateObstaclesTable("long_range",obstaclesTable)
      move(obstaclesTable, obstacleProximity, obstacleDirection,0,0)
   end
end

function broadcastSource(x,y)
   local msg=sourceIn(x,y)
   robot.range_and_bearing.set_data(msg)
end


function sourceIn(x,y)
   local msgOut={1,sgnIn(x),sgnIn(y),math.floor(abs(x)/100),math.floor(abs(y)/100),math.floor(abs(x)%100),math.floor(abs(y)%100),0,0,0}
   return msgOut
end

function sourceOut(msg)
   local x,y
   x=100*msg[4]+msg[6]
   if msg[2]==2 then
      x=-x
   end
   y=100*msg[5]+msg[7]
   if msg[3]==2 then
      y=-y
   end
   return {x,y}
end

function listen()
   local gotSource=false
   for i=1,#robot.range_and_bearing do
      if robot.range_and_bearing[i].data[1]==1 then
         local source = sourceOut(robot.range_and_bearing[i].data)
         if sourceIsOriginal(source[1],source[2],ressources) then
            source.score=.5
            ressources[#ressources+1]=source
            gotSource=true
         end
      end
   end
   return gotSource
end

function gasLike(obstacleProximity, obstacleDirection)
   local goalAngle
   if obstacleProximity < 30 and not(obstacleDirection<-PI/2 or obstacleDirection>PI/2) and not wasHit then
      wasHit = true
      newDirection = alpha+rebound(alpha,obstacleDirection)
      newDirection=setCoupure(newDirection)
   end
   robot.wheels.set_velocity(BASE_SPEED, BASE_SPEED)
   if wasHit then
      if abs(alpha-newDirection)<0.2 then
         wasHit=false
      else
         goalAngle=newDirection-alpha
         goalAngle=setCoupure(goalAngle)
         getToGoal(goalAngle, EXPL_CONV)
      end
   end
end

function rebound(alpha, obstacleDirection)
   if obstacleDirection<=12 then --obstacle is to the left
      newAngle = -2*(PI/2-obstacleDirection)
   else
      newAngle = 2*(PI/2-obstacleDirection)
   end
   newAngle=setCoupure(newAngle)
   return newAngle
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

function sourceIsOriginal(x, y, rsc)
   local i=1
   local orgn=true
   while i<=#ressources and orgn do
      orgn=(math.sqrt((rsc[i][1]-x)^2 + (rsc[i][2]-y)^2)>ORGN_SRC_DST)
      i=i+1
   end
   return orgn
end


function chooseNewSource(rsc)
   local sourceChosen=false
   local pickSource
   while not sourceChosen do
      pickSource=robot.random.uniform_int(1,#rsc+1)
      sourceChosen=robot.random.uniform()<rsc[pickSource].score
   end
   local x=rsc[pickSource][1]
   local y=rsc[pickSource][2]
   return pickSource,x, y
end

function checkGoalReached()
   local foundSource, onSource, backHome=false,false,false
   if floorIsBlack() and math.sqrt((posX)^2+(posY)^2)>=90 then
      if sourceIsOriginal(posX,posY, ressources) then
         ressources[#ressources+1]={posX,posY,score=.5}
         sourceId=#ressources
         foundSource=true
      end
      onSource=true
   elseif floorIsBlack() and math.sqrt((posX)^2+(posY)^2)<=70 then
      if goalX==0 and goalY==0 then
         backHome=true
      end
      if backForBattery then
         batterySecurity=updateBattCoeff(battery,batterySecurity)
         backForBattery=false
      end
      battery=100
   end
   return onSource, foundSource, backHome
end

function updateBattCoeff(battery, batterySecurity)
   if battery>10 then
      batterySecurity=batterySecurity-(battery-10)*.1
   else
      batterySecurity=batterySecurity-(battery-10)*.1
   end
   --log("bSec ",batterySecurity)
   return batterySecurity
end

function floorIsBlack()
   for i=1,12 do
      if robot.base_ground[i].value==1 then
         return false
      end
   return true
   end
end

function move(obstaclesTable, obstacleProximity, obstacleDirection, goalX,goalY)
   if obstacleProximity >= 30 then
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

function getToGoal(goalAngle, conv)
   if goalAngle>=0 then --goal is to the left
      vLeft=speed*((PI-goalAngle)/PI)^conv
      vRight = 2*speed-vLeft
   else --goal is to the right
      vRight=speed*((PI+goalAngle)/PI)^conv
      vLeft = 2*speed - vRight
   end
   robot.wheels.set_velocity(vLeft, vRight)
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
   getToGoal(bestAngle, CONVERGENCE)
end

--[[This function is executed every time you press the 'reset'
   button in the GUI. It is supposed to restore the state
   of the controller to whatever it was right after init() was
   called. The state of sensors and actuators is reset
   automatically by ARGoS.
]]
function reset()
   speed=BASE_SPEED
   BASE_SPEED=30
   goalX=RESSOURCEX
   goalY=RESSOURCEY
   log("Next Goal is (", goalX, ", ", goalY, ")")
   travels=0
   currentStep=0
   battery=100
   backForBattery=false
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
   ressources={}
   if explore then
      robot.wheels.set_velocity(BASE_SPEED,BASE_SPEED)
      wasHit=false
   else
      sourceId, goalX,goalY=chooseNewSource(ressources)
   end
   batterySecurity=INIT_BATT_SEC
end

function sgnIn(n)
   local sgn
   if n==0 then
      sgn=0
   else
      if n==abs(n) then
         sgn=1
      else
         sgn=2
      end
   end
   return sgn
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

function odometry()
   posX=100*robot.positioning.position.x
   posY=100*robot.positioning.position.y
   alpha=robot.positioning.orientation.axis.z*robot.positioning.orientation.angle
   alpha=setCoupure(alpha)
   currentStep=currentStep+1
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

function setCoupure(angle)
   if angle<-PI then angle = angle+2*PI end
   if angle >PI then angle = angle-2*PI end
   return angle
end



--This function is executed only once, when the robot is removedfrom the simulation
function destroy()
   -- put your code here
end
