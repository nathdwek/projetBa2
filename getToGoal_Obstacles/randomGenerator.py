from random import randint, uniform
from math import sqrt, pi
from sys import argv

def startingPositionsDictGenerator(xMin=-50, xMax=50, yMin=-50, yMax=50, angleMax=2*pi, robotsCount=10, robotName="fb", spacing=22):
   startingPositionsDict={}
   for i in range(robotsCount):
      x,y=placeARobot(startingPositionsDict, xMin, xMax, yMin, yMax, spacing)
      startingPositionsDict[robotName+str(i)]=[x,y,uniform(0,angleMax)]
   return startingPositionsDict

def placeARobot(startingPositionsDict, xMin, xMax, yMin, yMax, spacing):
   collisions=True
   while collisions:
      x=randint(xMin, xMax)
      y=randint(yMin, yMax)
      collisions=collisionsChecker(x,y,startingPositionsDict, spacing)
   return x,y

def collisionsChecker(x,y,startingPositionsDict, spacing):
   for positionList in startingPositionsDict.values():
      if sqrt((x-positionList[0])**2+(y-positionList[1])**2)<=spacing:
         return True
   return False

def fileInserter(startingPositionsDict, fileIn, fileOut, fileType, fileWhereInsert):
   originalLines=getLines(fileIn, fileType)
   newFile=open(fileOut+"."+fileType, 'w')
   for originalLine in originalLines[:fileWhereInsert]:
      newFile.write(originalLine)
   positionsInserter(newFile, startingPositionsDict, fileType)
   for originalLine in originalLines[fileWhereInsert:]:
      newFile.write(originalLine)
   newFile.close

def getLines(fileIn, fileType):
   originalFile=open(fileIn+"."+fileType, "r")
   originalLines=originalFile.readlines()
   originalFile.close()
   return originalLines

def positionsInserter(newFile, startingPositionsDict, fileType):
   if fileType=="argos":
      for robotName in startingPositionsDict:
         newFile.write('<foot-bot id="'+robotName+'" rab_range = "1">\n')
         newFile.write('<body position="'+toArgosPosition(startingPositionsDict[robotName])+'" orientation="'+toArgosOrientation(startingPositionsDict[robotName])+'" />\n')
         newFile.write('<controller config="lua" />\n</foot-bot>\n')
      newFile.write('\n')
   if fileType=="lua":
      newFile.write("STARTINGPOSITIONSTABLE={\n")
      for robotName in startingPositionsDict:
         newFile.write(robotName+"={\n")
         newFile.write("posX="+str(startingPositionsDict[robotName][0])+",\n")
         newFile.write("posY="+str(startingPositionsDict[robotName][1])+",\n")
         newFile.write("alpha="+str(startingPositionsDict[robotName][2])+"\n},\n")
      newFile.write("}")

def toArgosPosition(positionList):
   x=positionList[0]/100
   y=positionList[1]/100
   return str(x)+","+str(y)+",0"

def toArgosOrientation(positionList):
   orientation=(positionList[2]/pi)*180
   return str(orientation)+",0,0"

if __name__=="__main__":
   startingPositionsDict=startingPositionsDictGenerator(robotsCount=int(argv[1]))
   fileInserter(startingPositionsDict, argv[2], argv[3], "lua", 16)
   fileInserter(startingPositionsDict, argv[2], argv[3], "argos", 70)

