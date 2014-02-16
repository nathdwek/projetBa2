# ############################################################### #
#Ce fichier script python permet de faire apparaître les robots au#
#hasard dans l'arène tout en disposant des informations sur les po#
#sitions et orientations initiales des robots dans le fichier .lua#
#Si vous appelez ce script dans le terminal, vous devez lui passer#
#trois arguments : le nombre de robots à faire apparaître dans l' #
#arène, le (même) nom des deux fichiers argos et lua de départ et #
#et le (même) nom des deux fichiers argos et lua qui seront géné  #
# rés.########################################################### #

#Exemple : python3 randomGenerator.py 10 getToGoalIN getToGoalOUT #
#(getToGoalIN.argos et getToGoalIN.lua sont déjà présents dans ce #
#répertoire dans ce dépôt).###################################### #

# ############################################################### #

from random import uniform
from math import sqrt, pi, cos, sin
from sys import argv

def startingPositionsDictGenerator(rMax=50, thetaMax=2*pi, angleMax=2*pi, robotsCount=10, robotName="fb", spacing=22):
   """Fonction qui génère de manière aléatoire les positions et orientations de départ dans l'arène des robots.
   Arguments:
      rMax, thetaMax, angleMax (float): les paramètres de la distribution des robots.
      robotsCount (int): le nombre de robots à faire apparaître dans l'arène.
      robotName (str): le préfixe à l'id de chaque robot.
      spacing (float): l'espacement minimum des robots (pris centre à centre dans le plan XY).
   Valeur de retour:
      dict: Dictionnaire dont les clés sont les ids des robots et les valeurs sont des tuples (coordonnée x, coordonnée y,orientation) de départ du robot
   """
   startingPositionsDict={}
   for i in range(robotsCount):
      x,y=placeARobot(startingPositionsDict, rMax, thetaMax, spacing)
      startingPositionsDict[robotName+str(i)]=(x,y,uniform(0,angleMax))
   return startingPositionsDict

def placeARobot(startingPositionsDict, rMax, thetaMax, spacing):
   """fonction qui génère une position de départ aléatoire d'un robot dans l'arène en veillant à éviter les conflits entre robots.
   Arguments:
      rMax, thetaMax (float): paramètres de la distribution des robots.
      startingPositionsDict (dict): dictionnaire contenant les informations sur les robots déjà présents dans l'arène. Les clés sont les ids des robots et les valeurs sont des tuples (coorodonnée x, coordonnée y,orientation) de départ du robot.
      spacing (float): l'espacement minimum des robots (pris centre à centre dans le plan XY).
   Valeurs de retour:
      floats: renvoie une coordonnée x et une coordonnée y de départ d'un robot, générée aléatoirement, et n'impliquant pas de conflit entre robots.
   """
   collisions=True
   while collisions:
      r=uniform(0,rMax)
      theta=uniform(0, thetaMax)
      x=r*cos(theta)
      y=r*sin(theta)
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
   originalLines=getLines(fileIn, fileType, fileOut)
   newFile=open(fileOut+"."+fileType, 'w')
   for originalLine in originalLines[:fileWhereInsert]:
      newFile.write(originalLine)
   positionsInserter(newFile, startingPositionsDict, fileType)
   for originalLine in originalLines[fileWhereInsert:]:
      newFile.write(originalLine)
   newFile.close

def getLines(fileIn, fileType, fileOut):
   """Fonction qui consulte un fichier et qui renvoie la liste des lignes de ce fichier. Cette fonction appelle aussi la fonction qui insère la ligne argos permettant de charger automatiquement le comportement lua associé (pour les fichiers argos).
   Arguments:
      fileIn (string): nom du fichier à consulter.
      fileType (string): extension du fichier à consulter.
   Valeur de retour:
      list: renvoie la liste des lignes du fichier.
   """
   originalFile=open(fileIn+"."+fileType, "r")
   originalLines=originalFile.readlines()
   if fileType=="argos":
      insertParamsScript(originalLines, fileIn, fileOut)
   originalFile.close()
   return originalLines

def insertParamsScript(originalLines,fileIn,fileOut):
   """fonction qui insère la ligne argos permettant de charger automatiquement le comportement lua associé (pour les fichiers argos).
   Arguments:
      originalLines (list): Liste des lignes extraites du fichier original (contenant toutes les informations sauf celles concernant les positions et orientations de départ des robots)
      fileOut (string): le nom du fichier ou écrire le résultat final ("fileIN+données sur les positions et orientations de départ robots"). ATTENTION Cette fonction ne se comporte bien que si fileOut est le même pour le fichier ARGoS et le fichier lua. Dans ce cas, elle les associe l'un à l'autre lors de l'éxécution d'ARGoS
   Valeur de retour:
      None (modifie une liste)
   """
   for i in range(len(originalLines)):
      if "<!-- params script=" in originalLines[i]:
         originalLines[i]='<params script="'+fileIn+'.lua"/>'

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
   fileInserter(startingPositionsDict, argv[2], argv[3], "argos", 63) #écrit ces positions dans la configuration d'arène .argos

