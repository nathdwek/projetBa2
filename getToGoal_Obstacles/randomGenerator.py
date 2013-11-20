from random import randint, uniform
from math import sqrt, pi
from sys import argv

def startingPositionsDictGenerator(xMin=-50, xMax=50, yMin=-50, yMax=50, angleMax=2*pi, robotsCount=10, robotName="fb", spacing=22):
   """Fonction qui génère de manière aléatoire les positions et orientations de départ dans l'arène des robots.
   Arguments:
      xMin, xMax, yMin, yMax, angleMax (float): les paramètres de la distribution des robots.
      robotsCount (int): le nombre de robots à faire apparaître dans l'arène.
      robotName (str): le préfixe à l'id de chaque robot.
      spacing (float): l'espacement minimum des robots (pris centre à centre dans le plan XY).
   Valeur de retour:
      dict: Dictionnaire dont les clés sont les ids des robots et les valeurs sont des tuples (coordonnée x, coordonnée y,orientation) de départ du robot
   """
   startingPositionsDict={}
   for i in range(robotsCount):
      x,y=placeARobot(startingPositionsDict, xMin, xMax, yMin, yMax, spacing)
      startingPositionsDict[robotName+str(i)]=(x,y,uniform(0,angleMax))
   return startingPositionsDict

def placeARobot(startingPositionsDict, xMin, xMax, yMin, yMax, spacing):
   """fonction qui génère une position de départ aléatoire d'un robot dans l'arène en veillant à éviter les conflits entre robots.
   Arguments:
      xMin, xMax, yMin, yMax (float): paramètres de la distribution des robots.
      startingPositionsDict (dict): dictionnaire contenant les informations sur les robots déjà présents dans l'arène. Les clés sont les ids des robots et les valeurs sont des tuples (coorodonnée x, coordonnée y,orientation) de départ du robot.
      spacing (float): l'espacement minimum des robots (pris centre à centre dans le plan XY).
   Valeurs de retour:
      floats: renvoie une coordonnée x et une coordonnée y de départ d'un robot, générée aléatoirement, et n'impliquant pas de conflit entre robots.
   """
   collisions=True
   while collisions:
      x=randint(xMin, xMax)
      y=randint(yMin, yMax)
      collisions=collisionsChecker(x,y,startingPositionsDict, spacing)
   return x,y

def collisionsChecker(x,y,startingPositionsDict, spacing):
   """fonction qui vérifie si une position de départ d'un robot tirée aléatoirement n'entre pas en conflit avec les robots déjà placés dans l'arène.
   Arguments:
      x (float): coordonnée x de départ d'un robot, tirée aléatoirement.
      y (float): coordonnée y de départ d'un robot, tirée aléatoirement.
      startingPositionsDict (dict): dictionnaire contenant les informations sur les robots déjà présents dans l'arène. Les clés sont les ids des robots et les valeurs sont des tuples (coorodonnée x, coordonnée y,orientation) de départ du robot.
      spacing (float): l'espacement minimum des robots (pris centre à centre dans le plan XY).
   Valeur de retour
      bool: renvoie True s'il y a collision, False sinon.
   """
   for positionTup in startingPositionsDict.values():
      if sqrt((x-positionTup[0])**2+(y-positionTup[1])**2)<=spacing:
         return True
   return False

def fileInserter(startingPositionsDict, fileIn, fileOut, fileType, fileWhereInsert):
   """Fonction qui insère les données relatives aux positions et orientations de départ des robots dans l'arène dans un fichier (lua ou argos).
   Arguments:
      startingPositionsDict (dict): Dictionnaire dont les clés sont les ids des robots et les valeurs sont des tuples (coordonnée x, coordonnée y,orientation) de départ du robot
      fileIn (string): le nom du fichier de départ (contenant toutes les lignes nécessaires sauf celles contenant les donnée sur les positions et orientations de départ des robots dans l'arène)
      fileOut (string): le nom du fichier ou écrire le résultat final ("fileIN+données sur les positions et orientations de départ robots")
      fileType (string: l'extension du fichier à traiter)
      fileWhereInsert (int): le numéro de la ligne ou commencer à insérer les lignes contenant les données sur les positions de départ des robots.
   Valeur de Retour:
      None
   """
   originalLines=getLines(fileIn, fileType)
   newFile=open(fileOut+"."+fileType, 'w')
   for originalLine in originalLines[:fileWhereInsert]:
      newFile.write(originalLine)
   positionsInserter(newFile, startingPositionsDict, fileType)
   for originalLine in originalLines[fileWhereInsert:]:
      newFile.write(originalLine)
   newFile.close

def getLines(fileIn, fileType):
   """Fonction qui consulte un fichier et qui renvoie la liste des lignes de ce fichier.
   Arguments:
      fileIn (string): nom du fichier à consulter.
      fileType (string): extension du fichier à consulter.
   Valeur de retour:
      list: renvoie la liste des lignes du fichier.
   """
   originalFile=open(fileIn+"."+fileType, "r")
   originalLines=originalFile.readlines()
   originalFile.close()
   return originalLines

def positionsInserter(newFile, startingPositionsDict, fileType):
   """Fonction qui s'occupe spécifiquement d'insérer les lignes contenant les informations sur les positions de départ des robots dans l'arène.
   Arguments:
      newFile (IOFile): le fichier déjà ouvert en cours d'écriture.
      startingPositionsDict (dict): Dictionnaire dont les clés sont les ids des robots et les valeurs sont des tuples (coordonnée x, coordonnée y,orientation) de départ du robot
      fileType (string): extension du fichier à consulter.
   Valeur de retour:
      None
   """
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

def toArgosPosition(positionTup):
   """Fonction qui génère le string décrivant une position de départ d'un robot au format accepté par ARGoS: "x,y,z" [m].
   Argument:
      positionTup (tuple): valeur d'un robot dans startingPositionsDict: (x,y,orientation) (cm et radians)
   Valeur de retour:
      str: renvoie le string décrivant cette position de départ au format accepté par ARGoS: "x,y,z" [m].
   """
   x=positionTup[0]/100
   y=positionTup[1]/100
   return str(x)+","+str(y)+",0"

def toArgosOrientation(positionTup):
   """Fonction qui génère le string décrivant une orientation de départ d'un robot au format accepté par ARGoS: "alpha, theta, phi" [°].
   Argument:
      positionTup (tuple): valeur d'un robot dans startingPositionsDict: (x,y,orientation) (cm et radians)
   Valeur de retour:
      str: renvoie le string décrivant cette orientation de départ au format accepté par ARGoS: "alpha, theta, phi" [°].
   """
   orientation=(positionTup[2]/pi)*180
   return str(orientation)+",0,0"

if __name__=="__main__":
   startingPositionsDict=startingPositionsDictGenerator(robotsCount=int(argv[1])) #Génère des positions et orientations de départ aléatoirement
   fileInserter(startingPositionsDict, argv[2], argv[3], "lua", 16) #écrit ces positions dans le comportement .lua
   fileInserter(startingPositionsDict, argv[2], argv[3], "argos", 70) #écrit ces positions dans la configuration d'arène .argos

