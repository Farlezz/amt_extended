-- client/gui_events.lua
-- Event handlers and commands: event listeners, /des command
-- Extracted from amt_gui.lua lines 1209-1227, 1229-1234, 1429-1449, 1451-1460

-- remove save option if element that was removed is the parent element for the generation
addEvent("onClientElementDestroyed", true)
addEventHandler("onClientElementDestroyed", getRootElement(),
function()
	if(source == AMT.selectedElement)then
		AMT.selectedElement = nil
	end
end)

addEventHandler("onClientResourceStop", getResourceRootElement(getThisResource()),
function()
	if(AMT.hElements[1] ~= nil)then
		triggerServerEvent("requestDestroyElements", getLocalPlayer(), AMT.hElements)
	end
	-- Clean up all preview elements (shared between Generator and Duplicator)
	clearPreviews()
end)

addCommandHandler("des",
function()
	local index = #AMT.elementList
	if(index == 0)then
		outputChatBox("#FF2525[AMT ERROR]: #FFFFFFNothing to undo.", 255, 25, 25, true)
		return false
	end
	if not AMT.generate then
		AMT.hElements = {}
		-- Switch back to preview/generate mode (updates button text and highlighting)
		GUIBuilder.setGenerateMode(true)
	end
	for i = 1, #AMT.elementList[index] do
		if(AMT.elementList[index][i] == AMT.selectedElement)then
			AMT.selectedElement = nil
			break
		end
	end
	triggerServerEvent("requestDestroyElements", getLocalPlayer(), AMT.elementList[index])
	table.remove(AMT.elementList, index)
end)

addEvent("sendBackDuplicatedElements", true)
addEventHandler("sendBackDuplicatedElements", getRootElement(),
function(elements)
	outputDebugString("Saving duplicated files to element list")
	local index = #AMT.elementList+1
	AMT.elementList[index] = {}
	for i = 1, #elements do
		AMT.elementList[index][#AMT.elementList[index]+1] = elements[i]
	end
end)
