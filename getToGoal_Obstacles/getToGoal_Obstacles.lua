-- Put your global variables here
SPEED=5
PI=math.pi
CONVERGENCE=1.7 --A number between 0 and 2 (0 means no convergence at all, 2 means strongest convergence possible)
AVOIDANCE=6 --A number between 1 and 12 (1 means minimum sufficient avoidance, 12 means strongest avoidance)
--maximum and minimum value for both are subject to discussion.
XMIN=-245
XMAX=245
YMIN=-245
YMAX=245
TOLERANCE_FREE=SPEED
TOLERANCE_OBSTACLE=20
TRAVELS_MAX=15


--[[ This function is executed every time you press the 'execute'
     button ]]
function init()
   posX=0
   posY=0
   alpha=0
   goalX=robot.random.uniform(XMIN,XMAX)
   goalY=robot.random.uniform(YMIN,YMAX)
   log("Next Goal is (", goalX, ", ", goalY, ")")
   AXIS_LENGTH=robot.wheels.axis_length
   travels=0
end





--[[ This function is executed at each time step
     It must contain the logic of your controller ]]

function step()
   odometry()
   isObstacle=closestObstacleDirection()

   if (isObstacle==0 and math.sqrt((posX-goalX)^2+(posY-goalY)^2)<=TOLERANCE_FREE) or (isObstacle>0 and math.sqrt((posX-goalX)^2+(posY-goalY)^2)<=TOLERANCE_OBSTACLE) then
      travels=travels+1
      if travels>TRAVELS_MAX then
         robot.wheels.set_velocity(0,0)
         log('back home baby')
         return
      elseif travels==TRAVELS_MAX then
         goalX=0
         goalY=0
      else
         goalX=robot.random.uniform(XMIN,XMAX)
         goalY=robot.random.uniform(YMIN,YMAX)
      end
      log("travels done so far: ", travels)
      log("Next Goal is (", goalX, ", ", goalY, ")")
   end

   if isObstacle==0 then
      deltaX=goalX-posX
      deltaY=goalY-posY
      goalDirection=math.atan(deltaY/deltaX)
      if deltaX<0 then
         goalDirection=goalDirection+PI
      end
      if goalDirection<0 then
         goalDirection=goalDirection+2*PI
      end
      deltaAngle=goalDirection-alpha
      if deltaAngle>PI then
         deltaAngle=deltaAngle-2*PI
      end
      coeff=deltaAngle/PI
      robot.wheels.set_velocity( (1-CONVERGENCE*coeff)*SPEED, (1+CONVERGENCE*coeff)*SPEED )

   else
      if isObstacle==1 then
         log("Odometry data might be offset")
      end
      if obstacleDirection <= 12 then
      -- The closest obstacle is between 0 and 180 degrees: soft turn towards the right
         robot.wheels.set_velocity((22-obstacleDirection+AVOIDANCE)*SPEED/11, (obstacleDirection-AVOIDANCE)*SPEED/11)
      else
      -- The closest obstacle is between 180 and 360 degrees: soft turn towards the left
         robot.wheels.set_velocity((25-AVOIDANCE-obstacleDirection)*SPEED/11, (-3+AVOIDANCE+obstacleDirection)*SPEED/11)
      end
   end

   if alpha>2*PI then
      alpha=alpha-2*PI
   end
end


function odometry()
   local deltaL=robot.wheels.distance_left
   local deltaR=robot.wheels.distance_right
   local deltaG=(deltaL+deltaR)/2
   local deltaAlpha=(deltaR-deltaL)/AXIS_LENGTH
   posX=posX+deltaG*math.cos(alpha)
   posY=posY+deltaG*math.sin(alpha)
   alpha=alpha+deltaAlpha
end

function closestObstacleDirection()
   -- Search for the reading with the highest value
   value = robot.proximity[1].value -- highest value found so far
   obstacleDirection = 1   -- index of the highest value
   for i=2,24 do
      if value < robot.proximity[i].value then
         obstacleDirection = i
         value = robot.proximity[i].value
      end
   end
   return value
end





--[[ This function is executed every time you press the 'reset'
     button in the GUI. It is supposed to restore the state
     of the controller to whatever it was right after init() was
     called. The state of sensors and actuators is reset
     automatically by ARGoS. ]]
function reset()
   posX=0
   posY=0
   alpha=0
   travels=0
end



--[[ This function is executed only once, when the robot is removed
     from the simulation ]]
function destroy()
   -- put your code here
end
