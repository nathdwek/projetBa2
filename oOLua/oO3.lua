--**l'orienté objet en lua, exemples 3**

--Nous allons implémenter la notion d'attributs privés en créant une fonction qui "crée" un "objet" et qui en renvoie une interface. L'utilisation de l'expression local (à l'origine utilisée pour définir des variables accessibles uniquement à l'intérieur d'une fonction afin d'éviter les conflits, ...) va nous permettre d'aboutir à une forme d'encapsulation.

--d'abord, un petit exemple de l'utilisation de local:
i={balance=100, country="Belgique", bank="BBL"}
j={balance=10000000000, country="Suisse", bank="UPS"}

--[[function factorial(n)
   i=1
   for j=2,n do
      i=i*j
   end
   return i
end
print(factorial(3))
print(i.balance, j.country)]]--
-- >>6
-- >>ERROR! (i "compte en banque" a été remplacé par i "compteur pour la factorielle") (Mettez les lignes 9 à 17 en commentaire)

--Le bon moyen de faire (même si on nomme ses variables à peu près correctement!)
function factorial(n)
   local i, j
   i=1
   for j=2,n do
      i=i*j
   end
   return i
end
print(factorial(3))
print(i.balance, j.country)
-- >>6
-- >>100     Suisse
--OK!


--Utilisons cela pour faire ce qui a été présenté dans l'intro:
--En fait, cette façon de faire se rapproche encore plus de l'orienté objet vu en java par exemple.

function newAccount(aTable)

   local account=aTable or {}
   account.balance = account.balance or 0
--ce qu'on pourrait assimiler au constructeur

   local getBalance = function()
      return account.balance
   end
   local setBalance=function(newBalance)
      account.balance=newBalance
   end
--l'équivalent d'une méthode accesseur
   local withdraw= function (cashOut)
      account.balance=account.balance - cashOut
   end
   local deposit= function (cashIn)
      account.balance=account.balance + cashIn
   end
   local privateHelloWorld= function()
      print("Hello World")
   end
--d'autres méthodes

   interface={
   withdraw= withdraw,
   deposit= deposit,
   getBalance= getBalance,
   setBalance=setBalance
   }
--définition de l'interface. Ne sont reprises dans l'interface que les méthodes publiques (en supposant qu'on applique les règles de bonne pratique, c'est à dire tous les attributs privés.
   return interface
--pour le monde extérieur, l'objet se limite donc littéralement à son interface.
end

--Voyons ce que ça donne:
a1=newAccount{balance=100}
print(a1.getBalance())
-- >>100
a1.withdraw(50)
print(a1.getBalance())
-- >>50
a1.deposit(40)
print(a1.getBalance())
-- >>90

a2=newAccount{bank="ING"}
print(a2.getBalance())
-- >>0
a2.deposit(40)
print(a2.getBalance())
-- >>40
print(a1.getBalance())

--Deux exemples d'encapsulation:
print(a2.balance)
-- >>nil
a2.privateHelloWorld()
-- >>ERROR!
--Mettez ces lignes en commentaire.

--dernier effort: l'héritage avec cette manière-ci d'aborder le problème:
function newSpecialAccount(aTable)

   local account=newAccount(aTable) --Je fais ça parce que je vais avoir besoin de newAccount(aTable) deux fois (lignes 99 et 110)
   local specialAccount=account --Comme en Java (sans l'usage de protected), un objet d'une "sous-classe" n'a lui aussi accès qu'à l'interface de la "super-classe"
   specialAccount.personalMessage = specialAccount.personalMessage or "Hello"
--l'équivalent du constructeur. Ici, on ajoute un attribut supplémentaire.

   local deposit = function(cashIn)
      specialAccount.setBalance(specialAccount.getBalance() + 2*cashIn) --Waw!
   end
--une redéfinition de méthode
   local greet = function()
      print(specialAccount.personalMessage)
   end
--une méthode supplémentaire

   interface=account
   interface.greet=greet
   interface.deposit=deposit
--création de l'interface. Attention, il faut non seulement rajouter les méthodes supplémentaires, mais aussi réassigner les méthodes redéfinies.
   return interface
end

--Voyons ce que ça donne:
sa1=newSpecialAccount()
print(sa1.getBalance())
-- >>0
sa1.greet()
-- >>Hello
sa1.deposit(50)
print(sa1.getBalance())
-- >>100

