-- client/element_selection.lua
-- Element selection UI: image rendering, click handlers, selected element tracking
-- Extracted from amt_gui.lua lines 376-399, 401-570, 572-582, 584-599, 601-645, 647-665, 667-709

-- AMT.selectedElement must be global - used by gui_generator.lua, gui_preview.lua, gui_events.lua
-- (Now in AMT namespace)

local lastPreviewPosition = nil
local lastPreviewRotation = nil

-- Track if mouse is hovering over an arrow to prevent editor selection conflict
AMT.isHoveringArrow = false

-- Mapping for arrow labels
local ARROW_LABELS = {
	[1] = "UP",
	[2] = "DOWN",
	[3] = "LEFT",
	[4] = "RIGHT",
	[5] = "FORWARD",
	[6] = "BACKWARD"
}

-- Centralized function to clear arrow screen coordinates (invalidates stale click data)
function clearArrowCoordinates()
	if AMT.selectedElement and AMT.img[AMT.selectedElement] then
		for i = 1, 6 do
			AMT.img[AMT.selectedElement][i].x = nil
			AMT.img[AMT.selectedElement][i].y = nil
		end
	end
	-- Also clear position/rotation tracking to prevent stale comparisons
	lastPreviewPosition = nil
	lastPreviewRotation = nil
	AMT.isHoveringArrow = false
end

function setWindow(window)
	local previousWindow = AMT.currentWindow
	
	for i = 1, #AMT.gui do
		if(AMT.gui[i].window ~= nil)then
			if(i == window)then
				guiSetVisible(AMT.gui[i].window, true)
			else
				guiSetVisible(AMT.gui[i].window, false)
			end
		end
	end
	AMT.currentWindow = window
	-- Clean up previews and arrows when switching windows (shared between Generator and Duplicator)
	clearPreviews()
	clearArrowCoordinates()
	
	-- Reset duplicator element selection when switching away from duplicator
	if previousWindow == 2 and window ~= 2 then
		AMT.duplicateElement[1] = nil
		AMT.duplicateElement[2] = nil
		if AMT.gui.element1 and isElement(AMT.gui.element1) then
			guiSetText(AMT.gui.element1, "Select 1st element")
		end
		if AMT.gui.element2 and isElement(AMT.gui.element2) then
			guiSetText(AMT.gui.element2, "Select 2nd element")
		end
	end
end

-- Get selected element from editor_main and only save when new element has been selected.
addEventHandler("onClientRender", getRootElement(),
function()
	if(guiGetVisible(AMT.gui[AMT.currentWindow].window))then
		local lx, ly, rx, ry = AMT.gui.left_x, AMT.gui.left_y, AMT.gui.right_x, AMT.gui.right_y
		local wColor = tocolor(255, 255, 255, 255)
		local cx, cy = 0.5, 0.5
		if(isCursorShowing())then
			cx, cy = getCursorPosition()
		end
		cx = cx * screen_width
		cy = cy * screen_height
		if(cx >= lx and cx <= lx+AMT.gui.left_width and cy >= ly and cy <= ly+AMT.gui.left_height)then
			if(getKeyState("mouse1"))then
				wColor = tocolor(255, 0, 0, 255)
			else
				wColor = tocolor(255, 75, 75, 255)
			end
		end
		dxDrawImage(lx, ly, AMT.gui.left_width, AMT.gui.left_height, "img/cimg.png", 180, 0, 0, wColor, true)
		wColor = tocolor(255, 255, 255, 255)
		if(cx >= rx and cx <= rx+AMT.gui.right_width and cy >= ry and cy <= ry+AMT.gui.right_height)then
			if(getKeyState("mouse1"))then
				wColor = tocolor(255, 0, 0, 255)
			else
				wColor = tocolor(255, 75, 75, 255)
			end
		end
		dxDrawImage(rx, ry, AMT.gui.right_width, AMT.gui.right_height, "img/cimg.png", 0, 0, 0, wColor, true)
	end
	if(not guiGetVisible(AMT.gui[AMT.currentWindow].window) or AMT.currentWindow ~= 1)then return end
	if(getKeyState(AMT.KEY.LARGER_RADIUS))then
		triggerEvent("onAMTKeyPress", getLocalPlayer(), AMT.KEY.LARGER_RADIUS)
	end
	if(getKeyState(AMT.KEY.SMALLER_RADIUS))then
		triggerEvent("onAMTKeyPress", getLocalPlayer(), AMT.KEY.SMALLER_RADIUS)
	end
	
	local element = exports.editor_main:getSelectedElement()
	
	-- BUGFIX: Prevent editor selection change if hovering over an arrow
	if AMT.isHoveringArrow and AMT.selectedElement and element ~= AMT.selectedElement then
		-- Force editor back to our element because we are interacting with UI
		exports.editor_main:selectElement(AMT.selectedElement)
	elseif(not AMT.isHoveringArrow and element ~= false and element ~= AMT.selectedElement and getElementType(element) == "object")then
		-- Safety check: Ensure element is not one of our preview elements
		local isPreview = false
		if AMT.previewElements then
			for _, pElem in pairs(AMT.previewElements) do
				if element == pElem then
					isPreview = true
					break
				end
			end
		end
		
		if isPreview then
			-- If user clicked a preview, force editor back to the original selection
			if AMT.selectedElement then
				exports.editor_main:selectElement(AMT.selectedElement)
			end
		else
			AMT.selectedElement = element
			if(not AMT.img[AMT.selectedElement])then
			AMT.img[AMT.selectedElement] = {}
			AMT.img[AMT.selectedElement].dist = 50 -- distance from object to image

			-- Check for specific object model overrides
			local model = getElementModel(AMT.selectedElement)
			local specialArrow = AMT.SPECIAL_ARROW_MODELS[model]
			if specialArrow then
				-- Use predefined arrow directions for this model
				AMT.img[AMT.selectedElement].selectedCenter = specialArrow.center
				AMT.img[AMT.selectedElement].selectedDir = specialArrow.dir
			else
				-- Standard defaults (Top/Forward)
				AMT.img[AMT.selectedElement].selectedCenter = AMT.img.selectedCenter
				AMT.img[AMT.selectedElement].selectedDir = AMT.img.selectedDir
			end

			-- Reset twist fields when selecting a new object (User Request)
			if AMT.gui.twist_rotX_field then
				guiSetText(AMT.gui.twist_rotX_field, "0")
				guiSetText(AMT.gui.twist_rotY_field, "0")
				guiSetText(AMT.gui.twist_rotZ_field, "0")
			end

			-- Update curve rotation axis highlighting based on initial direction selection
			GUIBuilder.updateCurveAxisHighlight(AMT.img[AMT.selectedElement].selectedDir)

			-- 1: UP
			-- 2: DOWN
			-- 3: LEFT
			-- 4: RIGHT
			-- 5: FORWARD
			-- 6: BACKWARD
			for i = 1, 6 do
				AMT.img[AMT.selectedElement][i] = {}
				AMT.img[AMT.selectedElement][i].diameter = AMT.img.diameter -- width and height of the image
				AMT.img[AMT.selectedElement][i].x = 0
				AMT.img[AMT.selectedElement][i].y = 0
			end

			-- Direction data
			AMT.img[AMT.selectedElement][1].dirX = 0
			AMT.img[AMT.selectedElement][1].dirY = 0
			AMT.img[AMT.selectedElement][1].dirZ = 1

			AMT.img[AMT.selectedElement][2].dirX = 0
			AMT.img[AMT.selectedElement][2].dirY = 0
			AMT.img[AMT.selectedElement][2].dirZ = -1

			AMT.img[AMT.selectedElement][3].dirX = -1
			AMT.img[AMT.selectedElement][3].dirY = 0
			AMT.img[AMT.selectedElement][3].dirZ = 0

			AMT.img[AMT.selectedElement][4].dirX = 1
			AMT.img[AMT.selectedElement][4].dirY = 0
			AMT.img[AMT.selectedElement][4].dirZ = 0

			AMT.img[AMT.selectedElement][5].dirX = 0
			AMT.img[AMT.selectedElement][5].dirY = 1
			AMT.img[AMT.selectedElement][5].dirZ = 0

			AMT.img[AMT.selectedElement][6].dirX = 0
			AMT.img[AMT.selectedElement][6].dirY = -1
			AMT.img[AMT.selectedElement][6].dirZ = 0
		end
		outputDebugString("AMT: New element selected.")
		local dist = tonumber(guiGetText(AMT.gui.radius_field)) or 50
		if(AMT.img[AMT.selectedElement] ~= nil)then
			dist = AMT.img[AMT.selectedElement].dist
		end
		--AMT.img[AMT.selectedElement].dist = tonumber(dist)
		guiSetText(AMT.gui.radius_field, tostring(dist))
		updateAutocount()
		guiSetText(AMT.gui.objects_times_field, "1")
		-- Reset position and rotation tracking for new element
		lastPreviewPosition = nil
		lastPreviewRotation = nil
		resetPreviewState()
		previewUpdate()
		end
	end
	if(AMT.selectedElement ~= nil and guiGetVisible(AMT.gui[AMT.currentWindow].window))then
		-- if the selected element gets deleted by a resource(editor is stopped, etc)
		if(not isElement(AMT.selectedElement))then
			AMT.selectedElement = nil
			return false
		end
		local camX, camY, camZ, tarX, tarY, tarZ = getCameraMatrix()
		local s = AMT.selectedElement
		
		-- Optimization: Only calculate distances if camera or element moved significantly
		-- (For now we do it every frame as it's not super expensive for 6 items, but good practice)
		for i = 1, 6 do
			local distX, distY, distZ = AMT.img[s][i].dirX, AMT.img[s][i].dirY, AMT.img[s][i].dirZ
			local x, y, z = getTransformedElementPosition(AMT.selectedElement, distX, distY, distZ)
			local dx = camX - x
			local dy = camY - y
			local dz = camZ - z
			local dist = math.sqrt(dx*dx + dy*dy + dz*dz)
			AMT.img[s][i].dist = dist
		end
		
		local posX, posY, posZ = getElementPosition(AMT.selectedElement)
		local isHoveringAny = false
		
		for i = 1, 6 do
			local index = i
			local distX, distY, distZ = AMT.img[s][index].dirX*AMT.img[s].dist, AMT.img[s][index].dirY*AMT.img[s].dist, AMT.img[s][index].dirZ*AMT.img[s].dist
			local x, y, z = getTransformedElementPosition(AMT.selectedElement, distX, distY, distZ)
			local x2, y2, z2 = getTransformedElementPosition(AMT.selectedElement, distX*1.001, distY*1.001, distZ*1.001)
			if(x ~= false and x2 ~= false)then
				dxDrawLine3D(posX, posY, posZ, x, y, z, AMT.img.rope_color, AMT.img.rope_width, false, 10.0)
				local sx, sy, sz = getScreenFromWorldPosition(x, y, z)
				local sx2, sy2, sz2 = getScreenFromWorldPosition(x2, y2, z2)
				if(sx ~= false and sx2 ~= false)then
					local rot = -math.deg(math.atan2(sx - sx2, sy - sy2)) - 90
					local color = AMT.img.nonSelectedColor
					if(i == AMT.img[s].selectedCenter)then
						color = AMT.img.selectedCenterColor
					end
					if(i == AMT.img[s].selectedDir)then
						color = AMT.img.selectedDirColor
					end
					AMT.img[s][index].x, AMT.img[s][index].y, AMT.img[s][index].diameter, AMT.img[s][index].diameter = dxDrawImage3D(x, y, z, AMT.img.diameter, AMT.img.diameter, AMT.img.src, rot, 0, 0, color, false)
					
					-- Check hover for next frame logic
					if AMT.img[s][index].x and AMT.img[s][index].y then
						local cx, cy = getCursorPosition()
						if cx then
							cx, cy = cx*screen_width, cy*screen_height
							-- Calculate distance from center of the image
							local centerX = AMT.img[s][index].x + AMT.img[s][index].diameter/2
							local centerY = AMT.img[s][index].y + AMT.img[s][index].diameter/2
							local dist = math.sqrt((cx - centerX)^2 + (cy - centerY)^2)
							
							if dist <= AMT.img[s][index].diameter/2 then
								isHoveringAny = true
								-- NEW: Draw hover label
								local labelText = ARROW_LABELS[index]
								if labelText then
									local textWidth = dxGetTextWidth(labelText, 1, "default-bold")
									local textX = centerX - textWidth/2
									local textY = centerY - AMT.img[s][index].diameter/2 - 15
									
									-- Draw text background for readability
									dxDrawRectangle(textX - 2, textY - 2, textWidth + 4, 16, tocolor(0,0,0,180))
									-- Draw label text
									dxDrawText(labelText, textX, textY, textX+textWidth, textY+15, tocolor(255,255,255,255), 1, "default-bold")
								end
							end
						end
					end
				end
			end
		end
		AMT.isHoveringArrow = isHoveringAny

		-- NEW: Check for "Save & Generate" condition
		-- If we are in "Save" mode (AMT.generate == false) and have generated elements
		if not AMT.generate and AMT.hElements and #AMT.hElements > 0 then
			local currentText = guiGetText(AMT.gui.gen_button)
			-- If the currently selected element is DIFFERENT from the one we generated off of
			if AMT.selectedElement ~= AMT.hElements[1].source then
				-- We are in "Save & Generate" mode
				if currentText ~= "Save & Generate" then
					guiSetText(AMT.gui.gen_button, "Save & Generate")
				end
			else
				-- We are still on the original element, so just "Save"
				if currentText ~= "Save" then
					guiSetText(AMT.gui.gen_button, "Save")
				end
				-- Clear any previews from other objects
				clearPreviews()
			end
		end
	end

	-- Check if selected element has moved or rotated and update preview if needed
	if(AMT.selectedElement and AMT.currentWindow == 1 and guiGetVisible(AMT.gui[AMT.currentWindow].window))then
		local currentX, currentY, currentZ = getElementPosition(AMT.selectedElement)
		local currentRotX, currentRotY, currentRotZ = getElementRotation(AMT.selectedElement)
		local needsUpdate = false

		if(lastPreviewPosition == nil)then
			lastPreviewPosition = {x = currentX, y = currentY, z = currentZ}
		elseif(lastPreviewPosition.x ~= currentX or lastPreviewPosition.y ~= currentY or lastPreviewPosition.z ~= currentZ)then
			lastPreviewPosition = {x = currentX, y = currentY, z = currentZ}
			needsUpdate = true
		end

		if(lastPreviewRotation == nil)then
			lastPreviewRotation = {x = currentRotX, y = currentRotY, z = currentRotZ}
		elseif(lastPreviewRotation.x ~= currentRotX or lastPreviewRotation.y ~= currentRotY or lastPreviewRotation.z ~= currentRotZ)then
			lastPreviewRotation = {x = currentRotX, y = currentRotY, z = currentRotZ}
			needsUpdate = true
		end

		if(needsUpdate)then
			previewUpdate()
		end
	end
end)

function dxDrawImage3D(x, y, z, width, height, src, rot, px, py, color, postGUI)
	local camX, camY, camZ, tarX, tarY, tarZ = getCameraMatrix()
	local dx, dy, dz, dist = 0
	dx = camX - x
	dy = camY - y
	dz = camZ - z
	dist = math.sqrt(dx*dx + dy*dy + dz*dz)
	x, y, z = getScreenFromWorldPosition(x, y, z)
	if(x == false)then return end
	width = width / (dist * FOV)
	height = height / (dist * FOV)
	x = x - width/2
	y = y - height/2
	dxDrawImage(x, y, width, height, src, rot, px, py, color, postGUI)
	return x, y, width, height
end

-- Helper function to check if a screen position is over any visible GUI window
-- This prevents clicking arrows that are visually hidden behind GUI elements
local function isCursorOverGUI(x, y)
	-- Check all GUI windows
	for i = 1, #AMT.gui do
		if AMT.gui[i].window and guiGetVisible(AMT.gui[i].window) then
			local wx, wy = AMT.gui[i].window_x, AMT.gui[i].window_y
			local ww, wh = AMT.gui[i].window_width, AMT.gui[i].window_height
			-- Check if cursor is within window bounds
			if x >= wx and x <= wx + ww and y >= wy and y <= wy + wh then
				return true
			end
		end
	end
	return false
end

addEventHandler("onClientClick", getRootElement(),
function(button, state, absX, absY, worldX, worldY, worldZ, element)
	if(state == "down" and button == "left" and AMT.selectingElement)then
		if(element)then
			if(AMT.selectingElement == AMT.gui.element1)then
				AMT.duplicateElement[1] = element
			elseif(AMT.selectingElement == AMT.gui.element2)then
				AMT.duplicateElement[2] = element
			end
			guiSetText(AMT.selectingElement, getElementID(element))
			AMT.selectingElement = nil
		else
			if(AMT.selectingElement == AMT.gui.element1)then
				guiSetText(AMT.selectingElement, "Select 1st element")
			elseif(AMT.selectingElement == AMT.gui.element2)then
				guiSetText(AMT.selectingElement, "Select 2nd element")
			end
			AMT.selectingElement = nil
		end
	end
	if(state == "down" and button == "left")then
		local nextWindow = AMT.currentWindow
		if(absX >= AMT.gui.left_x and absX <= AMT.gui.left_x+AMT.gui.left_width and absY >= AMT.gui.left_y and absY <= AMT.gui.left_y+AMT.gui.left_height)then
			nextWindow = nextWindow - 1
			if(nextWindow < 1)then nextWindow = #AMT.gui end
			setWindow(nextWindow)
		end
		if(absX >= AMT.gui.right_x and absX <= AMT.gui.right_x+AMT.gui.right_width and absY >= AMT.gui.right_y and absY <= AMT.gui.right_y+AMT.gui.right_height)then
			nextWindow = nextWindow + 1
			if(nextWindow > #AMT.gui)then nextWindow = 1 end
			setWindow(nextWindow)
		end
	end
	-- If element is not streamed, then dont care if player presses on image or not.
	-- Defensive check: only process clicks when window is visible and we're on generator window
	if(state ~= "up" or not AMT.selectedElement or not guiGetVisible(AMT.gui[AMT.currentWindow].window) or AMT.currentWindow ~= 1)then return end
	-- Don't process arrow clicks if cursor is over a GUI element (prevents clicking arrows hidden behind GUI)
	if(isCursorOverGUI(absX, absY))then return end
	for i = 1, 6 do
		-- Only process arrows that have valid coordinates (were successfully rendered)
		-- Skip arrows that are off-screen or behind camera without blocking others
		if(AMT.img[AMT.selectedElement][i].x ~= nil and AMT.img[AMT.selectedElement][i].y ~= nil)then
			local dx = absX - (AMT.img[AMT.selectedElement][i].x + AMT.img[AMT.selectedElement][i].diameter/2)
			local dy = absY - (AMT.img[AMT.selectedElement][i].y + AMT.img[AMT.selectedElement][i].diameter/2)
			local dist = math.sqrt(dx*dx + dy*dy)
			if(dist <= AMT.img[AMT.selectedElement][i].diameter/2)then
				triggerEvent("onClientAMTImageClick", getLocalPlayer(), i, button)
				return false
			end
		end
	end
end)

addEvent("onAMTKeyPress", true)
addEventHandler("onAMTKeyPress", getRootElement(),
function(button)
	-- AMT has selected element, but not the editor (when object has once been marked, but then deselected)
	if(exports.editor_main:getSelectedElement() == false and AMT.selectedElement ~= nil)then
		local s = AMT.selectedElement
		if(button == AMT.KEY.LARGER_RADIUS)then
			AMT.img[s].dist = AMT.img[s].dist + AMT.KEY.RADIUS_CHANGE_SPEED
		end
		if(button == AMT.KEY.SMALLER_RADIUS)then
			AMT.img[s].dist = AMT.img[s].dist - AMT.KEY.RADIUS_CHANGE_SPEED
		end
		if(AMT.img[s].dist < MIN_RADIUS)then
			AMT.img[s].dist = MIN_RADIUS
		end
		guiSetText(AMT.gui.radius_field, tostring(AMT.img[s].dist))
		updateAutocount()
	end
end)

addEvent("onClientAMTImageClick", true)
addEventHandler("onClientAMTImageClick", getRootElement(),
function(imgIndex, button)
	-- source is the player that clicked on AMTImage (always local player)
	local s = AMT.selectedElement
	if(button == "left")then
		-- When player selectes center and selected dir is not in allowed direction, then set
		-- selected direction to another
		if(imgIndex == 1 or imgIndex == 2)then
			if(AMT.img[s].selectedDir == 1 or AMT.img[s].selectedDir == 2)then
				AMT.img[s].selectedDir = 5
			end
		end
		if(imgIndex == 3 or imgIndex == 4)then
			if(AMT.img[s].selectedDir == 3 or AMT.img[s].selectedDir == 4)then
				AMT.img[s].selectedDir = 1
			end
		end
		if(imgIndex == 5 or imgIndex == 6)then
			if(AMT.img[s].selectedDir == 5 or AMT.img[s].selectedDir == 6)then
				AMT.img[s].selectedDir = 1
			end
		end
		AMT.img[s].selectedCenter = imgIndex
		outputDebugString("AMT: center point set to "..imgIndex)
		-- Update curve rotation axis highlighting based on direction (which may have been auto-adjusted)
		GUIBuilder.updateCurveAxisHighlight(AMT.img[s].selectedDir)
	end
	if(button == "middle")then
		if(AMT.img[s].selectedCenter == 1 or AMT.img[s].selectedCenter == 2)then
			if(imgIndex == 1 or imgIndex == 2)then return end
		end
		if(AMT.img[s].selectedCenter == 3 or AMT.img[s].selectedCenter == 4)then
			if(imgIndex == 3 or imgIndex == 4)then return end
		end
		if(AMT.img[s].selectedCenter == 5 or AMT.img[s].selectedCenter == 6)then
			if(imgIndex == 5 or imgIndex == 6)then return end
		end
		AMT.img[s].selectedDir = imgIndex
		outputDebugString("AMT: direction point set to "..imgIndex)
		-- Update curve rotation axis highlighting based on new direction selection
		GUIBuilder.updateCurveAxisHighlight(imgIndex)
	end
	updateAutocount()
	resetPreviewState()
	previewUpdate()
end)
