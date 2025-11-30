-- client/gui_generator.lua
-- Generator controls and logic: field updates, startGenerating function, calculation functions
-- Extracted from amt_gui.lua lines 711-730, 733-737, 740-865, 867-884, 886-900, 902-998

function updateAMTFields()
	-- we only want to change edit fields
	if(source == AMT.gui.objects_auto_box)then return end

	-- Reset preview state when any field that affects preview changes
	if(source == AMT.gui.loops_field or source == AMT.gui.radius_field or source == AMT.gui.objects_field or
	   source == AMT.gui.objects_times_field or source == AMT.gui.offset_field)then
		resetPreviewState()
		previewUpdate()
	end

	if(source == AMT.gui.radius_field)then
		local number = tonumber(guiGetText(source))
		if(number ~= nil)then
			if AMT.selectedElement and AMT.img[AMT.selectedElement] then
				AMT.img[AMT.selectedElement].dist = number
			end
		end
		if AMT.selectedElement and AMT.img[AMT.selectedElement] and (AMT.img[AMT.selectedElement].dist < MIN_RADIUS)then
			AMT.img[AMT.selectedElement].dist = MIN_RADIUS
		end
	end
end

-- Update preview when twist values change
function onTwistChanged()
	if(AMT.selectedElement == nil)then return end
	resetPreviewState()
	previewUpdate()
end

-- Update autocount object edit field if its enabled
function updateAutocount()
	if(AMT.selectedElement == nil or not guiCheckBoxGetSelected(AMT.gui.objects_auto_box))then return end
	local radius = tonumber(guiGetText(AMT.gui.radius_field))
	local offsetValue = tonumber(guiGetText(AMT.gui.offset_field))
	if not radius or radius <= 0 or not offsetValue then return end
	local objects = tonumber(guiGetText(AMT.gui.objects_field)) or 0
	if(objects <= 0)then
		objects = 1 -- Prevent division by zero when recovering from invalid autocount state
	end
	local offset = offsetValue / objects
	local side = "x"
	local center = AMT.img[AMT.selectedElement].selectedCenter
	local dir = AMT.img[AMT.selectedElement].selectedDir
	local rot = 360 / objects
	local rx, ry, rz = 0, 0, 0
	if(center == 1)then
		if(dir == 5)then
			side = "y"
			rz = -atan2(offset, cos(rot - 90)*radius)
		end
		if(dir == 6)then
			side = "y"
			rz = -atan2(-offset, -cos(rot - 90)*radius)
		end
		if(dir == 3)then
			side = "x"
			rz = atan2(offset, -cos(rot - 90)*radius)
		end
		if(dir == 4)then
			side = "x"
			rz = -atan2(offset, cos(rot - 90)*radius)
		end
	end
	if(center == 2)then
		if(dir == 5)then
			side = "y"
		end
		if(dir == 6)then
			side = "y"
		end
		if(dir == 3)then
			side = "x"
		end
		if(dir == 4)then
			side = "x"
		end
	end
	if(center == 3)then
		if(dir == 5)then
			side = "y"
		end
		if(dir == 6)then
			side = "y"
		end
		if(dir == 1)then
			side = "z"
		end
		if(dir == 2)then
			side = "z"
		end
	end
	if(center == 4)then
		if(dir == 5)then
			side = "y"
		end
		if(dir == 6)then
			side = "y"
		end
		if(dir == 1)then
			side = "z"
		end
		if(dir == 2)then
			side = "z"
		end
	end
	if(center == 5)then
		if(dir == 1)then
			side = "z"
		end
		if(dir == 2)then
			side = "z"
		end
		if(dir == 3)then
			side = "x"
		end
		if(dir == 4)then
			side = "x"
		end
	end
	if(center == 6)then
		if(dir == 1)then
			side = "z"
		end
		if(dir == 2)then
			side = "z"
		end
		if(dir == 3)then
			side = "x"
		end
		if(dir == 4)then
			side = "x"
		end
	end
	local length = getElementLength(AMT.selectedElement, side)
	objects = math.ceil(length*radius)
	if(objects < 1)then
		objects = 1
	end
	guiSetText(AMT.gui.objects_field, tostring(objects))
	outputDebugString("AMT: autocount objects set automatically to: "..tostring(objects))
	resetPreviewState()
	previewUpdate()
end

function getElementLength(element, side)
	side = string.lower(tostring(side))
	local length = 0
	local minX, minY, minZ, maxX, maxY, maxZ = getElementBoundingBox(element)
	minX, minY, minZ, maxX, maxY, maxZ = math.abs(minX), math.abs(minY), math.abs(minZ), math.abs(maxX), math.abs(maxY), math.abs(maxZ)
	--local x, y, z = (maxX + minX)/2, (maxY + minY)/2, (maxZ + minZ)/2
	if(side == "x")then
		length = PI/maxX
	end
	if(side == "y")then
		length = PI/maxY
	end
	if(side == "z")then
		length = PI/maxZ
	end
	outputDebugString("AMT: automatic element length = "..length..".")
	return length
end

function editFieldHandle()
	-- source is the gui element
	if(source == AMT.gui.objects_auto_box)then
		local selected = guiCheckBoxGetSelected(AMT.gui.objects_auto_box)
		guiSetEnabled(AMT.gui.objects_field, (not selected))
	end
end

-- Start generating loop/wallride etc...
function startGenerating()
	if(AMT.generate)then
		if(AMT.selectedElement == nil)then
			outputChatBox("[AMT ERROR]: No element has been selected!", 255, 25, 25)
			return false
		end
		local loops = tonumber(guiGetText(AMT.gui.loops_field))
		local radius = tonumber(guiGetText(AMT.gui.radius_field))
		local objectsValue = tonumber(guiGetText(AMT.gui.objects_field))
		local timesValue = tonumber(guiGetText(AMT.gui.objects_times_field))
		local offset = tonumber(guiGetText(AMT.gui.offset_field))
		if not loops or not radius or not objectsValue or not timesValue or not offset then
			outputChatBox("[AMT ERROR]: error in number value in edit fields!", 255, 25, 25)
			return false
		end
		local objects = objectsValue * timesValue
		--radius = math.floor(radius)
		if(radius < MIN_RADIUS)then
			outputChatBox("[AMT ERROR]: Radius is less than minimal allowed radius ("..MIN_RADIUS..")", 255, 25, 25)
			return false
		end
		--objects = math.floor(objects*times)
		if(loops <= 0 or objects <= 0)then
			outputChatBox("[AMT ERROR]: loops and/or objects cant be less or equal to 0", 255, 25, 25)
			return false
		end
		guiSetText(AMT.gui.additional_rotX_field, "0")
		guiSetText(AMT.gui.additional_rotY_field, "0")
		guiSetText(AMT.gui.additional_rotZ_field, "0")

		guiSetText(AMT.gui.conrot_rotX_field, "0")
		guiSetText(AMT.gui.conrot_rotY_field, "0")
		guiSetText(AMT.gui.conrot_rotZ_field, "0")
		outputDebugString("AMT: Generating...")

		-- Determine if curved loop is enabled based on twist values
		local twistX = tonumber(guiGetText(AMT.gui.twist_rotX_field)) or 0
		local twistY = tonumber(guiGetText(AMT.gui.twist_rotY_field)) or 0
		local twistZ = tonumber(guiGetText(AMT.gui.twist_rotZ_field)) or 0
		local isCurvedLoop = (twistX ~= 0 or twistY ~= 0 or twistZ ~= 0)

		-- Store original rotation globally (still needed for alterGeneration)
		AMT.originalBaseRotation.x, AMT.originalBaseRotation.y, AMT.originalBaseRotation.z = getElementRotation(AMT.selectedElement)
		
		-- Calculate the "twisted" rotation mathematically without physically rotating the element
		-- This prevents the element from getting "stuck" if the server rejects the request
		local rotX, rotY, rotZ = AMT.originalBaseRotation.x, AMT.originalBaseRotation.y, AMT.originalBaseRotation.z
		
		if(isCurvedLoop)then
			-- Apply twist using rotation composition functions
			rotX, rotY, rotZ = rotateX(rotX, rotY, rotZ, twistX)
			rotX, rotY, rotZ = rotateY(rotX, rotY, rotZ, twistY)
			rotX, rotY, rotZ = rotateZ(rotX, rotY, rotZ, twistZ)
			outputDebugString("AMT: Calculated twisted rotation ("..rotX..", "..rotY..", "..rotZ..") without physical rotation")
		end

		local addX, addY, addZ = 0, 0, 0
		local conX, conY, conZ = 0, 0, 0

		local origRotX, origRotY, origRotZ, twistAmountX, twistAmountY, twistAmountZ = nil, nil, nil, nil, nil, nil
		if isCurvedLoop then
			origRotX, origRotY, origRotZ = AMT.originalBaseRotation.x, AMT.originalBaseRotation.y, AMT.originalBaseRotation.z
			twistAmountX, twistAmountY, twistAmountZ = twistX, twistY, twistZ
		end

		-- Pass the CALCULATED rotation (rotX, rotY, rotZ) which includes the twist if applicable
		triggerServerEvent("onRequestGenerate", getLocalPlayer(), AMT.selectedElement, rotX, rotY, rotZ, loops, radius, objects, offset, AMT.img[AMT.selectedElement].selectedCenter, AMT.img[AMT.selectedElement].selectedDir, addX, addY, addZ, conX, conY, conZ, nil, nil, nil, isCurvedLoop, origRotX, origRotY, origRotZ, twistAmountX, twistAmountY, twistAmountZ)

		-- Disable twist fields after generating (lock the curved rotation values)
		-- Values are kept visible but not editable until Save
		guiSetEnabled(AMT.gui.twist_rotX_field, false)
		guiSetEnabled(AMT.gui.twist_rotY_field, false)
		guiSetEnabled(AMT.gui.twist_rotZ_field, false)

		-- Switch to edit/save mode (updates button text and highlighting)
		-- GUIBuilder.setGenerateMode(false) -- MOVED: Now handled in sendBackRequestedElements
		guiSetEnabled(AMT.gui.gen_button, false)
		guiSetText(AMT.gui.gen_button, "Generating...")
	else
		-- Logic for "Save" - just saves the current loop, resets fields, and goes back to generate mode
		-- The user can then configure the next loop and click "Generate" manually

		outputDebugString("AMT: saving...")
		if not AMT.hElements or #AMT.hElements == 0 then
			outputDebugString("AMT ERROR: No elements to save!", 1)
			-- Reset state just in case
			GUIBuilder.setGenerateMode(true)
			return
		end
		local tData = {}
		for i = 1, #AMT.hElements do
			--if(isElementStreamedIn(AMT.hElements[i].element))then
				triggerServerEvent("onRequestUpdateElementPosition", AMT.hElements[i].element, getElementPosition(AMT.hElements[i].element))
				triggerServerEvent("onRequestUpdateElementRotation", AMT.hElements[i].element, getElementRotation(AMT.hElements[i].element))
			--end
		end
		triggerServerEvent("onRequestUpdateElementRotation", AMT.hElements[1].source, getElementRotation(AMT.hElements[1].source))
		-- Send data to use and recreate all the objects.
		--triggerServerEvent("onRequestRecreateElements", getLocalPlayer(), tData)
		tData = {}
		AMT.hElements = {}

		-- Reset ALL rotation fields to 0
		guiSetText(AMT.gui.additional_rotX_field, "0")
		guiSetText(AMT.gui.additional_rotY_field, "0")
		guiSetText(AMT.gui.additional_rotZ_field, "0")
		guiSetText(AMT.gui.conrot_rotX_field, "0")
		guiSetText(AMT.gui.conrot_rotY_field, "0")
		guiSetText(AMT.gui.conrot_rotZ_field, "0")

		-- Re-enable and reset twist/curve rotation fields on Save
		guiSetEnabled(AMT.gui.twist_rotX_field, true)
		guiSetEnabled(AMT.gui.twist_rotY_field, true)
		guiSetEnabled(AMT.gui.twist_rotZ_field, true)
		guiSetText(AMT.gui.twist_rotX_field, "0")
		guiSetText(AMT.gui.twist_rotY_field, "0")
		guiSetText(AMT.gui.twist_rotZ_field, "0")

		-- Switch back to preview/generate mode (updates button text and highlighting)
		GUIBuilder.setGenerateMode(true)
	end
end
