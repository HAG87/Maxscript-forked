/*
-- maj:
	/-  pendre en charge les scene state pour les diff�rents points de vue plutot que les cameras multiples
	
	--convertir un selection de camera en camera avec scene state
	-- convertir une serie de scene state en multiples cameras
	
	-- faire fonctionner le "batch from cam" sur une selection multiple de cameras
	/- faire fonctionner le rename � la selection de camera dans la liste

	/- creer vraycam avec target
		
	/- cr�er les �tats de camera et de soleil pour chaque vue (scene state)
	/- cr�er les lignes de batch render pour chaque camera � rendre
	-- cr�er des batch render depuis les scene state
		-- faire focntionner sur la selection
	
	-- proposer la position du soleil en fonction de la camera(droite, gauche)
	
-- bug:
	/- � la suppression ou � la creation de camera la selection est incorrecte, backuper la selection pour la reactiver au refresh
	-- faire un callback pour detecter la creation de camera
	-- faire un callback au changement de selection de camera dans la scene
*/
Global re = maxOps.GetCurRenderElementMgr ()

maxVers = getFileVersion "$max/3dsmax.exe"

-- vrayCreateVRayPhysicalCamera()

fn convertToVrCam s =
(
	if classof s == TargetCamera or classof s == FreeCamera or classof s == Physical then
	(
-- 		vrCam = VRayPhysicalCamera transform: s.transform name: s.name targeted: true specify_fov: true fov: s.fov vignetting: false shutter_speed: 150 f_number: 9 	whiteBalance_preset: 2 whiteBalance: (color 191.25 226.023 255)
		
		local vrayCam = vrayCreateVRayPhysicalCamera ()
		
		vrayCam.transform = s.transform
		vrayCam.name = s.name
		
		vrayCam.targeted = true
		
		vrayCam.specify_fov = true
		vrayCam.fov = s.fov
		
		vrayCam.vignetting = false

		vrayCam.shutter_speed = 150
		vrayCam.f_number = 9

		vrayCam.whiteBalance_preset = 2
		vrayCam.whiteBalance = color 191.25 226.023 255
		
		s.name = s.name + "_bak"
	)
	else(format "camera inconvertible: %\n" s)
)

try(destroyDialog Pt2vue_renderer_UI)catch()
rollout Pt2vue_renderer_UI "Rendeur de points de vues" width: 500
(
	local params = #("outputPath", "outputPathMaq")
	
	local maxIni = getMAXIniFile()
	local armadasScriptsIni = (getFilenamePath maxIni) + "armadasScriptsIni.ini"
	
	-- 	vars
	local renderSize
	
	local camArray = #()
	local camToRender = #()
	
	local statesAr = #()
	local stateToDisplay = #()
	
	local stateSel
	local stateSelAr = ()
	
	local outputPath = ""
	local outputPathFolder
	
	local outputPathMaq = ""
	local outputPathMaqFolder
	
	local sceneCam = #()
			
	local camSel 
	local oneCamSelected = undefined
	
	local camSelAr
	
	local Pt2vueNode
	
-- 	vars bakup
		
	-- functions
	fn sortbyname v1 v2 =
	(
	-- 	vars
		local d
		
		if ( v1.name < v2.name) then
			d=-1
		else
			d=1
		
	--compare les numeros entre eux et les classe	
		case of
		(
			(d < 0.): -1
			(d > 0.): 1
			default: 0
		)
	)
	
	fn collectCamFN =
	(
		local camCollected = for c in cameras where classof c != Targetobject collect c
		qsort camCollected sortbyname
		
		-- collect cam to render
		camToRender = #()
		for cam in camCollected do
		(
			res = getUserProp cam "camToRender"
			if res != undefined then
			(
				if res then 
				(
-- 					format "cam to render: %\n" cam.name
					append camToRender cam
				)
				else
				(
-- 					format "cam to not render: %\n" cam.name
				)
			)
		)
		
-- 		format "cam to render: %\n" camToRender
		camCollected
	)
-- 	fn cam_filt obj = classof obj == freecamera

	fn collectSceneStates =
	(
		local num = sceneStateMgr.GetCount()   
		statesAr = for i = 1 to num collect sceneStateMgr.GetSceneState i
		format "statesAr: %,stateToDisplay: % \n" statesAr stateToDisplay
		stateToDisplay = for o in statesAr collect o
		sort stateToDisplay
		format "statesAr: %,stateToDisplay: % \n" statesAr stateToDisplay
	)


	-- def ui
	group "Camera Manager"
	(
		
		Multilistbox SceneCamsMLT "Scene Cameras:"  
-- 		button sortCamName "Classer par nom" across: 2
		button RebootCamBT "Refresh" across: 3 width: 120
		
		button selectCamBT "Select Cam" width: 120
		button CamViewBT "Camera View" width: 120
		button vrCamBT "convert to vr cam" enabled: true across: 3 width: 120
		

		button duplicateCamSelBT "Clone Cam"  width: 120
		button deleteReelCamBT "Del Cam" width: 120
		
-- 		button addCamSelect "Add to Render" width: 120 -- across: 2 
		
		edittext RenameCamEdit "Rename" 
		
-- 		pickbutton PickCam "Piquer une Camera"  filter: cam_filt across: 4

	)
		
	group "Scene States"
	(

-- 		button delOtherCamBT "Supprimer les autres"
		edittext sceneStateET "new scene state:" pos:[15,310] width: 420
		button newSceneStateBT "create" pos:[440, 310]
		Multilistbox BatchRenderMLT "scene states:"  
		
		
		
		button saveLigthStateBT "Save Scene State" width: 120 across: 3	
		button loadLigthStateBT "Load Scene State" width: 120
		button delCamSelect "Del Scene State Cam" width: 120 
	)
	
	group "Still - Batch Render"
	(
		edittext savepath  "Path:" text: "" readonly: true
		button SelectPathFile "..." across: 3
		button createBatchRenderBT "Batch from Cam"
		button batchFromStateBT "Batch from State"
	)
	
	group "Animation - Batch Render"
	(
		edittext savepathMaqET  "Path:" text: "" readonly: true
		button SelectPathFileMaqBT  "..." across: 3
-- 		button createBatchRenderBTMaq "Batch from Cam"
		button batchFromStateMaqBT "Batch from sel State"
	)
	
-- 	functions UI dependant
	fn refreshUI =
	(
		-- refresh scene cameras
		SceneCamsMLT.items = for o in camArray collect o.name
		
		BatchRenderMLT.items = for o in stateToDisplay collect o
		
		if isvalidnode camSel then 
		(
			RenameCamEdit.text = camSel.name 
			if classof camSel != VRayPhysicalCamera then vrCamBT.enabled = true else vrCamBT.enabled = false
		)
		else 
		(
			RenameCamEdit.text = "[SELECTION INCORRECTE]"
		)
		
		if outputPath != undefined then savepath.text = outputPath
		if outputPathMaq != undefined then savepathMaqET.text = outputPathMaq

	)

	fn getCamSelection =
	(
		oneCamSelected
		multiCamSel = (SceneCamsMLT.selection as array)
		
		format "selection: %, count: %\n" multiCamSel multiCamSel.count
		if multiCamSel.count ==1 then 
		(
			oneCamSelected = multiCamSel[1] 
			camSel = camArray[oneCamSelected]
			if isvalidnode camSel then format "camera selected: %\n" camSel.name
			camSelAr = #(camSel)
		)
		else if multiCamSel.count > 1 then
		(
-- 			print "youpi" 
			oneCamSelected == undefined
			camSel = undefined 
-- 			format "multi camera selection: %\n" multiCamSel
			camSelAr = for id in  multiCamSel collect camArray[id]
			
		)
		else
		(
			oneCamSelected == undefined
			camSel = undefined 
			camSelAr= #()
			format "none camera selection: %\n" multiCamSel
		)
		
		format "camSelAr: %\n" camSelAr
		
	)
	
-- Scene Camera actions
	on Pt2vue_renderer_UI open do
	(
		camArray = collectCamFN ()
		
		loadRolloutParams Pt2vue_renderer_UI params
		-- ajouter une verification des chemins d'enregistrement
		
		collectSceneStates()
		
		refreshUI()
		
		if camArray.count > 0 then
		(
			SceneCamsMLT.selection = #{1}
			getCamSelection()
		)
		
		refreshUI()
	)
	
	on Pt2vue_renderer_UI close do
	(
		if savepath.text != undefined do
		(
			writeRolloutParams Pt2vue_renderer_UI params
		)
	)
	
	on SceneCamsMLT selectionEnd do
	(
		getCamSelection()		
		refreshUI()
	)
	
	on SceneCamsMLT doubleClicked oneCam do
	(
		format "onecam: %\n" oneCam
		
		getCamSelection()		
		viewport.setCamera camSel
		select  camSel
	)		

	on RebootCamBT pressed do
	(
		camArray = collectCamFN ()
		refreshUI()
	)
	
		
	on selectCamBT pressed do
	(
		if camsel != undefined then select camsel else format "SELECTION INCORRECTE"
	)
	
	on CamViewBT pressed do
	(
		if isvalidnode camSel then
		(
			viewport.setCamera camsel 
		)
		else format "SELECTION INCORRECTE"
	)
	
	on vrCamBT pressed do
	(
		if isvalidnode camSel then
		(
			convertToVrCam camSel
			
			camArray = collectCamFN ()
			getCamSelection()	
			refreshUI()
		)
		else format "SELECTION INCORRECTE"
	)
		
	on duplicateCamSelBT pressed do
	(
		if isvalidnode camSel then
		(
			copy camsel
			
			camArray = collectCamFN ()
			getCamSelection()	
			refreshUI()
		)
		else format "SELECTION INCORRECTE"
	)
		
	on deleteReelCamBT pressed do
	(
		if isvalidnode camSel then
		(
			delete camsel
			
			camArray = collectCamFN ()
			getCamSelection()	
			refreshUI()
		)
		else format "SELECTION INCORRECTE"
	)
	
	on RenameCamEdit entered NewNameString do 
	(
		if isvalidnode camSel then
		(
			camsel.name = NewNameString
			
			camArray = collectCamFN ()
			getCamSelection()	
			refreshUI()
		)
		else format "SELECTION INCORRECTE"
	)
	
	on BatchRenderMLT selectionend do
	(
		local sel = BatchRenderMLT.selection as array
		
		if sel.count == 1 then
		(
			stateSel = BatchRenderMLT.items[sel[1]]
			stateSelAr = for i in BatchRenderMLT.selection collect BatchRenderMLT.items[i]
		)
		else if sel.count > 1 then
		(
			stateSel = undefined
			stateSelAr = for i in BatchRenderMLT.selection collect BatchRenderMLT.items[i]
		)
		else
		(
			stateSel = undefined
			stateSelAr = undefined
		)
		
		format "stateSel: %, stateSelAr:%\n" stateSel stateSelAr
	)
	
	on newSceneStateBT pressed do
	(
		sceneStateMgr.Capture sceneStateET.text #{1,2,4,5}
		
		collectSceneStates()
		refreshUI()
	)
	
	on saveLigthStateBT pressed do
	(
		-- retrouver la selection du scene state
		
		sceneStateMgr.Capture stateSel #{1,2,4,5}
		
		collectSceneStates()
		refreshUI()
	)
	
	on loadLigthStateBT pressed do
	(
		sceneStateMgr.Restore  stateSel #{1,2,4,5}
	)
	
	on SelectPathFile pressed do
	(
		local res  = getSavePath caption: "Select \"point de vue\" folder" -- initialDir: pathToSearchET.text
		
		if res != undefined then outputPath = copy res
		format "outputPath: %\n" outputPath
		refreshUI()
	)

	
	on createBatchRenderBT pressed do
	(
		for c in camselAr do
		(
			
		)
		
		-- prevoir les exception avec un find view
		local check = batchRenderMgr.FindView camSel.name
		if check == 0 then
		(
			local batch = batchRenderMgr.CreateView camSel
			batch.name = camSel.name
			local filename = outputPath + "\\" + camSel.name + ".jpg"
			format "path: %\n" filename
			
	-- 		test.sceneStateName = ""
			batch.outputFilename = filename
		)else(format "batch render deja existant: %\n" camSel.name)

	)
	
	on batchFromStateBT pressed do
	(
-- 		cam = $Camera001
-- 		outputPath = @"T:\BPD Marignan\SoBlagnac_0917\Perspectives\Perspectives\ptsdevue"
		
		
-- 		local idSel 
		
		local statesIds = BatchRenderMLT.selection
		
		for c in camselAr do
		(
			for i in statesIds do
			(
				local id = finditem statesAr stateToDisplay[i]
	-- 			format "state: %, i: % , id:% , reel state: %, display state: %\n" (sceneStateMgr.GetSceneState id) i  id statesAr[id] stateToDisplay[i]
				local oneName = (sceneStateMgr.GetSceneState id)
				local check = batchRenderMgr.FindView  (sceneStateMgr.GetSceneState id)
				if check == 0 then
				(
					local batch = batchRenderMgr.CreateView undefined
					batch.name = oneName
					batch.camera = c
					local filename = outputPath + "\\" + oneName + ".jpg"
					format "folder: %\n"filename
					makedir (getFilenamePath  filename)
					batch.sceneStateName = oneName
					batch.outputFilename = filename
				)
				
			)
		)	
		
		
		/*
		num = sceneStateMgr.GetCount()   
		for i = 1 to num do
		(
			local oneName = sceneStateMgr.GetSceneState i
			
				-- prevoir les exception avec un find view
			local check = batchRenderMgr.FindView oneName
			if check == 0 then
			(
				local batch = batchRenderMgr.CreateView undefined
				batch.name = oneName
				batch.camera = camSel
-- 				format "outputPathFolder: %, outputPath: %\n" outputPathFolder outputPath
				local filename = outputPath + "\\" + oneName + ".jpg"
				format "path: %\n" filename
				
				batch.sceneStateName = oneName
				batch.outputFilename = filename
			)else(format "batch render deja existant: %\n" oneName)
		)
		*/
		
	)
	
	on SelectPathFileMaqBT pressed do
	(
		local res = getSavePath caption: "Select \"maquette 360\" folder" -- initialDir: pathToSearchET.text
		
		if res != undefined then outputPathMaq = res
		format "outputPathMaq: %\n" outputPathMaq
		refreshUI()
	)
	
	on batchFromStateMaqBT pressed do
	(
		
		local statesIds = BatchRenderMLT.selection
-- 		format "statesIds: %\n" statesIds
		for c in camselAr do
		(
			for i in statesIds do
			(
				local id = finditem statesAr stateToDisplay[i]
	-- 			format "state: %, i: % , id:% , reel state: %, display state: %\n" (sceneStateMgr.GetSceneState id) i  id statesAr[id] stateToDisplay[i]
				local oneName = (sceneStateMgr.GetSceneState id)
				local check = batchRenderMgr.FindView  (c.name + "_" + oneName)
				if check == 0 then
				(
					local batch = batchRenderMgr.CreateView undefined
					batch.name = c.name + "_" + oneName
					batch.camera = c
-- 					local filename = outputPathMaq + "\\" + c.name + "_" + oneName + "\\"+ c.name + "_" + oneName + "_.jpg"
					local filename = outputPathMaq + "\\"  + oneName + "\\" + oneName + "_.jpg"
-- 					format "folder: %\n"filename
					makedir (getFilenamePath  filename)
					batch.sceneStateName = oneName
					batch.outputFilename = filename
					format "new batch render: %\n"filename
				)
				else()
				
			)
		)		
	)
)
createdialog Pt2vue_renderer_UI


/*
test = sceneStateMgr.GetSceneState 1

b = batchRenderMgr.GetView 1
showinterface b
b.camera 
b.width 
b.height 
b.startFrame 
b.endFrame 
b.name
b.presetFile 
b.sceneStateName 
b.enabled
b.pixelAspect 
b.overridePreset 
b.outputFilename
*/

	/*
	on addCamSelect pressed do 
	(
		
		if isvalidnode camsel then
		(
			setUserProp camsel "camToRender" true
			appendifunique camToRender camsel
			setUserProp camToRender[i] "camToRender" true
		)
		else format "SELECTION INCORRECTE"
		
		refreshUI()
	)
	*/
	
-- Render Camera actions
	/*
	on delCamSelect pressed do
	(
		cameToRemoveID = BatchRenderMLT.selection as array
		
		
		for i = cameToRemoveID.count to  1 by -1 do
		(
			
			format "cams to remove: %\n" camToRender[i].name
			deleteitem camToRender i
			setUserProp camToRender[i] "camToRender" false
-- 			format "cams to remove: %\n" camToRender[i].name
		)
		
-- 		format "cams to remove: %\n" cameToRemove
		
		for i=(SceneCamsMLT.selection as array).count to 1 by -1  do
		(			
			deleteItem camToRender (SceneCamsMLT.selection as array)[i]
		)
		
		refreshUI()
	)
	*/