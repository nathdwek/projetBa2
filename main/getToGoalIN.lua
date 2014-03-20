-- Put your global variables here
BASE_SPEED=30
PI=math.pi
abs=math.abs

CONVERGENCE=1
BATT_BY_STEP =.1
SCANNER_RPM=75
DIR_NUMBER = 9
EXPL_DIR_NUMBER = 20
EXPL_CONV = 3
OBSTACLE_PROXIMITY_DEPENDANCE=.25
OBSTACLE_DIRECTION_DEPENDANCE=.25
MINE_PROB_WHEN_SRC_RECVD=.2
ORGN_SRC_DST=80
INIT_BATT_SEC=20
IDEAL_NEST_BATT=20
EPSILONGREED=0.1
EMER_DIR_DEP=1
EMER_PROX_DEP=1
MIN_SPEED_COEFF = 0.6 --When a footbot "hits" something, he will pick a temporary speed between this coeff and 1 times BASE_SPEED
RANDOM_SPEED_TIME = 30 --The number of steps during which the footbot keeps this new random speed




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
   explore=false
   ressources={{400,350,bSpent=0,score=1,travels=0},{420,-420,score=1,bSpent=0,travels=0},{-250,0,score=1,bSpent=0,travels=0}}
   if explore then
      robot.wheels.set_velocity(BASE_SPEED,BASE_SPEED)
   else
      sourceId,goalX,goalY=chooseNewSource(ressources)
   end
   batterySecurity=INIT_BATT_SEC
end





--This function is executed at each time step. It must contain the logic of your controller
function step()
   if currentStep%5000==4999 then
      for key, val in pairs(ressources) do
         log(robot.id," :travels for source (", val[1], ",", val[2], ") : ", val.travels)
      end
   end
   local obstacleProximity, obstacleDirection, onSource, foundSource, backHome, gotSource, emerProx, emerDir
   obstacleProximity, obstacleDirection, onSource, foundSource, backHome, gotSource, emerProx, emerDir = doCommon()
   if emerProx>0 then
      emergencyAvoidance(emerProx, emerDir)
   elseif explore then
      doExplore(obstacleProximity, obstacleDirection, foundSource, gotSource)
   else
      doMine(obstacleProximity, obstacleDirection, onSource, backHome)
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
   backForBattery = backForBattery or battery-batterySecurity*BATT_BY_STEP*math.sqrt(posX^2+posY^2)/BASE_SPEED<IDEAL_NEST_BATT
   emerProx, emerDir=readProxSensor()
   if #ressources>=1 then
      broadcastSource(chooseSourceToBroadcast())
   end
   if battery<0 then
      if BASE_SPEED~=0 then
         BASE_SPEED,speed=0,0
         logerr(robot.id, " batt empty")
      end
   end
   return obstacleProximity, obstacleDirection, onSource, foundSource, backHome,gotSource, emerProx, emerDir
end

function chooseSourceToBroadcast()
   local i=(currentStep%#ressources)+1
   return ressources[i][1],ressources[i][2]
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

function doMine(obstacleProximity, obstacleDirection, onSource, backHome)
   if onSource then
      if not hasMined then
         ressources[sourceId].travels=ressources[sourceId].travels +1
         travels=travels+1
         evalSource(sourceId, battery)
         goalX,goalY=0,0
      end
      hasMined=true
   elseif backHome then
      if hasMined then
         hasMined=false
      end
      sourceId,goalX,goalY=chooseNewSource(ressources)
   elseif backForBattery then
      if goalX~=0 and goalY~=0 then
         goalX,goalY=0,0
         evalSource(sourceId, 0)
      end
   end
   obstaclesTable = updateObstaclesTable("long_range",obstaclesTable)
   move(obstaclesTable, obstacleProximity, obstacleDirection,goalX,goalY)
end

function evalSource(sourceId, battery)
   ressources[sourceId].bSpent=ressources[sourceId].bSpent+(100-battery)
   ressources[sourceId].score=ressources[sourceId].travels/ressources[sourceId].bSpent
end

function placeMaxAtOne(rsc)
   if #rsc>1 then
      local maxes={1}
      local i
      for i=2,#rsc do
         if rsc[i].score>rsc[maxes[1]].score then
            maxes={i}
         elseif rsc[i].score==rsc[maxes[1]].score then
            maxes[#maxes+1]=i
         end
      end
      maxToSwap=maxes[robot.random.uniform_int(1,#maxes+1)]
      rsc[maxToSwap],rsc[1]=rsc[1],rsc[maxToSwap]
   end
end

function doExplore(obstacleProximity, obstacleDirection, foundSource, gotSource)
   if foundSource then
      explore=false
      goalX,goalY=0,0
      hasMined=true
   end
   if gotSource then
      if robot.random.uniform()<MINE_PROB_WHEN_SRC_RECVD then
         explore,goalX,goalY=false,0,0
      end
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
            source.score=1
            source.travels=0
            source.bSpent=0
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
   if wasHit then
      if abs(alpha-newDirection)<0.2 then
         wasHit=false
      else
         goalAngle=newDirection-alpha
         goalAngle=setCoupure(goalAngle)
         getToGoal(goalAngle, EXPL_CONV)
      end
   else
      robot.wheels.set_velocity(BASE_SPEED, BASE_SPEED)
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
   local newSourceId
   if #rsc>1 then
      placeMaxAtOne(rsc)
      local pickBest=robot.random.uniform()
      if pickBest<(1-EPSILONGREED) then
         newSourceId=1
      else
         newSourceId=robot.random.uniform_int(2,#rsc+1)
      end
   else
      newSourceId=1
   end
   local x=rsc[newSourceId][1]
   local y=rsc[newSourceId][2]
   return newSourceId, x, y
end

function checkGoalReached()
   local foundSource, onSource, backHome=false,false,false
   insideBlack, seeBlack = floorIsBlack()
   if seeBlack and math.sqrt((posX)^2+(posY)^2)>=90 then
      if insideBlack and sourceIsOriginal(posX,posY, ressources) then
         ressources[#ressources+1]={math.floor(posX),math.floor(posY),score=1, travels=0,bSpent=0}
         foundSource=true
      end
      onSource=true
   elseif seeBlack and math.sqrt((posX)^2+(posY)^2)<=70 then
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
   if battery>IDEAL_NEST_BATT then
      batterySecurity=batterySecurity-(battery-IDEAL_NEST_BATT)*.07
   else
      batterySecurity=batterySecurity-(battery-IDEAL_NEST_BATT)*.1
   end
   return batterySecurity
end

function floorIsBlack()
   local insideBlack = true
   local seeBlack = false
   local clr,i
   for i=1,8 do
      clr = robot.base_ground[i].value
      seeBlack = seeBlack or clr== 0
      insideBlack = insideBlack and clr == 0
   end
   return insideBlack, seeBlack
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
