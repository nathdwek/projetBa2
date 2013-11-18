from random import randint, uniform
from math import sqrt


def startingPositionsGenerator(xMin=-50, xMax=50, yMin=-50, yMax=50, angleMax=2*pi, robotCount=10, robotName="fb", spacing=22):
   startingPositionsDict={}
   for i in range(robotCount):
      collisions=True
      while collisions:
         x=randint(xMin, xMax)
         y=randint(yMin, yMax)
         collisions=collisionsChecker(x,y,startingPositionsDict, spacing)
      startingPositionsDict[robotName+string(i)]=[x,y,uniform(angleMax)]
   return startingPositionsDict

def collisionsChecker(x,y,startingPositionsDict):
   for positionList in startingPositionsDict.values():
      if sqrt((x-positionList[0])**2+(y-positionList[1])**2)<=22:
         return False
   return True

def fileInserter(startingPositionsDict, fileIn, fileOut, fileType, fileWhereInsert):
   originalFile=open(fileIn+"."+fileType, "r")
   originalLines=originalFile.readlines()
   originalFile.close()
   newFile=open(fileOut+"."+fileType)
   for originalLine in originalLines[:fileWhereInsert]:
      newFile.write(originalLine)
   positionsInsert(newFile, startingPositionsDict)
   for originalLine in originalLines[fileWhereInsert:]:
      newFile.write(originalLine)

