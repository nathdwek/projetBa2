--**l'orienté objet en lua, exemples 2**

--définition d'une table (objet) Account comme à la fin de oO1:
Account={balance=0}
function Account:deposit(cashIn)
   self.balance=self.balance + cashIn
end
function Account:withdraw(cashOut)
   self.balance = self.balance - cashOut
end

--En lua, la notion de classe, de "moule" pour la création d'objet se fait via le concept de prototype. N'importe quel table peut-être utilisé comme prototype d'une autre table. Pour faire de b la prototype de a, on écrit:
--setmetatable(a, {__index=b})

--Essayons d'utiliser cette expression au mieux:
function Account:new(aTable)
   newAccount=aTable or {} --en lua, a=b or c éxécute a=b si b!=nil et a=c sinon. Ici, on crée une table vide si aTable=nil, càd si l'utilisateur ne fournit pas d'argument.
   setmetatable(newAccount, self)
   self.__index=self
--ici, je n'ai pas compris pourquoi le "guide officiel" implémentait cette méthode ainsi plutôt qu'en faisant simplement setmetatable(newAccount, {__index=self}) à la place des lignes 18 et 19. Les deux méthodes m'ont semblé équivalentes (après test) pour toutes les applications que j'ai lues par après. A voir.
   return newAccount
end

--Maintenant, Account dispose d'une méthode permettant de créer un nouveau compte ayant pour prototype Account:
a1=Account:new{balance=100} --cette écriture est équivalente à a1=Account:new({balance=100})
a1:deposit(50)
print(a1.balance)
-- >>150

--Comme on vient de le voir, un objet a ayant pour prototype un objet b peut accéder à travers la metatable à toutes valeurs des clés (=> en orienté objet: les méthodes ET les attributs) présentes dans la table de l'objet prototype b:
a2=Account:new()
print(a2.balance)
-- >>0 (cf ligne 4)

--redéfinir une valeur dans l'objet a1 (cf ligne 25) n'écrase pas pour autant la valeur "par défaut" définie dans l'objet prototype (Account). lua consulte simplement d'abord la table "principale" avant la (les) metatables (imbriquées dans des cas un peu plus complexes):
print(a1.balance)
-- >>150
--lua consulte bien par défaut la variable attendue
print(getmetatable(a1).__index.balance)
-- >>0
--Cette ligne un peu longue nous montre que la balance "par défaut" =0 (cf ligne 4) est bel et bien toujours présente

--A partir de là, et en utilisant tout ce qu'on vient de dire, l'héritage peut s'implémenter très facilement. On va créer un objet de prototype Account et l'utiliser lui même comme prototype pour d'autres objets après l'avoir légèrement modifié:
SpecialAccount=Account:new()
function SpecialAccount:deposit(cashIn)
   self.balance=self.balance + 2*cashIn --Waw!
end

--Vu la manière dont on a implémenté Account:new en utilisant self de manière astucieuse, la méthode new dont hérite SpecialAccount est parfaitement valide pour créer de nouveaux objet SpecialAccount (en appelant new sur SpecialAccount bien sûr):
sa1=SpecialAccount:new{balance=300}
sa1:deposit(50)
print(sa1.balance)
-- >>400
sa1:withdraw(50)
print(sa1.balance)
-- >> 350
--Tout se passe comme dans une situation d'héritage classique, avec en plus des "constructeurs" très faciles.

--Il reste à couvrir l'encapsulation des attributs (privés), qui se fait avec une approche un peu différente.
