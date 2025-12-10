-- server/generation.lua
-- Loop and wallride generation logic
-- Refactored to use shared/geometry_calculator.lua (eliminates 185 lines of duplication)

-- Dont use editor_main:import! the script will not work corretly.
local map = {}
map.xmlFile = "amt.xml"
map.current = nil

-- Here generation of elements and attaching is handled
addEvent("onRequestGenerate", true)
addEventHandler("onRequestGenerate", getRootElement(),
function(element, rotX, rotY, rotZ, loops, radius, objects, offset, center, dir, addX, addY, addZ, conX, conY, conZ, sourceRotX, sourceRotY, sourceRotZ, isCurvedLoop, originalRotX, originalRotY, originalRotZ, twistX, twistY, twistZ)
	outputDebugString("AMT: server generating elements.")

	-- Server-side safety check: Prevent excessive object counts
	local totalObjects = math.ceil(objects * loops)
	if totalObjects > MAX_SERVER_GENERATION_OBJECTS then
		outputDebugString("AMT ERROR: Object count exceeds server limit: " .. totalObjects .. " > " .. MAX_SERVER_GENERATION_OBJECTS, 1)
		outputChatBox("[AMT ERROR]: Too many objects requested (" .. totalObjects .. "). Maximum is " .. MAX_SERVER_GENERATION_OBJECTS .. ".", source, 255, 25, 25, true)
		triggerClientEvent(source, "onGenerationFailed", source)
		return
	end
	if totalObjects <= 0 then
		outputDebugString("AMT ERROR: Object count is zero after loops/objects calculation", 1)
		outputChatBox("[AMT ERROR]: Resulting object count is zero. Increase loops or objects.", source, 255, 25, 25, true)
		triggerClientEvent(source, "onGenerationFailed", source)
		return
	end

	-- Validate curved loop parameters if curved loop is enabled
	if isCurvedLoop and (not twistX or not twistY or not twistZ) then
		outputDebugString("AMT ERROR: Curved loop requested but twist parameters are missing", 1)
		outputChatBox("[AMT ERROR]: Invalid curved loop parameters.", source, 255, 25, 25, true)
		triggerClientEvent(source, "onGenerationFailed", source)
		return
	end

	local elements = {}
	local rot = 360/objects
	local off = 0
	local inter = 0
	local relOff = offset/objects
	conX = conX / totalObjects
	conY = conY / totalObjects
	conZ = conZ / totalObjects

	-- Performance optimization: Cache element count at start instead of calling getElementCount() for every object
	local elementModel = getElementModel(element)
	local elementCount = getElementCount(element)

	-- Transaction Safety: Wrap generation in pcall to catch errors and cleanup if needed
	local globalIndex = 0  -- Track total objects like preview does
	local shouldBreak = false
	local success, errorMsg = pcall(function()
		for l = 1, math.ceil(loops) do
			for i = 1, objects do
				globalIndex = globalIndex + 1
				
				-- FIX: Check BEFORE creating element (matches preview logic at line 222-224)
				if globalIndex > totalObjects then
					shouldBreak = true
					break
				end
				
				local nrx, nry, nrz = rotX, rotY, rotZ
				local index = #elements + 1
				elements[index] = {}
				off = off + relOff
	
				-- USE SHARED GEOMETRY CALCULATOR - now returns offset direction too!
				local nx, ny, nz, rx, ry, rz, offsetDirX, offsetDirY, offsetDirZ = calculateElementGeometry(center, dir, i, rot, radius)
	
				-- Apply rotation composition
				nrx, nry, nrz = rotateX(nrx, nry, nrz, rx)
				nrx, nry, nrz = rotateY(nrx, nry, nrz, ry)
				nrx, nry, nrz = rotateZ(nrx, nry, nrz, rz)
	
				-- For curved loops: apply INVERSE of the base twist to get rotation relative to original base
				if isCurvedLoop and twistX and twistY and twistZ then
					nrx, nry, nrz = applyInverseTwist(nrx, nry, nrz, twistX, twistY, twistZ)
				end
	
				-- Create and configure the new element
				local newElement = exports.edf:edfCloneElement(element)
				if not newElement then
					error("Failed to clone element")
				end

				elementCount = elementCount + 1  -- Increment cached count
				local newID = "AMT "..elementModel.." ("..elementCount..")"
				exports.edf:edfSetElementProperty(newElement, "id", newID)
				setElementID(newElement, newID)
	
				-- Store element data
				elements[index].source = element
				elements[index].element = newElement
				elements[index].posX = nx
				elements[index].posY = ny
				elements[index].posZ = nz
	
				elements[index].rotX = nrx
				elements[index].rotY = nry
				elements[index].rotZ = nrz
	
				-- Always use rotX/Y/Z for source (position transformation)
				elements[index].sourceX = rotX
				elements[index].sourceY = rotY
				elements[index].sourceZ = rotZ
	
				elements[index].source_rotX, elements[index].source_rotY, elements[index].source_rotZ = getElementRotation(element)
	
				-- Store offset information for later application in local space
				elements[index].offsetAmount = off
				elements[index].offsetDirX = offsetDirX
				elements[index].offsetDirY = offsetDirY
				elements[index].offsetDirZ = offsetDirZ

				inter = inter + 1
			end
			if shouldBreak then break end
		end
	end)

	if not success then
		outputDebugString("AMT ERROR: Generation failed: " .. tostring(errorMsg), 1)
		outputChatBox("[AMT ERROR]: Generation failed. Cleaning up...", source, 255, 25, 25, true)
		
		-- Cleanup partially created elements
		for i = 1, #elements do
			if elements[i].element and isElement(elements[i].element) then
				destroyElement(elements[i].element)
			end
		end
		triggerClientEvent(source, "onGenerationFailed", source)
		return
	end

	outputDebugString("AMT: object generated: "..inter-1)
	-- Send back the generated elements to the creator client.
	triggerClientEvent(source, "sendBackRequestedElements", source, elements, rotX + addX, rotY + addY, rotZ + addZ)
end)

-- Update position for element so its synced with editor and works
addEvent("onRequestUpdateElementPosition", true)
addEventHandler("onRequestUpdateElementPosition", getRootElement(),
function(px, py, pz)
	-- source is the element
	exports.edf:edfSetElementPosition(source, px, py, pz)
end)

-- Update rotation for element so its synced with editor and works
addEvent("onRequestUpdateElementRotation", true)
addEventHandler("onRequestUpdateElementRotation", getRootElement(),
function(rx, ry, rz)
	-- source is the element
	exports.edf:edfSetElementRotation(source, rx, ry, rz)
end)

-- Get list with elements from client to destroy
addEvent("requestDestroyElements", true)
addEventHandler("requestDestroyElements", getRootElement(),
function(elements)
	for i = 1, #elements do
		if isElement(elements[i]) then
			destroyElement(elements[i])
		end
	end
end)

addEvent("onMapOpened", true)
addEventHandler("onMapOpened", getRootElement(),
function(mapContainer, openingResource)
	-- openingResource is the map element
	map.current = ":"..getResourceName(mapContainer).."/"..map.xmlFile
	outputDebugString("AMT: xml file name saved to: "..map.current)
end)
