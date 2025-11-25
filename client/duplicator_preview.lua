-- client/duplicator_preview.lua
-- Preview generation logic for duplicator mode
-- Shows a preview of what will be duplicated before the user clicks "Duplicate"
--
-- Dependencies: shared/constants.lua (PREVIEW_LIMIT, AMT.VALID_DUPLICATION_TYPES)
-- Uses the shared AMT.previewElements table (same as Generator preview)
-- Only one preview can be active at a time (Generator OR Duplicator)

-- UI Constants
local PREVIEW_ALPHA = 150  -- Transparency level for preview elements (0-255)

-- Alias to the shared clearPreviews function for consistency
-- clearPreviews() is defined in gui_preview.lua and works for both modes
function clearDuplicatorPreview()
	clearPreviews()
end

-- Track selected elements for preview update
local dupState = {
	element1 = nil,
	element2 = nil,
	amount = nil,
	element1Pos = nil,
	element2Pos = nil,
	element1Rot = nil,
	element2Rot = nil,
	type1 = nil,
	type2 = nil
}

-- Helper to check if position changed
local function positionChanged(pos1, pos2)
	if not pos1 or not pos2 then return true end
	return pos1.x ~= pos2.x or pos1.y ~= pos2.y or pos1.z ~= pos2.z
end

-- Helper to check if rotation changed
local function rotationChanged(rot1, rot2)
	if not rot1 or not rot2 then return true end
	return rot1.x ~= rot2.x or rot1.y ~= rot2.y or rot1.z ~= rot2.z
end

-- Reset tracking state (called when switching windows or clearing)
local function resetDuplicatorTrackingState()
	dupState.element1 = nil
	dupState.element2 = nil
	dupState.amount = nil
	dupState.element1Pos = nil
	dupState.element2Pos = nil
	dupState.element1Rot = nil
	dupState.element2Rot = nil
	dupState.type1 = nil
	dupState.type2 = nil
end

-- Update the duplicator preview based on selected elements and copy count
local function updateDuplicatorPreview()
	-- Guard: Check if GUI is initialized
	if not AMT.gui[2] or not isElement(AMT.gui[2].window) then
		return
	end

	-- Only update when on duplicator window (window 2)
	if AMT.currentWindow ~= 2 or not guiGetVisible(AMT.gui[2].window) then
		return
	end

	-- Validate elements are selected
	if not isElement(AMT.duplicateElement[1]) or not isElement(AMT.duplicateElement[2]) then
		clearDuplicatorPreview()
		return
	end

	-- Validate element types
	local type1 = getElementType(AMT.duplicateElement[1])
	local type2 = getElementType(AMT.duplicateElement[2])
	if not AMT.VALID_DUPLICATION_TYPES[type1] or not AMT.VALID_DUPLICATION_TYPES[type2] then
		clearDuplicatorPreview()
		return
	end

	-- Guard: Check if dup_amount GUI element exists
	if not AMT.gui.dup_amount or not isElement(AMT.gui.dup_amount) then
		return
	end

	-- Get copies count
	local copies = tonumber(guiGetText(AMT.gui.dup_amount))
	if not copies or copies <= 0 then
		clearDuplicatorPreview()
		return
	end

	-- Calculate duplication parameters
	local px, py, pz = getElementPosition(AMT.duplicateElement[1])
	local rx, ry, rz = getElementRotation(AMT.duplicateElement[1])
	local px2, py2, pz2 = getElementPosition(AMT.duplicateElement[2])
	local rx2, ry2, rz2 = getElementRotation(AMT.duplicateElement[2])
	
	local posDiffX, posDiffY, posDiffZ = px2 - px, py2 - py, pz2 - pz
	local rotDiffX, rotDiffY, rotDiffZ = rx2 - rx, ry2 - ry, rz2 - rz
	
	local model1 = getElementModel(AMT.duplicateElement[1])
	local model2 = getElementModel(AMT.duplicateElement[2])

	-- Limit preview to reasonable count to prevent performance issues
	local previewCopies = math.min(copies, PREVIEW_LIMIT)

	-- Optimization: Check if we can reuse existing preview elements
	-- We reuse if the count is the same and the element types haven't changed
	local reuseElements = false
	if #AMT.previewElements == previewCopies and type1 == dupState.type1 and type2 == dupState.type2 then
		reuseElements = true
	else
		-- If we can't reuse, clear everything first
		clearDuplicatorPreview()
	end

	-- Update tracking types
	dupState.type1 = type1
	dupState.type2 = type2

	-- Generate or update preview elements
	for i = 1, previewCopies do
		local model
		if i % 2 == 0 then
			model = model1
		else
			model = model2
		end

		local newPosX = px2 + posDiffX * i
		local newPosY = py2 + posDiffY * i
		local newPosZ = pz2 + posDiffZ * i
		local newRotX = rx2 + rotDiffX * i
		local newRotY = ry2 + rotDiffY * i
		local newRotZ = rz2 + rotDiffZ * i

		if reuseElements then
			-- Update existing element
			local previewElement = AMT.previewElements[i]
			if isElement(previewElement) then
				setElementPosition(previewElement, newPosX, newPosY, newPosZ)
				setElementRotation(previewElement, newRotX, newRotY, newRotZ)
				setElementModel(previewElement, model)
			end
		else
			-- Create new preview element based on type
			local previewElement
			-- Determine type for this specific copy (alternating)
			local currentType = (i % 2 == 0) and type1 or type2
			
			if currentType == "object" then
				previewElement = createObject(model, newPosX, newPosY, newPosZ, newRotX, newRotY, newRotZ)
			elseif currentType == "vehicle" then
				previewElement = createVehicle(model, newPosX, newPosY, newPosZ, newRotX, newRotY, newRotZ)
			elseif currentType == "ped" then
				previewElement = createPed(0, newPosX, newPosY, newPosZ)  -- Peds use skin ID, not model
				if previewElement then
					setElementModel(previewElement, model)
					setElementRotation(previewElement, newRotX, newRotY, newRotZ)
				end
			end

			if previewElement then
				setElementDimension(previewElement, getElementDimension(getLocalPlayer()))
				setElementAlpha(previewElement, PREVIEW_ALPHA)  -- Transparent preview
				setElementCollisionsEnabled(previewElement, false)  -- No collision for preview
				
				-- For vehicles, freeze them so they don't fall
				if currentType == "vehicle" then
					setElementFrozen(previewElement, true)
				end
				
				AMT.previewElements[#AMT.previewElements + 1] = previewElement
			end
		end
	end

	-- Show warning if preview is limited
	if AMT.gui.dup_button and isElement(AMT.gui.dup_button) then
		if copies > PREVIEW_LIMIT then
			-- Update button to show warning
			guiSetProperty(AMT.gui.dup_button, "NormalTextColour", "FFFF0000")
			guiSetText(AMT.gui.dup_button, "Duplicate (" .. copies .. " copies)")
		else
			-- Reset button to normal
			guiSetProperty(AMT.gui.dup_button, "NormalTextColour", "FFFFFFFF")
			guiSetText(AMT.gui.dup_button, "Duplicate")
		end
	end
end

-- Monitor for changes that should trigger preview update
local wasDupVisible = false
addEventHandler("onClientRender", root, function()
	-- Guard: Check if GUI is initialized
	if not AMT.gui[2] or not isElement(AMT.gui[2].window) then
		return
	end
	
	-- Handle visibility changes first
	local isVisible = guiGetVisible(AMT.gui[2].window) and AMT.currentWindow == 2
	
	if isVisible ~= wasDupVisible then
		if isVisible then
			-- Window just opened - reset tracking state and trigger preview
			resetDuplicatorTrackingState()
			updateDuplicatorPreview()
		else
			-- Window just closed - clear preview and reset tracking
			clearDuplicatorPreview()
			resetDuplicatorTrackingState()
		end
		wasDupVisible = isVisible
		return -- Exit early after visibility change
	end

	-- Only process element changes when visible
	if not isVisible then return end

	-- Guard: Check if dup_amount exists
	if not AMT.gui.dup_amount or not isElement(AMT.gui.dup_amount) then
		return
	end

	local needsUpdate = false

	-- Check if elements changed
	if AMT.duplicateElement[1] ~= dupState.element1 then
		dupState.element1 = AMT.duplicateElement[1]
		needsUpdate = true
	end
	if AMT.duplicateElement[2] ~= dupState.element2 then
		dupState.element2 = AMT.duplicateElement[2]
		needsUpdate = true
	end

	-- Check if amount changed
	local currentAmount = guiGetText(AMT.gui.dup_amount)
	if currentAmount ~= dupState.amount then
		dupState.amount = currentAmount
		needsUpdate = true
	end

	-- Check if element positions/rotations changed (for real-time preview)
	if isElement(AMT.duplicateElement[1]) then
		local x, y, z = getElementPosition(AMT.duplicateElement[1])
		local rx, ry, rz = getElementRotation(AMT.duplicateElement[1])
		local newPos = {x = x, y = y, z = z}
		local newRot = {x = rx, y = ry, z = rz}
		
		if positionChanged(dupState.element1Pos, newPos) or rotationChanged(dupState.element1Rot, newRot) then
			dupState.element1Pos = newPos
			dupState.element1Rot = newRot
			needsUpdate = true
		end
	end

	if isElement(AMT.duplicateElement[2]) then
		local x, y, z = getElementPosition(AMT.duplicateElement[2])
		local rx, ry, rz = getElementRotation(AMT.duplicateElement[2])
		local newPos = {x = x, y = y, z = z}
		local newRot = {x = rx, y = ry, z = rz}
		
		if positionChanged(dupState.element2Pos, newPos) or rotationChanged(dupState.element2Rot, newRot) then
			dupState.element2Pos = newPos
			dupState.element2Rot = newRot
			needsUpdate = true
		end
	end

	if needsUpdate then
		updateDuplicatorPreview()
	end
end)
