Ceci est un dépôt git, probablement temporaire pour notre Projet d'Année "Swarm Robotics".

Vous trouverez principalement deux types de fichier dans ce dépôt:

Des fichiers (syntaxe xml) .argos permettant de configurer l'environnement de l'expérience (arène et attributs des robots).

/!\ ***VERSION DES FICHIERS .argos: ARGOS3 BETA20*** /!\

Des fichiers .lua qui permettent de programmer le comportement des robots (but du projet).

Pour lancer une expérience, dans le terminal linux, après avoir installé argos(*), rendez-vous dans le dossier contenant les fichiers .argos (et les images nécessaires à l'affichage), et entrez la commande:

user:~path/to/directory>argos3 -c configurationFile.argos

Vous pourrez alors commencer à utiliser argos (l'interface est asez intuitive normalement).

(*) Voir http://iridia.ulb.ac.be/~cpinciroli/extra/h-414/ pour plus de détails sur l'installation de argos3 et sur argos en général.
