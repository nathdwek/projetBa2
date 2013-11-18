-- Put your global variables here
SPEED=5
PI=math.pi
CONVERGENCE=2 --A number between 0 and 2 (0 means no convergence at all, 2 means strongest convergence possible)
AVOIDANCE=2 --A number between 1 and 12 (1 means minimum sufficient avoidance, 12 means strongest avoidance)
--maximum and minimum value for both are subject to discussion.
XMIN=-245
XMAX=245
YMIN=-245
YMAX=245
TOLERANCE_FREE=SPEED
TOLERANCE_OBSTACLE=20
TRAVELS_MAX=10
OBSTACLE_PROXIMITY_DEPENDANCE=1


--[[ This function is executed every time you press the 'execute'
     button ]]
function init()
   posX=STARTINGPOSITIONSTABLE[robot.id].posX
   posY=STARTINGPOSITIONSTABLE[robot.id].posY
   alpha=STARTINGPOSITIONSTABLE[robot.id].alpha
   goalX=robot.random.uniform(XMIN,XMAX)
   goalY=robot.random.uniform(YMIN,YMAX)
   log("Next Goal is (", goalX, ", ", goalY, ")")
   AXIS_LENGTH=robot.wheels.axis_length
   travels=0
   steps=0
end





--[[ This function is executed at each time step
     It must contain the logic of your controller ]]

function step()
   steps=steps+1
   posX, posY, alpha=odometry(posX, posY, alpha)
   local obstacleProximity, obstacleDirection=closestObstacleDirection()

   if (obstacleProximity==0 and math.sqrt((posX-goalX)^2+(posY-goalY)^2)<=TOLERANCE_FREE) or (obstacleProximity>0 and math.sqrt((posX-goalX)^2+(posY-goalY)^2)<=TOLERANCE_OBSTACLE) then
      goalX, goalY, travels=travelEndHandler()
      if travels>20 then
         return
      end
   end

   if obstacleProximity==0 then
      getToGoal()
   else
      obstacleAvoidance(obstacleProximity, obstacleDirection)
   end
end


function odometry(x, y, angle)
   local deltaL=robot.wheels.distance_left
   local deltaR=robot.wheels.distance_right
   local deltaG=(deltaL+deltaR)/2
   local deltaAngle=(deltaR-deltaL)/AXIS_LENGTH
   x=x+deltaG*math.cos(angle)
   y=y+deltaG*math.sin(angle)
   angle=angle+deltaAngle
   if angle>2*PI then
      angle=angle-2*PI
   end
   return x,y,angle
end

function closestObstacleDirection()
   local obstacleProximity = robot.proximity[1].value
   local obstacleDirection = 1
   for i=2,24 do
      if obstacleProximity < robot.proximity[i].value then
         obstacleDirection = i
         obstacleProximity = robot.proximity[i].value
      end
   end
   return obstacleProximity, obstacleDirection
end

function travelEndHandler()
   travels=travels+1
   if travels>TRAVELS_MAX then
      robot.wheels.set_velocity(0,0)
      log('back home baby')
   else
      if travels==TRAVELS_MAX then
         goalX=0
         goalY=0
      else
         goalX=robot.random.uniform(XMIN,XMAX)
         goalY=robot.random.uniform(YMIN,YMAX)
      end
      log("travels done so far: ", travels)
      log("Next Goal is (", goalX, ", ", goalY, ")")
   end
   return goalX, goalY, travels
end

function getToGoal()
   local deltaX=goalX-posX
   local deltaY=goalY-posY
   local goalDirection=math.atan(deltaY/deltaX)
   if deltaX<0 then
      goalDirection=goalDirection+PI
   end
   if goalDirection<0 then
      goalDirection=goalDirection+2*PI
   end
   local goalDirRel=goalDirection-alpha
   if goalDirRel>PI then
      goalDirRel=goalDirRel-2*PI
   end
   local coeff=goalDirRel/PI
   robot.wheels.set_velocity( (1-CONVERGENCE*coeff)*SPEED, (1+CONVERGENCE*coeff)*SPEED )
end

function obstacleAvoidance(obstacleProximity,obstacleDirection)
   local vLeft, vRight
   if obstacleProximity==1 then
      logerr("Odometry data might be offset")
   end
   if obstacleDirection <= 12 then
   -- The closest obstacle is between 0 and 180 degrees: soft turn towards the right
      vRight=((1-obstacleProximity)^OBSTACLE_PROXIMITY_DEPENDANCE*obstacleDirection-AVOIDANCE)*SPEED/11
      vLeft=10-vRight
   else
   -- The closest obstacle is between 180 and 360 degrees: soft turn towards the left
      vLeft=((1-obstacleProximity)^OBSTACLE_PROXIMITY_DEPENDANCE*25-AVOIDANCE-obstacleDirection)*SPEED/11
      vRight=10-vLeft
   end
   robot.wheels.set_velocity(vLeft, vRight)
end



--[[ This function is executed every time you press the 'reset'
     button in the GUI. It is supposed to restore the state
     of the controller to whatever it was right after init() was
     called. The state of sensors and actuators is reset
     automatically by ARGoS. ]]
function reset()
   posX=STARTINGPOSITIONSTABLE[robot.id].posX
   posY=STARTINGPOSITIONSTABLE[robot.id].posY
   alpha=STARTINGPOSITIONSTABLE[robot.id].alpha
   goalX=robot.random.uniform(XMIN,XMAX)
   goalY=robot.random.uniform(YMIN,YMAX)
   log("Next Goal is (", goalX, ", ", goalY, ")")
   travels=0
   steps=0
end



--[[ This function is executed only once, when the robot is removed
     from the simulation ]]
function destroy()
   -- put your code here
end
