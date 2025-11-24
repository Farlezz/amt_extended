-- client/element_manipulation.lua
-- Post-generation manipulation: alterGeneration, keyboard rotation handlers, continuous rotation
-- Extracted from amt_gui.lua lines 1000-1054, 1056-1207, 1345-1378

-- Recieve new elements from server to handle
addEvent("sendBackRequestedElements", true)
addEventHandler("sendBackRequestedElements", getRootElement(),
function(elements)
	outputDebugString("AMT: client handle elements changed.")
	AMT.hElements = elements

	-- No need to restore rotation anymore as we don't physically rotate the base element
	-- This prevents the "stuck" bug if server fails


	local index = #AMT.elementList + 1
	AMT.elementList[index] = {}
	for i = 1, #AMT.hElements do
		local element = AMT.hElements[i]
		local index2 = #AMT.elementList[index]+1
		AMT.elementList[index][index2] = element.element
		-- Use stored rotation (includes twist) instead of base element's actual rotation
		local baseX, baseY, baseZ = getElementPosition(element.source)
		local posX, posY, posZ = getTransformedPosition(baseX, baseY, baseZ, element.sourceX, element.sourceY, element.sourceZ, element.posX, element.posY, element.posZ)

		-- Apply offset in local space (NEW: fixes offset + curved loop bug)
		posX, posY, posZ = applyOffsetInLocalSpace(posX, posY, posZ, element.rotX, element.rotY, element.rotZ, element.offsetAmount, element.offsetDirX, element.offsetDirY, element.offsetDirZ)

		local rotX, rotY, rotZ = element.rotX, element.rotY, element.rotZ
		triggerServerEvent("onRequestUpdateElementRotation", element.element, rotX, rotY, rotZ)
		triggerServerEvent("onRequestUpdateElementPosition", element.element, posX, posY, posZ)
	end
		exports.editor_main:selectElement(AMT.hElements[1].source)
	-- Clear preview elements after generation completes using centralized function
	clearPreviews()
	
	-- Switch to edit/save mode (updates button text and highlighting)
	-- We do this HERE now, to ensure we only switch if generation actually succeeded
	GUIBuilder.setGenerateMode(false)
	guiSetEnabled(AMT.gui.gen_button, true) -- Re-enable button (it will be "Save" now)
end)

addEvent("onGenerationFailed", true)
addEventHandler("onGenerationFailed", getRootElement(),
function()
	outputDebugString("AMT: Generation failed or rejected by server.")
	guiSetEnabled(AMT.gui.gen_button, true)
	guiSetText(AMT.gui.gen_button, "Generate")
	GUIBuilder.setGenerateMode(true)
end)

-- Handle generation rotation and position change when rotating element
addEventHandler("onClientRender", getRootElement(),
function()
	if #AMT.hElements == 0 or AMT.generate then return end

	if not isElementStreamedIn(AMT.hElements[1].source) then return end
	local nx, ny, nz = getElementPosition(AMT.hElements[1].source)
	local rotate = {}
	rotate.slow = "lalt"
	rotate.fast = "lshift"
	rotate.key = "lctrl"
	rotate.left = "arrow_l"
	rotate.right = "arrow_r"
	rotate.forward = "arrow_u"
	rotate.backward = "arrow_d"
	rotate.upwards = "pgup"
	rotate.downwards = "pgdn"
	local doRotate = false
	if(getKeyState(rotate.key) and exports.editor_main:getSelectedElement() == AMT.hElements[1].source)then
		doRotate = true
		exports.move_keyboard:disable()
		AMT.rotationDisabled = true
	elseif(AMT.rotationDisabled)then
		exports.move_keyboard:enable()
		AMT.rotationDisabled = false
	end
	local rotSlow, rotMedium, rotFast = exports.move_keyboard:getRotateSpeeds()
	local speed = rotMedium
	if(getKeyState(rotate.slow))then
		speed = rotSlow
	end
	if(getKeyState(rotate.fast))then
		speed = rotFast
	end
	-- only check key state once, because it may change under the loop (wont rotate for all object)
	local left, right, forward, backward, upwards, downwards = false, false, false, false, false, false

	local diffRotX = tonumber(guiGetText(AMT.gui.additional_rotX_field))
	local diffRotY = tonumber(guiGetText(AMT.gui.additional_rotY_field))
	local diffRotZ = tonumber(guiGetText(AMT.gui.additional_rotZ_field))
	local rotX, rotY, rotZ = getElementRotation(AMT.hElements[1].source)
	if(doRotate)then
		if(getKeyState(rotate.forward))then
			forward = true
			rotX, rotY, rotZ = rotateY(rotX, rotY, rotZ, speed)
			diffRotY = diffRotY + speed
		end
		if(getKeyState(rotate.backward))then
			backward = true
			rotX, rotY, rotZ = rotateY(rotX, rotY, rotZ, -speed)
			diffRotY = diffRotY - speed
		end

		if(getKeyState(rotate.upwards))then
			upwards = true
			rotX, rotY, rotZ = rotateX(rotX, rotY, rotZ, speed)
			diffRotX = diffRotX + speed
		end
		if(getKeyState(rotate.downwards))then
			downwards = true
			rotX, rotY, rotZ = rotateX(rotX, rotY, rotZ, -speed)
			diffRotX = diffRotX - speed
		end

		if(getKeyState(rotate.right))then
			right = true
			rotX, rotY, rotZ = rotateZ(rotX, rotY, rotZ, speed)
			diffRotZ = diffRotZ + speed
		end
		if(getKeyState(rotate.left))then
			left = true
			rotX, rotY, rotZ = rotateZ(rotX, rotY, rotZ, -speed)
			diffRotZ = diffRotZ - speed
		end
		setElementRotation(AMT.hElements[1].source, rotX, rotY, rotZ)
	end
	if(diffRotX)then
		guiSetText(AMT.gui.additional_rotX_field, diffRotX)
	end
	if(diffRotY)then
		guiSetText(AMT.gui.additional_rotY_field, diffRotY)
	end
	if(diffRotZ)then
		guiSetText(AMT.gui.additional_rotZ_field, diffRotZ)
	end

	for i = 1, #AMT.hElements do
		local rotX, rotY, rotZ = getElementRotation(AMT.hElements[i].element)
		local diffX, diffY, diffZ = rotX - AMT.hElements[1].sourceX, rotY - AMT.hElements[1].sourceY, rotZ - AMT.hElements[1].sourceZ
		local posX, posY, posZ = getTransformedPosition(nx, ny, nz, AMT.hElements[1].sourceX, AMT.hElements[1].sourceY, AMT.hElements[1].sourceZ, AMT.hElements[i].posX, AMT.hElements[i].posY, AMT.hElements[i].posZ)

		-- Apply offset in local space (NEW: fixes offset + curved loop bug)
		local elem = AMT.hElements[i]
		posX, posY, posZ = applyOffsetInLocalSpace(posX, posY, posZ, elem.rotX, elem.rotY, elem.rotZ, elem.offsetAmount, elem.offsetDirX, elem.offsetDirY, elem.offsetDirZ)

		-- posX, posY, posZ = getTransformedElementPosition(AMT.hElements[i].source, AMT.hElements[i].posX, AMT.hElements[i].posY, AMT.hElements[i].posZ)
		setElementPosition(AMT.hElements[i].element, posX, posY, posZ)
		if(doRotate)then
			if(forward)then
				rotX, rotY, rotZ = rotateY(rotX, rotY, rotZ, speed)
			end
			if(backward)then
				rotX, rotY, rotZ = rotateY(rotX, rotY, rotZ, -speed)
			end

			if(upwards)then
				rotX, rotY, rotZ = rotateX(rotX, rotY, rotZ, speed)
			end
			if(downwards)then
				rotX, rotY, rotZ = rotateX(rotX, rotY, rotZ, -speed)
			end

			if(right)then
				rotX, rotY, rotZ = rotateZ(rotX, rotY, rotZ, speed)
			end
			if(left)then
				rotX, rotY, rotZ = rotateZ(rotX, rotY, rotZ, -speed)
			end
			setElementRotation(AMT.hElements[i].element, rotX, rotY, rotZ)
		end
	end
end)

function alterGeneration(element)
	local rx, ry, rz = 0, 0, 0
	rx = tonumber(guiGetText(AMT.gui.additional_rotX_field))
	ry = tonumber(guiGetText(AMT.gui.additional_rotY_field))
	rz = tonumber(guiGetText(AMT.gui.additional_rotZ_field))
	conrx = tonumber(guiGetText(AMT.gui.conrot_rotX_field))
	conry = tonumber(guiGetText(AMT.gui.conrot_rotY_field))
	conrz = tonumber(guiGetText(AMT.gui.conrot_rotZ_field))
	if not rx or not ry or not rz or not conrx or not conry or not conrz or not AMT.hElements or #AMT.hElements == 0 then return end
	conrx = conrx/#AMT.hElements
	conry = conry/#AMT.hElements
	conrz = conrz/#AMT.hElements

	-- For curved loops, use the original base rotation (before twist was applied)
	-- For regular loops, use the stored rotation from generation
	local rotX, rotY, rotZ
	-- For curved loops, use the original base rotation (before twist was applied)
	-- For regular loops, use the stored rotation from generation
	local rotX, rotY, rotZ
	
	-- Check if twist was used (implicit curved loop)
	local twistX = tonumber(guiGetText(AMT.gui.twist_rotX_field)) or 0
	local twistY = tonumber(guiGetText(AMT.gui.twist_rotY_field)) or 0
	local twistZ = tonumber(guiGetText(AMT.gui.twist_rotZ_field)) or 0
	local isCurvedLoop = (twistX ~= 0 or twistY ~= 0 or twistZ ~= 0)

	if isCurvedLoop then
		rotX, rotY, rotZ = AMT.originalBaseRotation.x, AMT.originalBaseRotation.y, AMT.originalBaseRotation.z
	else
		rotX, rotY, rotZ = AMT.hElements[1].sourceX, AMT.hElements[1].sourceY, AMT.hElements[1].sourceZ
	end
	rotX, rotY, rotZ = rotateX(rotX, rotY, rotZ, rx)
	rotX, rotY, rotZ = rotateY(rotX, rotY, rotZ, ry)
	rotX, rotY, rotZ = rotateZ(rotX, rotY, rotZ, rz)
	setElementRotation(AMT.hElements[1].source, rotX, rotY, rotZ)

	for i = 1, #AMT.hElements do
		local rotX, rotY, rotZ = AMT.hElements[i].rotX, AMT.hElements[i].rotY, AMT.hElements[i].rotZ
		rotX, rotY, rotZ = rotateY(rotX, rotY, rotZ, ry+conry*i)
		rotX, rotY, rotZ = rotateX(rotX, rotY, rotZ, rx+conrx*i)
		rotX, rotY, rotZ = rotateZ(rotX, rotY, rotZ, rz+conrz*i)
		setElementRotation(AMT.hElements[i].element, rotX, rotY, rotZ)
	end
end
