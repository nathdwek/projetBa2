-- Put your global variables here
SPEED=5
PI=math.pi



--[[ This function is executed every time you press the 'execute'
     button ]]
function init()
   posX=0
   posY=0
   alpha=0
   goalX=100
   goalY=100
   AXIS_LENGTH=robot.wheels.axis_length
end





--[[ This function is executed at each time step
     It must contain the logic of your controller ]]

function step()
   odometry()
   if math.abs(posX-goalX)<=SPEED/10 and math.abs(posY-goalY)<=SPEED/10 then
      robot.wheels.set_velocity(0,0)

   else
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
      robot.wheels.set_velocity( (1-2*coeff)*SPEED, (1+2*coeff)*SPEED )
      if alpha>2*PI then
         alpha=alpha-2*PI
      end
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
end



--[[ This function is executed only once, when the robot is removed
     from the simulation ]]
function destroy()
   -- put your code here
end
