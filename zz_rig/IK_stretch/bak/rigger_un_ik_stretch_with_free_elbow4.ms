--DEBUG

--Reste � placer les variable backup � la place des variable fixe dans les controleurs scripts de stretch.
--il faut leur donner la valeur du track zero avant de re mapper les variables de taille de bras et d'avant bras.

--contraindre le free_elbow_target au ctr_free_elbow_target
----faire le mappage des transfert d'animation en fonction

-------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------

-- CREER UNE IK CHAIN

--� partir de trois bones
os = $ as array

-- verifier que l'array est dans le bon sens
--placer trois point a la place des os et construire l'ik sur ces points
--cr�er une ik
ik_chain = IKSys.ikChain os[1] os[3] "IKHISolver"

--cr�ation de trois points
points = for i = 1 to os.count collect point () 
for o in points do
(
points.Box = on
points.axistripod = off
)
--alignement des trois points sur les os 

for i = 1 to os.count do
(
	points[i].rotation =  os[i].rotation 
	points[i].pos = os[i].pos
)
--parente ik_chain avec un helper
os[1].parent = points[1] 
-- parente le premier os avec un helper
ik_chain.parent = points[3] 

--faire du point du milieu le controleur de la rotation de l'ik
ik_chain.transform.controller.VHTarget = points[2]

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------

-- CREER LE STRETCH

--A sur l'os du coude, preparation du controller de position en x
--1 cr�er une liste de controller de position en x 
--2 creer un bezier float pour memoriser la taille initiale de l'os
os2_pos = os[2].transform.controller.FK_Sub_Control.controller.Position.controller


os2_pos.x_position.controller = bezier_float ()
os2_pos.x_position.controller = float_list ()

os2_pos_x = os2_pos.x_position.controller
--3 cr�er un script float pour d�larer le script
os2_pos_x.available.controller = float_script ()
os2_pos_x.setname 1 "zero"
os2_pos_x.setname 2 "stretch"
--4 activer le position script
os2_pos_x.setactive 2
os2_pos_x.weight[1].controller = bezier_float ()
os2_pos_x.weight[2].controller = bezier_float ()
os2_pos_x.weight[1].controller.value = 0
--5 variable: longueur du biceps fixe : biceps_fix = position en x de os[2]
os2_pos_x.stretch.controller.addconstant "biceps_fix" (os[2].transform.controller.FK_Sub_Control.controller.Position.controller.x_position.controller.zero.controller)
os2_pos_x.stretch.controller.script = "biceps_fix.value"

--B preparation du controller de position en x sur l'os du poignet
--1 cr�er une liste de controller de position en x 
--2 creer un bezier float pour memoriser la taille initiale de l'os
os3_pos = os[3].transform.controller.FK_Sub_Control.controller.Position.controller

os3_pos.x_position.controller   = bezier_float ()
os3_pos.x_position.controller = float_list ()

os3_pos_x = os3_pos.x_position.controller

--3 cr�er un script float pour d�larer le script
os3_pos_x.available.controller = float_script ()
os3_pos_x.setname 1 "zero"
os3_pos_x.setname 2 "stretch"
--4 activer le position script
os3_pos_x.setactive 2
os3_pos_x.weight[1].controller = bezier_float ()
os3_pos_x.weight[2].controller = bezier_float ()
os3_pos_x.weight[1].controller.value = 0
--5 variable longueur de l'avant bras fixe : av_bras_fix = position en x de os[3]
os3_pos_x.stretch.controller.addconstant "av_bras_fix" (os[3].transform.controller.FK_Sub_Control.controller.Position.controller.x_position.controller.zero.controller)
os3_pos_x.stretch.controller.script = "av_bras_fix.value"

--C �crire le script du coude
-----variables : point du coude comme node, point de l'epaule et longueur de l'avant bras
os2_pos_x.stretch.controller.addconstant "poignet" (points[3])
os2_pos_x.stretch.controller.addconstant "epaule" (points[1])
os2_pos_x.stretch.controller.addconstant "av_bras_fix" (os[3].transform.controller.FK_Sub_Control.controller.Position.controller.x_position.controller.zero.controller)

aa = "(arm_size = distance epaule poignet) \n"
bb = "(arm_size_fix = biceps_fix.value + av_bras_fix.value) \n"
cc =" (coef = arm_size / arm_size_fix) \n"
dd = " (if arm_size > arm_size_fix then (biceps_fix.value*coef)  else (biceps_fix.value))"
os2_pos_x.stretch.controller.script = aa + bb +cc +dd 


--D �crire le script du poignet
-----variables : point du coude comme node, point de l'epaule et longueur du biceps
os3_pos_x.stretch.controller.addconstant "poignet" (points[3])
os3_pos_x.stretch.controller.addconstant "epaule" (points[1])
os3_pos_x.stretch.controller.addconstant "biceps_fix" (os[2].transform.controller.FK_Sub_Control.controller.Position.controller.x_position.controller.zero.controller)

aa = "arm_size = distance epaule poignet\n "
bb = "arm_size_fix = biceps_fix.value + av_bras_fix.value \n "
cc = "coef = arm_size/arm_size_fix \n "
dd = "if arm_size > arm_size_fix then (av_bras_fix.value*coef) else (av_bras_fix.value)"
os3_pos_x.stretch.controller.script = aa +bb +cc +dd

-------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------

--CREER LE FREE ELBOW

--creer le dispositif:
---cr�er un helper de trois splines
cercle = for i= 1 to 3 collect circle ()


rotate cercle[1]  (angleaxis 90 [1,0,0])
rotate cercle[2]  (angleaxis 90 [0,1,0])
rotate cercle[3] (angleaxis 90 [0,0,1])

 for o in cercle do
	(
	select o
	modPanel.addModToSelection (Edit_Spline ()) ui:on
	maxOps.CollapseNodeTo o 1 off
	)

for i = 2 to cercle.count do
addandweld cercle[1] cercle[i] 10

	
test = stringstream ""
format "ctr_free_elbow_target%" (random 1 100) to: test
cercle[1].name = test as string

---- deux points, un entre epaule et poigent, orient� vers le helper de "twist ik", l'autre enfant de celui l�
--free_elbow_target = point ()
free_elbow_target = cercle[1]
free_elbow_target.pos = os[2].pos
free_elbow_target.pos.controller = Position_XYZ ()
free_elbow_target.pos.controller = position_list ()
free_elbow_target.pos.controller.Available.controller = position_script ()
free_elbow_target.pos.controller.setname 1  "free"
free_elbow_target.pos.controller.setname 2  "lock"


free_elbow_target_hlp = point ()
free_elbow_target_hlp.pos.controller = Position_Constraint ()
free_elbow_target_hlp.pos.controller.constraints.appendTarget points[1] 50
free_elbow_target_hlp.pos.controller.constraints.appendTarget points[3] 50

free_elbow_target_hlp.rotation.controller = LookAt_Constraint ()
free_elbow_target_hlp.rotation.controller.constraints.appendTarget points[1] 100
free_elbow_target_hlp.rotation.controller.upnode_world = off
free_elbow_target_hlp.rotation.controller.pickUpNode = points[2]
free_elbow_target_hlp.rotation.controller.upnode_ctrl = 0

--cercle[1].parent = free_elbow_target_hlp
--free_elbow_target.parent = cercle[1]
free_elbow_target.parent = free_elbow_target_hlp
--free_elbow_target.pos = free_elbow_target_hlp.pos
free_elbow_target.pos = os[2].pos

AlignToParent free_elbow_target

------mettre en place les controleur de position sur les os, deux controllers, un pour suivre le free_elbow_target, un pour r�cup�rer la position du free_elbow_target
----g�n�ration controller free_elbow os2
-----g�n�ration controller de position
os2_pos_x.available.controller = float_script ()
os2_pos_x.available.controller = bezier_float ()
os2_pos_x.setname 3 "lock"
os2_pos_x.setname 4 "backup"

------g�n�ration  les controller de poids
os2_pos_x.weight[3].controller = bezier_float ()
os2_pos_x.weight[4].controller = bezier_float ()
os2_pos_x.weight[3].controller.value = 0
os2_pos_x.weight[4].controller.value = 0

-------- d�claration des variables
os2_pos_x.lock.controller.addconstant "poignet" (points[3])
os2_pos_x.lock.controller.addconstant "epaule" (points[1])
os2_pos_x.lock.controller.addconstant "free_elbow_target" (free_elbow_target)
-------- �criture du script lock
os2_pos_x.lock.controller.script = "distance free_elbow_target epaule"
-------- modification du stretch



----g�n�ration controller free_elbow os3
-----g�n�ration controller de position
os3_pos_x.available.controller = float_script ()
os3_pos_x.available.controller = bezier_float ()
os3_pos_x.setname 3 "lock"
os3_pos_x.setname 4 "backup"
------g�n�ration  les controller de poids
os3_pos_x.weight[3].controller = bezier_float ()
os3_pos_x.weight[4].controller = bezier_float ()
os3_pos_x.weight[3].controller.value = 0
os3_pos_x.weight[4].controller.value = 0

-------- d�claration des variables
os3_pos_x.lock.controller.addconstant "poignet" (points[3])
os3_pos_x.lock.controller.addconstant "epaule" (points[1])
os3_pos_x.lock.controller.addconstant "free_elbow_target" (free_elbow_target)

-------- �criture du script lock
os3_pos_x.lock.controller.script = "distance free_elbow_target poignet"

------- modification des stretch
os2_pos_x.backup.controller.value = os2_pos_x.zero.controller.value
os2_pos_x.stretch.controller.addconstant "biceps_fix" 	(os[2].transform.controller.FK_Sub_Control.controller.Position.controller.x_position.controller.backup.controller)
os2_pos_x.stretch.controller.addconstant "av_bras_fix" 	(os[3].transform.controller.FK_Sub_Control.controller.Position.controller.x_position.controller.backup.controller)

os3_pos_x.backup.controller.value = os3_pos_x.zero.controller.value
os3_pos_x.stretch.controller.addconstant "biceps_fix" 	(os[2].transform.controller.FK_Sub_Control.controller.Position.controller.x_position.controller.backup.controller)
os3_pos_x.stretch.controller.addconstant "av_bras_fix" 	(os[3].transform.controller.FK_Sub_Control.controller.Position.controller.x_position.controller.backup.controller)


--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--GENERER LE SCRIPT DE LIBERATION DU COUDE
test = stringstream ""
format "var%" (random 1 1000) to:test
rd_name = test as string
out_file = createfile rd_name
format "bone002 = $%\n" 	os[2].name to: out_file
format "bone003 = $%\n" 	os[3].name to: out_file
format "point001 = $%\n" 	cercle[1].name to: out_file
format "point7 = $%\n" 	free_elbow_target_hlp.name to: out_file
format "epaule =$%\n" 		points[1].name to: out_file
format "poignet =$%\n" 	points[3].name to: out_file
close out_file

--yo = openfile rd_name
--execute yo 
edit rd_name
------------------------------------------


def = attributes boton

(
	parameters main rollout:free_elbow ()
	
	rollout free_elbow "free elbow!" width:162 height:300 
	( 
		checkButton ckb1 "liberer le coude!"pos:[32,56] width:105 height:54
		 
		on ckb1 changed state do 

			if state == on then 
			(
				yo = openfile rd_name
				execute yo 

				ya = openfile "free_elbow_on.ms"
				execute ya
			)
			
			else
			(
				yo = openfile rd_name
				execute yo 
	
				ya = openfile "free_elbow_off.ms"
				execute ya
			)	
	)
)
select cercle[1]
modPanel.addModToSelection (emptymodifier ()) ui:on
custAttributes.add $.modifiers[#'Attribute Holder'] def


--yo = openfile "toto3.ms"
--execute yo
--close yo



-- enregistrer le script quelque part
-- cr�er un bouton sur le free_elbow_target pour charger le rollout
----cr�er un modifier
----placer le modifier sur le free_elbow_target


--CREER LES TWIST BONES

--CREER UN STRETCH ANIMABLE

--CREER LE PASSAGE FK/IK

--suppression des points

--delete points
















