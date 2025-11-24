-- server/duplication.lua
-- Element duplication logic

addEvent("onClientRequestDuplicate", true)
addEventHandler("onClientRequestDuplicate", getRootElement(),
function(element1, element2, copies)
	-- Validate elements exist
	if not isElement(element1) or not isElement(element2) then
		outputChatBox("[AMT ERROR]: Invalid elements selected.", source, 255, 25, 25, true)
		return
	end

	-- Validate element types
	local type1 = getElementType(element1)
	local type2 = getElementType(element2)
	if not AMT.VALID_DUPLICATION_TYPES[type1] or not AMT.VALID_DUPLICATION_TYPES[type2] then
		outputChatBox("[AMT ERROR]: You can only duplicate Objects, Vehicles, or Peds.", source, 255, 25, 25, true)
		return
	end

	local px, py, pz = getElementPosition(element1)
	local rx, ry, rz = getElementRotation(element1)
	local px2, py2, pz2 = getElementPosition(element2)
	local rx2, ry2, rz2 = getElementRotation(element2)
	local posDiffX, posDiffY, posDiffZ = px2 - px, py2 - py, pz2 - pz
	local rotDiffX, rotDiffY, rotDiffZ = rx2 - rx, ry2 - ry, rz2 - rz
	local model1 = getElementModel(element1)
	local model2 = getElementModel(element2)
	local elementList = {}

	-- Performance optimization: Cache element counts at start for both models
	-- Duplication alternates between two models, so we need separate counts
	local elementCount1 = getElementCount(element1)
	local elementCount2 = getElementCount(element2)

	for i = 1, copies do
		local newElement = exports.edf:edfCloneElement(element1)
		local currentModel, currentCount
		if(i%2 == 0)then
			setElementModel(newElement, model1)
			elementCount1 = elementCount1 + 1
			currentModel = model1
			currentCount = elementCount1
		else
			setElementModel(newElement, model2)
			elementCount2 = elementCount2 + 1
			currentModel = model2
			currentCount = elementCount2
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
