-- client/gui_preview.lua
-- Preview generation logic: previewUpdate function, preview rendering
-- Refactored to use shared/geometry_calculator.lua (eliminates 185 lines of duplication)
-- Optimized with coroutines to prevent client freeze

-- Store points for the preview path line (left and right edges)
local previewPathPoints = {}

-- Coroutine for preview generation
local previewCoroutine = nil

-- Helper function to reset preview state when parameters change
function resetPreviewState()
	AMT.showAllPreview = false
	if previewCoroutine then
		previewCoroutine = nil -- Kill existing coroutine
	end
end

-- Centralized function to clear all preview elements and path
function clearPreviews()
	for i = 1, #AMT.previewElements do
		if(isElement(AMT.previewElements[i]))then
			detachElements(AMT.previewElements[i])
			if(exports.editor_main:getSelectedElement() == AMT.previewElements[i])then
				exports.editor_main:destroySelectedElement()
			else
				destroyElement(AMT.previewElements[i])
			end
		end
	end
	AMT.previewElements = {} -- Clear the table to prevent memory leaks
	previewPathPoints = {} -- Clear path points
end

function previewUpdate()
	-- Defensive guard: only generate previews when Generator window (1) is visible
	if AMT.currentWindow ~= 1 or not guiGetVisible(AMT.gui[AMT.currentWindow].window) then return end
	
	-- Don't show preview if we're in Save mode on the SAME base object
	-- Preview should only show when in generate mode OR when selecting a DIFFERENT object during save mode
	if not AMT.generate and AMT.hElements and #AMT.hElements > 0 then
		if AMT.selectedElement == AMT.hElements[1].source then
			-- We're still on the original object, don't show preview
			return
		end
	end
	
	-- Kill any existing coroutine to restart generation
	previewCoroutine = coroutine.create(previewGeneratorCoroutine)
	local status, err = coroutine.resume(previewCoroutine)
	if not status then
		outputDebugString("AMT Preview Error (Start): " .. tostring(err), 1)
		previewCoroutine = nil
	end
end

function previewGeneratorCoroutine()
	local radius = tonumber(guiGetText(AMT.gui.radius_field))
	local offset = tonumber(guiGetText(AMT.gui.offset_field))
	local objects = tonumber(guiGetText(AMT.gui.objects_field))
	local times = tonumber(guiGetText(AMT.gui.objects_times_field))
	local loops = tonumber(guiGetText(AMT.gui.loops_field))
	local selected = AMT.selectedElement
	if not offset or not objects or not radius or not loops or not times or times <= 0 or loops <= 0 or radius <= 0 or objects <= 0 or not isElement(selected) then return end
	objects = math.floor(objects*times)

	-- Additional check after multiplication: prevent division by zero
	if objects <= 0 then
		outputDebugString("AMT Preview: Object count is zero after multiplication", 2)
		return
	end

	-- Calculate total preview count
	AMT.totalPreviewCount = math.ceil(objects*loops)

	-- Determine if we should limit the preview (Smart Sampling)
	-- Path mode creates first PREVIEW_THRESHOLD (500) + last 5 objects
	-- So only activate when total > 505 to ensure there's actually a gap
	local usePathMode = AMT.totalPreviewCount > (PREVIEW_THRESHOLD + 5)
	
	-- Visual Warning: Change text color to red if limit exceeded
	if usePathMode then
		guiSetProperty(AMT.gui.objects_label, "NormalTextColour", "FFFF0000")
		guiSetProperty(AMT.gui.objects_field, "NormalTextColour", "FFFF0000")
		guiSetProperty(AMT.gui.objects_times_field, "NormalTextColour", "FFFF0000")
		guiSetProperty(AMT.gui.gen_button, "NormalTextColour", "FFFF0000")
		
		-- Change button text only if in generate mode
		if AMT.generate then
			guiSetText(AMT.gui.gen_button, "Generate (High Count!)")
		end
	else
		-- Reset to default colors
		guiSetProperty(AMT.gui.objects_label, "NormalTextColour", "FFFFFFFF") -- White label
		guiSetProperty(AMT.gui.objects_field, "NormalTextColour", "FF000000") -- Black text for edit
		guiSetProperty(AMT.gui.objects_times_field, "NormalTextColour", "FF000000") -- Black text for edit
		guiSetProperty(AMT.gui.gen_button, "NormalTextColour", "FFFFFFFF") -- White text for button
		
		-- Reset button text only if in generate mode
		if AMT.generate then
			guiSetText(AMT.gui.gen_button, "Generate!")
		end
	end
	
	-- Hide the "Show all" button as it's deprecated by Smart Sampling
	if AMT.gui.showall_button then
		guiSetVisible(AMT.gui.showall_button, false)
	end

	local rot = 360/objects
	local off = 0
	local inter = 0
	local relOff = offset/objects
	local originalRotX, originalRotY, originalRotZ = getElementRotation(selected)
	local rotX, rotY, rotZ = originalRotX, originalRotY, originalRotZ

	-- Apply twist if curved loop is enabled
	-- Apply twist if curved loop is enabled (implicit check)
	local twistX = tonumber(guiGetText(AMT.gui.twist_rotX_field)) or 0
	local twistY = tonumber(guiGetText(AMT.gui.twist_rotY_field)) or 0
	local twistZ = tonumber(guiGetText(AMT.gui.twist_rotZ_field)) or 0
	local isCurvedLoop = (twistX ~= 0 or twistY ~= 0 or twistZ ~= 0)

	if(isCurvedLoop)then
		-- Use rotation composition functions (same as additional rotation)
		rotX, rotY, rotZ = rotateX(rotX, rotY, rotZ, twistX)
		rotX, rotY, rotZ = rotateY(rotX, rotY, rotZ, twistY)
		rotX, rotY, rotZ = rotateZ(rotX, rotY, rotZ, twistZ)
	end

	local posX, posY, posZ = getElementPosition(selected)
	local model = getElementModel(selected)
	local center, dir = AMT.img[selected].selectedCenter, AMT.img[selected].selectedDir

	-- Get object dimensions for width visualization
	local minX, minY, minZ, maxX, maxY, maxZ = getElementBoundingBox(selected)
	local halfWidth = DEFAULT_HALF_WIDTH
	if minX and maxX then
		halfWidth = (maxX - minX) / 2
		-- Ensure we have a valid width (fallback for some objects)
		if halfWidth < 0.1 then halfWidth = DEFAULT_HALF_WIDTH end
	end

	-- Clear existing preview elements using centralized function
	clearPreviews()

	-- Calculate step for path sampling to keep it under MAX_PATH_SAMPLE_POINTS
	local pathStep = 1
	if usePathMode then
		pathStep = math.max(1, math.floor(AMT.totalPreviewCount / MAX_PATH_SAMPLE_POINTS))
	end

	-- Generate preview elements
	local globalIndex = 0
	local shouldBreak = false  -- Flag for breaking both loops
	
	local startTime = getTickCount()
	
	for l = 1, math.ceil(loops) do
		for i = 1, objects do
			globalIndex = globalIndex + 1

			-- CRITICAL FIX: Increment offset BEFORE calculation (must happen every iteration)
			off = off + relOff

			-- Optimization: Skip calculation if we are in Path Mode and this index is not needed
			-- We need indices:
			-- 1. First PREVIEW_THRESHOLD (e.g. 500) objects - as requested by user
			-- 2. Last 5 (total-4 to total)
			-- 3. Sample points (globalIndex % pathStep == 0)
			local isStart = globalIndex <= PREVIEW_THRESHOLD
			local isEnd = globalIndex > (AMT.totalPreviewCount - 5)
			local isSample = (globalIndex % pathStep == 0)

			if not usePathMode or isStart or isEnd or isSample then
				local nrx, nry, nrz = rotX, rotY, rotZ

				-- USE SHARED GEOMETRY CALCULATOR - now returns offset direction too!
				local nx, ny, nz, rx, ry, rz, offsetDirX, offsetDirY, offsetDirZ = calculateElementGeometry(center, dir, i, rot, radius)

				-- Apply rotation composition
				nrx, nry, nrz = rotateX(nrx, nry, nrz, rx)
				nrx, nry, nrz = rotateY(nrx, nry, nrz, ry)
				nrx, nry, nrz = rotateZ(nrx, nry, nrz, rz)

				-- For curved loops: apply INVERSE of the base twist
				if(isCurvedLoop)then
					nrx, nry, nrz = applyInverseTwist(nrx, nry, nrz, twistX, twistY, twistZ)
				end

				-- Calculate world position
				local px, py, pz = getTransformedPosition(posX, posY, posZ, rotX, rotY, rotZ, nx, ny, nz)

				-- Apply offset in local space (NEW: fixes offset + curved loop bug)
				px, py, pz = applyOffsetInLocalSpace(px, py, pz, nrx, nry, nrz, off, offsetDirX, offsetDirY, offsetDirZ)

				-- Action 1: Add to path if sample
				if usePathMode and isSample then
					-- Calculate left and right edge positions
					-- We use the object's rotation (nrx, nry, nrz) to offset from its center (px, py, pz)
					local leftX, leftY, leftZ = getTransformedPosition(px, py, pz, nrx, nry, nrz, -halfWidth, 0, 0)
					local rightX, rightY, rightZ = getTransformedPosition(px, py, pz, nrx, nry, nrz, halfWidth, 0, 0)

					table.insert(previewPathPoints, {
						left = {leftX, leftY, leftZ},
						right = {rightX, rightY, rightZ}
					})
				end

				-- Action 2: Create Object
				-- Create if:
				-- A) Not using path mode (create all)
				-- B) Using path mode AND (isStart OR isEnd)
				if not usePathMode or (isStart or isEnd) then
					-- Check legacy preview limit just in case (though usePathMode handles the logic now)
					if inter < PREVIEW_LIMIT or usePathMode then
						local index = #AMT.previewElements+1
						
						-- FIX: Enforce strict total count to handle fractional loops correctly
						-- This prevents the loop from generating "ghost" objects for the remainder of the last loop
						if globalIndex > AMT.totalPreviewCount then
							shouldBreak = true
							break
						end
						
						AMT.previewElements[index] = createObject(model, px, py, pz, nrx, nry, nrz)
						setElementDimension(AMT.previewElements[index], getElementDimension(getLocalPlayer()))
						setElementAlpha(AMT.previewElements[index], 150)
						setElementCollisionsEnabled(AMT.previewElements[index], false) -- Prevent clicking/selection
						inter = inter + 1
					elseif not usePathMode then
						-- CRITICAL OPTIMIZATION: If not in path mode and limit reached, STOP calculating!
						shouldBreak = true
						break
					end
				end
			end
			
			-- Yield if we've spent too much time (e.g. > 5ms) to prevent freeze
			if getTickCount() - startTime > 5 then
				coroutine.yield()
				startTime = getTickCount()
			end

			-- Check if we should break both loops
			if shouldBreak then break end
		end
		-- Break outer loop if flag is set
		if shouldBreak then break end
	end
	previewCoroutine = nil -- Finished
end

-- Resume coroutine every frame if active
addEventHandler("onClientRender", root, function()
	if previewCoroutine and coroutine.status(previewCoroutine) == "suspended" then
		local status, err = coroutine.resume(previewCoroutine)
		if not status then
			outputDebugString("AMT Preview Error (Resume): " .. tostring(err), 1)
			clearPreviews()  -- Clean up any preview elements created before error
			previewCoroutine = nil
		end
	end
end)

-- Render the preview path
addEventHandler("onClientRender", root, function()
	-- Defensive guard: only render when Generator window (1) is visible and preview is active
	if AMT.currentWindow ~= 1 or not guiGetVisible(AMT.gui[AMT.currentWindow].window) then return end
	
	-- Don't render preview path if we're in Save mode on the SAME base object
	if not AMT.generate and AMT.hElements and #AMT.hElements > 0 then
		if AMT.selectedElement == AMT.hElements[1].source then
			return
		end
	end

	if #previewPathPoints > 1 then
		for i = 1, #previewPathPoints - 1 do
			local p1 = previewPathPoints[i]
			local p2 = previewPathPoints[i+1]

			-- Draw Left Line
			dxDrawLine3D(p1.left[1], p1.left[2], p1.left[3], p2.left[1], p2.left[2], p2.left[3], tocolor(255, 255, 0, 200), 2)

			-- Draw Right Line
			dxDrawLine3D(p1.right[1], p1.right[2], p1.right[3], p2.right[1], p2.right[2], p2.right[3], tocolor(255, 255, 0, 200), 2)

			-- Optional: Draw cross-lines every 5th segment to look like a track
			if i % 5 == 0 then
				dxDrawLine3D(p1.left[1], p1.left[2], p1.left[3], p1.right[1], p1.right[2], p1.right[3], tocolor(255, 255, 0, 100), 1)
			end
		end
	end
end)
