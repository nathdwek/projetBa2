Ceci est un dépôt git, probablement temporaire pour notre Projet d'Année "Swarm Robotics".

Vous trouverez principalement deux types de fichier dans ce dépôt:

Des fichiers (syntaxe xml) .argos permettant de configurer l'environnement de l'expérience (arène et attributs des robots).

##***VERSION DES FICHIERS .argos: ARGOS3 BETA20***

Des fichiers .lua qui permettent de programmer le comportement des robots (but du projet).

Pour lancer une expérience, dans le terminal linux, après avoir installé argos(*), rendez-vous dans le dossier contenant les fichiers .argos (et les images nécessaires à l'affichage), et entrez la commande:

user:~path/to/directory>argos3 -c configurationFile.argos

Vous pourrez alors commencer à utiliser argos (l'interface est asez intuitive normalement).

Pour utiliser les fichiers de ce dépôt, clonez ce dépôt (vous avez non seulement besoin des codes mais aussi des images présentes dans le dossier floorPicture/) et utilisez ARGoS comme vous le feriez normalement.

Petit plus: dans chaque dossier correspondant à une situation (dossier style simplestConfig/, simpleObstacles/, ...) vous trouverez 3 fichiers: un fichier manualLoader.argos qui lancera ARGoS classiquement, et deux fichiers \<name\>.argos et \<name\>.lua associés (si \<name\> n'a pas encore été attribué, alors ils se nommeront yourScript.argos/yourScript.lua). Le fichier \<name\>.argos a été modifié de façon a charger directement \<name\>.lua comme comportement sans ouvrir l'éditeur de texte intégré à ARGoS, afin de pouvoir travailler plus rapidement (selon la manière dont vous travaillez).

Si vous voulez utiliser cet avantage, faites une copie de yourScript.argos, donnez lui le nom approprié à ce que vous allez faire et modifiez aux alentours de la ligne 40 la ligne


```xml
<params script="yourScript.lua"/>
```

en


```xml
<params script="<nom adapté à votre but>.lua"/>
```

Ensuite, créez le fichier .lua du même nom. C'est maintenant ce fichier qui sera chargé automatiquement à chaque fois que vous lancerez votre propre fichier .argos .

(*) Voir http://iridia.ulb.ac.be/~cpinciroli/extra/h-414/ pour plus de détails sur l'installation de argos3 et sur argos en général.
