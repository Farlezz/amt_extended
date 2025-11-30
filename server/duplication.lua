-- server/duplication.lua
-- Element duplication logic

addEvent("onAMTExtendedRequestDuplicate", true)
addEventHandler("onAMTExtendedRequestDuplicate", getRootElement(),
function(elementData, copies)
	-- Validate element data
	if not elementData or type(elementData) ~= "table" then
		outputChatBox("[AMT ERROR]: Invalid element data.", source, 255, 25, 25, true)
		return
	end

	local element1 = elementData.element1
	local element2 = elementData.element2

	-- Validate elements exist
	if not isElement(element1) or not isElement(element2) then
		outputChatBox("[AMT ERROR]: Invalid elements selected.", source, 255, 25, 25, true)
		return
	end

	-- Validate copies count (prevent server crashes from excessive requests)
	if not copies or copies <= 0 then
		outputChatBox("[AMT ERROR]: Invalid copy count.", source, 255, 25, 25, true)
		return
	end
	if copies > MAX_SERVER_GENERATION_OBJECTS then
		outputDebugString("AMT ERROR: Duplication count exceeds server limit: " .. copies .. " > " .. MAX_SERVER_GENERATION_OBJECTS, 1)
		outputChatBox("[AMT ERROR]: Too many copies requested (" .. copies .. "). Maximum is " .. MAX_SERVER_GENERATION_OBJECTS .. ".", source, 255, 25, 25, true)
		return
	end

	-- Validate element types
	local type1 = getElementType(element1)
	local type2 = getElementType(element2)
	if not AMT.VALID_DUPLICATION_TYPES[type1] or not AMT.VALID_DUPLICATION_TYPES[type2] then
		outputChatBox("[AMT ERROR]: You can only duplicate Objects, Vehicles, or Peds.", source, 255, 25, 25, true)
		return
	end

	-- Use client-provided positions/rotations (accounts for unsaved editor movements)
	local px, py, pz = elementData.pos1.x, elementData.pos1.y, elementData.pos1.z
	local rx, ry, rz = elementData.rot1.x, elementData.rot1.y, elementData.rot1.z
	local px2, py2, pz2 = elementData.pos2.x, elementData.pos2.y, elementData.pos2.z
	local rx2, ry2, rz2 = elementData.rot2.x, elementData.rot2.y, elementData.rot2.z
	local posDiffX, posDiffY, posDiffZ = px2 - px, py2 - py, pz2 - pz
	local rotDiffX, rotDiffY, rotDiffZ = rx2 - rx, ry2 - ry, rz2 - rz
	local model1 = elementData.model1
	local model2 = elementData.model2
	local elementList = {}

	-- Performance optimization: Cache element counts at start for both models
	-- Duplication alternates between two models, so we need separate counts
	local elementCount1 = getElementCount(element1)
	local elementCount2 = getElementCount(element2)

	for i = 1, copies do
		local useSecond = (i % 2 == 0) -- Preserve original ordering: first = element1, second = element2
		local sourceElement = useSecond and element2 or element1
		local newElement = exports.edf:edfCloneElement(sourceElement)
		if not newElement then
			outputChatBox("[AMT ERROR]: Failed to duplicate element.", source, 255, 25, 25, true)
			break
		end
		local currentModel, currentCount
		if useSecond then
			elementCount2 = elementCount2 + 1
			currentModel = model2
			currentCount = elementCount2
		else
			elementCount1 = elementCount1 + 1
			currentModel = model1
			currentCount = elementCount1
		end
		local newID = "AMT "..currentModel.." ("..currentCount..")"
		exports.edf:edfSetElementProperty(newElement, "id", newID)
		setElementID(newElement, newID)
		exports.edf:edfSetElementPosition(newElement, px2 + posDiffX*i, py2 + posDiffY*i, pz2 + posDiffZ*i)
		exports.edf:edfSetElementRotation(newElement, rx2 + rotDiffX*i, ry2 + rotDiffY*i, rz2 + rotDiffZ*i)
		elementList[#elementList+1] = newElement
	end
	triggerClientEvent(source, "sendBackDuplicatedElements", source, elementList)
end)
