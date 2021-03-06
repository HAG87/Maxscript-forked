-- am�lioration  option: dans le cas d'objet pr�sentant de la transparence ou de l'alpha adapter le mat�riaux blanc

Global re = maxOps.GetCurRenderElementMgr ()


	fn CleanOutEltsFN = 
(
	num = re.numrenderelements ()
		
	clean_name = ""

	for i = 0 to (num - 1) do
	(
		re.SetRenderElementFilename i clean_name
	)
)

rollout MRAlphaSelRLT "Rendu Apha de la selection."
(

	-- DECLARATION ---------------------------------------------------------------------------------------------------

	local MRbak = undefined

	-- declaration de la structure du couple objet/material
	struct objMatPair (obj , objMat )

	-- declaration de l'array d'objet � passer en alpha
	local objSelBak = #()

	-- declaration le mat�riaux blanc autoillumin�
		
	local MRMatLite = Arch___Design__mi name: "Alpha_Mat" diff_color: (color 255 255 255) refl_weight: 0 self_illum_on: on

	-- declaration du preset de rendu alpha
	local MR_alpha_preset = mental_ray_renderer name: "Alpha_Preset" \
	FinalGatherEnable2: false \-- d�sactivation du final gather, ,  
	GlobalIllumEnable: false \ -- du photon map
	ReflectionsEnable: false \ -- de la reflection,
	RefractionsEnable: false \ -- de la refraction,
	ShadowsEnable: false  -- des shadows, 

	--declaration de la structure light et etat de la light
	struct liteStatePair (lite, liteState)

	-- declaration de l'array de light
	local lightBak = #()

	-- declaration de la variable de l'�tat du background
	local skyStateBak = undefined

	-- declaration de la variable de l'�tat  de l'exposition
	local expStateBak = undefined 
	
-- 	UI
	Button selAphaMrBT "Go! Go! l'alpha"
	
-- 	event
	on selAphaMrBT pressed do
	(
		-- CREATION BACKUP ---------------------------------------------------------------------------------------------------

		-- m�moriser les objets selectionner et leur mat�riaux dans une structure
		objSelBak = #()
		for o in ($selection as array) do
		(
			if superclassof o == geometryclass then 
			(
				TempObjMatPair = objMatPair obj: o objMat: o.material
				append objSelBak TempObjMatPair
			)
		)
		print objSelBak

		-- m�moriser les param�tres courant de mental ray: 
		MRbak = renderers.production

		-- m�moriser les light de la sc�ne et leur �tat gr�ce � une structure
		lightBak = #()
		for o in ($* as array) do
		(
			if superclassof o == light then 
			(
				liteTemp = liteStatePair lite: o liteState: o.on
				append lightBak liteTemp
			)
		)
		print lightBak

		-- m�moriser l'�tat du background
		skyStateBak = useEnvironmentMap

		-- m�moriser l'�tat de l'exposition
		expStateBak = SceneExposureControl.exposureControl.active

		-- PRESET ---------------------------------------------------------------------------------------------------

		-- appliqu� le materiaux blanc autoillumin� aux objects selectionner
		for o in objSelBak do o.obj.material = MRMatLite

		-- application du preset de rendu alpha
		renderers.production = MR_alpha_preset

		-- extinction des lumi�res
		for o in lightBak do o.lite.on = false

		-- desactivation du background
		useEnvironmentMap = off

		-- desactivation de l'exposition
		SceneExposureControl.exposureControl.active = false

		-- RENDU ---------------------------------------------------------------------------------------------------
		-- faire le rendu
		CleanOutEltsFN ()
		max quick render

		-- RESTAURATION BACKUP ---------------------------------------------------------------------------------------------------

		-- restauration des mat�riaux aux objets
		for o in objSelBak do o.obj.material = o.objMat

		-- restauration des reglages mental ray
		renderers.production = MRbak

		-- restauration des lumi�res
		for o in lightBak do o.lite.on = o.liteState

		-- restauration du background
		useEnvironmentMap = skyStateBak

		-- restauration de l'�tat de l'exposition
		SceneExposureControl.exposureControl.active = expStateBak
	)
)

createdialog MRAlphaSelRLT
