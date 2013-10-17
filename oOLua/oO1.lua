--**l'orienté objet en lua, exemples 1**

--En lua, toute représentation d'une valeur trop complexe pour se ramener à un des 4+1 types primitifs nil (absence de donnée), string, number, boolean + function se fait par l'usage de tables:
a1={bank="UPS", country="Suisse", balance="1000"}
print(a1.bank)
-- >>UPS

--Il est tout à fait envisageable de stocker une fonction dans une table:
a1.withdraw= function(cashOut) --ici on aurait pu écrire function a1.withdraw(cashOut)
   a1.balance=a1.balance - cashOut
end
a1.withdraw(100)
print(a1.balance)
-- >>900

--Cependant, cette fonction utilise des variables globales (ligne 10):
a2={balance=2000}
a2.withdraw=a1.withdraw
a2.withdraw(100)
print(a2.balance)
print(a1.balance)
-- >>2000
-- >>800
--la fonction s'est éxécutée "sur" a1 et non a2 (toujours ligne 10)

--Ce problème peut se régler en utilisant self:
function a1.withdraw(self, cashOut)
   self.balance=self.balance - cashOut
end
a2.withdraw=a1.withdraw
a2.withdraw(a2,200)
print(a2.balance)
-- >>1800
--la fonction s'est bien éxécutée "sur" a2, OK!

--Cependant, cette fonction (qui commence à se rapprocher d'un méthode), n'est accessible que depuis les tables où elle a été introduite "à la main":
a3={balance=500}
a3.withdraw(100)
-- >>ERROR! (mettez la ligne précédente en commentaire pour la suite)

--Avant de voir comment régler ce problème, voici une facilité syntaxique que permet lua:
function a2:deposit(cashIn)
   self.balance=self.balance+cashIn --les deux points équivalent à un passage de self comme argument
end
a3.deposit=a2.deposit
a3:deposit(1000) --les deux écritures sont interchangeables tant à l'appel qu'à la définition.
print(a3.balance)
-- >>1500
