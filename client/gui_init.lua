-- client/gui_init.lua
-- GUI initialization: window creation, UI elements setup, font loading, initial variables
-- Extracted from amt_gui.lua lines 1-374

-- NOTE: Globals are now namespaced under AMT table defined in shared/constants.lua
-- GUIBuilder is loaded globally from gui_helpers.lua (see meta.xml)

screen_width, screen_height = guiGetScreenSize()
-- PI, FOV, MIN_RADIUS, PREVIEW_LIMIT, PREVIEW_THRESHOLD are in shared/constants.lua

AMT.generate = true -- handle generate/save button
AMT.currentWindow = 1
AMT.selectingElement = nil
AMT.rotationDisabled = false
AMT.showAllPreview = false
AMT.totalPreviewCount = 0

addEventHandler("onClientResourceStart", getResourceRootElement(getThisResource()),
function()
	outputChatBox("#3c00ffArezu's Mapping Toolbox #FFFFFF- Press F7 to toggle", 255, 25, 25, true)
	outputChatBox("Type /des to undo, n to start recording/playing, and m to stop.", 255, 255, 255, true)
	AMT.gui.font = guiCreateFont("font/Arialic Hollow.ttf", 10)

	AMT.gui[1] = {}
	AMT.gui[1].window_width = 500
	AMT.gui[1].window_height = AMT.gui[1].window_width * 0.5625
	AMT.gui[1].window_x = screen_width - AMT.gui[1].window_width
	AMT.gui[1].window_y = screen_height - AMT.gui[1].window_height
	AMT.gui[1].window_title = "Arezu's Mapping Toolbox"
	AMT.gui[1].window = guiCreateWindow(AMT.gui[1].window_x, AMT.gui[1].window_y, AMT.gui[1].window_width, AMT.gui[1].window_height, AMT.gui[1].window_title, false)
	guiWindowSetMovable(AMT.gui[1].window, false)
	guiWindowSetSizable(AMT.gui[1].window, false)

	-- Global Tooltip Label (Hidden by default)
	AMT.gui.tooltip_label = guiCreateLabel(0, 0, 250, 60, "", false, AMT.gui[1].window)
	guiSetVisible(AMT.gui.tooltip_label, false)
	guiSetProperty(AMT.gui.tooltip_label, "AlwaysOnTop", "True")
	guiLabelSetColor(AMT.gui.tooltip_label, 255, 255, 0) -- Yellow text for visibility
	guiSetFont(AMT.gui.tooltip_label, "default-bold-small")
	guiLabelSetHorizontalAlign(AMT.gui.tooltip_label, "right", true) -- Right align, word wrap

	AMT.gui[2] = {}
	AMT.gui[2].window_width = 500
	AMT.gui[2].window_height = AMT.gui[2].window_width * 0.5625
	AMT.gui[2].window_x = screen_width - AMT.gui[2].window_width
	AMT.gui[2].window_y = screen_height - AMT.gui[2].window_height
	AMT.gui[2].window_title = "Arezu's Mapping Toolbox"
	AMT.gui[2].window = guiCreateWindow(AMT.gui[2].window_x, AMT.gui[2].window_y, AMT.gui[2].window_width, AMT.gui[2].window_height, AMT.gui[2].window_title, false)
	guiWindowSetMovable(AMT.gui[2].window, false)
	guiWindowSetSizable(AMT.gui[2].window, false)

	AMT.gui.generate_background = guiCreateStaticImage(0, 0, AMT.gui[1].window_width, AMT.gui[1].window_height, "img/generator_background.png", false, AMT.gui[1].window)
	AMT.gui.tab_padding = 0
	AMT.gui.tab_panel = guiCreateTabPanel(AMT.gui.tab_padding, AMT.gui.tab_padding, AMT.gui[1].window_width - AMT.gui.tab_padding*2, AMT.gui[1].window_height - AMT.gui.tab_padding*2, false, AMT.gui[1].window)
	guiSetEnabled(AMT.gui.generate_background, false)
	guiSetEnabled(AMT.gui.tab_panel, false)

	AMT.gui[1].title = guiCreateLabel(0, 0, 100, 50, "Generator", false, AMT.gui[1].window)
	local textExtent = guiLabelGetTextExtent(AMT.gui[1].title)
	guiSetPosition(AMT.gui[1].title, AMT.gui[1].window_width/2 - textExtent/2, 25, false)
	guiSetEnabled(AMT.gui[1].title, false)
	guiBringToFront(AMT.gui[1].title)
	guiSetFont(AMT.gui[1].title, "default-bold-small")

	AMT.gui[2].title = guiCreateLabel(0, 0, 100, 50, "Duplicator", false, AMT.gui[2].window)
	local textExtent = guiLabelGetTextExtent(AMT.gui[2].title)
	guiSetPosition(AMT.gui[2].title, AMT.gui[2].window_width/2 - textExtent/2, 25, false)
	guiSetEnabled(AMT.gui[2].title, false)
	guiBringToFront(AMT.gui[2].title)
	guiSetFont(AMT.gui[2].title, "default-bold-small")

	AMT.gui.loops_label_title = "Loops:"
	AMT.gui.loops_label_width = 40
	AMT.gui.loops_label_height = 20
	AMT.gui.loops_label_x = 25
	AMT.gui.loops_label_y = 50
	AMT.gui.loops_label = guiCreateLabel(AMT.gui.loops_label_x, AMT.gui.loops_label_y, AMT.gui.loops_label_width, AMT.gui.loops_label_height, AMT.gui.loops_label_title, false, AMT.gui[1].window)
	guiSetEnabled(AMT.gui.loops_label, false)
	AMT.gui.loops_field_width = 50
	AMT.gui.loops_field_height = 20
	AMT.gui.loops_field_x = AMT.gui.loops_label_x + AMT.gui.loops_label_width
	AMT.gui.loops_field_y = AMT.gui.loops_label_y
	AMT.gui.loops_field = guiCreateEdit(AMT.gui.loops_field_x, AMT.gui.loops_field_y, AMT.gui.loops_field_width, AMT.gui.loops_field_height, "1", false, AMT.gui[1].window)
	guiSetProperty(AMT.gui.loops_field, "ValidationString", "^[0-9%.%-]*$")

	AMT.gui.radius_label_title = "Radius:"
	AMT.gui.radius_label_width = 40
	AMT.gui.radius_label_height = 20
	AMT.gui.radius_label_x = AMT.gui.loops_field_x + AMT.gui.loops_field_width + 15
	AMT.gui.radius_label_y = AMT.gui.loops_label_y
	AMT.gui.radius_label = guiCreateLabel(AMT.gui.radius_label_x, AMT.gui.radius_label_y, AMT.gui.radius_label_width, AMT.gui.radius_label_height, AMT.gui.radius_label_title, false, AMT.gui[1].window)
	guiSetEnabled(AMT.gui.radius_label, false)
	AMT.gui.radius_field_width = 60
	AMT.gui.radius_field_height = 20
	AMT.gui.radius_field_x = AMT.gui.radius_label_x + AMT.gui.radius_label_width
	AMT.gui.radius_field_y = AMT.gui.radius_label_y
	AMT.gui.radius_field = guiCreateEdit(AMT.gui.radius_field_x, AMT.gui.radius_field_y, AMT.gui.radius_field_width, AMT.gui.radius_field_height, "50", false, AMT.gui[1].window)
	guiSetProperty(AMT.gui.radius_field, "ValidationString", "^[0-9%.%-]*$")

	AMT.gui.objects_label_title = "Objects:"
	AMT.gui.objects_label_width = 50
	AMT.gui.objects_label_height = 20
	AMT.gui.objects_label_x = AMT.gui.loops_label_x
	AMT.gui.objects_label_y = AMT.gui.loops_label_y + AMT.gui.loops_label_height + 15
	AMT.gui.objects_label = guiCreateLabel(AMT.gui.objects_label_x, AMT.gui.objects_label_y, AMT.gui.objects_label_width, AMT.gui.objects_label_height, AMT.gui.objects_label_title, false, AMT.gui[1].window)
	guiSetEnabled(AMT.gui.objects_label, false)
	AMT.gui.objects_field_width = 60
	AMT.gui.objects_field_height = 20
	AMT.gui.objects_field_x = AMT.gui.objects_label_x + AMT.gui.objects_label_width
	AMT.gui.objects_field_y = AMT.gui.objects_label_y
	AMT.gui.objects_field = guiCreateEdit(AMT.gui.objects_field_x, AMT.gui.objects_field_y, AMT.gui.objects_field_width, AMT.gui.objects_field_height, "50", false, AMT.gui[1].window)
	guiSetProperty(AMT.gui.objects_field, "ValidationString", "^[0-9%.%-]*$")
	guiSetEnabled(AMT.gui.objects_field, false)
	AMT.gui.objects_times_label = guiCreateLabel(AMT.gui.objects_field_x + AMT.gui.objects_field_width + 5, AMT.gui.objects_field_y, 50, 25, "x", false, AMT.gui[1].window)
	guiSetEnabled(AMT.gui.objects_times_label, false)
	AMT.gui.objects_times_field = guiCreateEdit(AMT.gui.objects_field_x + AMT.gui.objects_field_width + 15, AMT.gui.objects_field_y, AMT.gui.objects_field_width, AMT.gui.objects_field_height, "1", false, AMT.gui[1].window)
	guiSetProperty(AMT.gui.objects_times_field, "ValidationString", "^[0-9%.%-]*$")

	AMT.gui.objects_auto_title = "Autocount objects"
	AMT.gui.objects_auto_width = 130
	AMT.gui.objects_auto_height = 20
	AMT.gui.objects_auto_x = AMT.gui.loops_label_x
	AMT.gui.objects_auto_y = AMT.gui.objects_label_y + AMT.gui.objects_label_height + 5
	AMT.gui.objects_auto_box = guiCreateCheckBox(AMT.gui.objects_auto_x, AMT.gui.objects_auto_y, AMT.gui.objects_auto_width, AMT.gui.objects_auto_height, AMT.gui.objects_auto_title, true, false, AMT.gui[1].window)

	AMT.gui.offset_label_title = "Offset:"
	AMT.gui.offset_label_width = 50
	AMT.gui.offset_label_height = 20
	AMT.gui.offset_label_x = AMT.gui.loops_label_x
	AMT.gui.offset_label_y = AMT.gui.objects_auto_y + AMT.gui.objects_auto_height + 5
	AMT.gui.offset_label = guiCreateLabel(AMT.gui.offset_label_x, AMT.gui.offset_label_y, AMT.gui.offset_label_width, AMT.gui.offset_label_height, AMT.gui.offset_label_title, false, AMT.gui[1].window)
	guiSetEnabled(AMT.gui.offset_label, false)
	AMT.gui.offset_field_width = 60
	AMT.gui.offset_field_height = 20
	AMT.gui.offset_field_x = AMT.gui.offset_label_x + AMT.gui.offset_label_width
	AMT.gui.offset_field_y = AMT.gui.offset_label_y
	AMT.gui.offset_field = guiCreateEdit(AMT.gui.offset_field_x, AMT.gui.offset_field_y, AMT.gui.offset_field_width, AMT.gui.offset_field_height, "100", false, AMT.gui[1].window)
	guiSetProperty(AMT.gui.offset_field, "ValidationString", "^[0-9%.%-]*$")

	-- Rotation groups using helper functions (replaces 65 lines!)
	-- Twist rotation (Always visible)
	AMT.gui.twist_group = GUIBuilder.createRotationGroup(AMT.gui[1].window, 270, 50, "Curve rotation:", "twist", onTwistChanged)
	for _, axis in ipairs({"X", "Y", "Z"}) do
		guiSetEnabled(AMT.gui.twist_group[axis.."_field"], true)
		guiSetEnabled(AMT.gui.twist_group[axis.."_label"], true)
	end

	-- Additional rotation (Always visible)
	AMT.gui.additional_group = GUIBuilder.createRotationGroup(AMT.gui[1].window, 270, 110, "Additional rotation:", "additional", alterGeneration)
	for _, elem in pairs(AMT.gui.additional_group) do 
		guiSetEnabled(elem, true) 
	end

	-- Continuous rotation (Always visible)
	AMT.gui.conrot_group = GUIBuilder.createRotationGroup(AMT.gui[1].window, 270, 170, "Continuous rotation:", "conrot", alterGeneration)
	for _, elem in pairs(AMT.gui.conrot_group) do
		guiSetEnabled(elem, true)
	end

	-- Initialize workflow highlighting (preview mode by default)
	GUIBuilder.updateWorkflowHighlighting(true)

	-- Version watermark at bottom left
	AMT.gui.version_watermark = guiCreateLabel(15, AMT.gui[1].window_height - 20, 100, 15, "v" .. VERSION, false, AMT.gui[1].window)
	guiLabelSetColor(AMT.gui.version_watermark, 150, 150, 150) -- Subtle gray color
	guiSetAlpha(AMT.gui.version_watermark, 0.3)
	guiSetFont(AMT.gui.version_watermark, "default-small")
	guiSetEnabled(AMT.gui.version_watermark, false)

	AMT.gui.gen_width = AMT.gui[1].window_width * 0.5
	AMT.gui.gen_height = 25
	AMT.gui.gen_x = AMT.gui[1].window_width/2 - AMT.gui.gen_width/2
	AMT.gui.gen_y = AMT.gui[1].window_height - AMT.gui.gen_height - 20
	AMT.gui.gen_title_generate = "Generate!"
	AMT.gui.gen_title_save = "Save"
	AMT.gui.gen_button = guiCreateButton(AMT.gui.gen_x, AMT.gui.gen_y, AMT.gui.gen_width, AMT.gui.gen_height, AMT.gui.gen_title_generate, false, AMT.gui[1].window)
	addEventHandler("onClientGUIClick", AMT.gui.gen_button, startGenerating, false)

	-- Show all button (for when preview objects > 500)
	-- Position it on the left side, below the offset field to avoid overlapping with rotation controls
	AMT.gui.showall_width = 200
	AMT.gui.showall_height = 25
	AMT.gui.showall_x = AMT.gui.offset_label_x
	AMT.gui.showall_y = AMT.gui.offset_label_y + AMT.gui.offset_label_height + 10
	AMT.gui.showall_button = guiCreateButton(AMT.gui.showall_x, AMT.gui.showall_y, AMT.gui.showall_width, AMT.gui.showall_height, "Show all objects", false, AMT.gui[1].window)
	guiSetProperty(AMT.gui.showall_button, "NormalTextColour", "FFFF0000") -- Red text
	guiSetVisible(AMT.gui.showall_button, false) -- Initially hidden
	addEventHandler("onClientGUIClick", AMT.gui.showall_button, function()
		AMT.showAllPreview = true
		previewUpdate()
	end, false)



	local wx, wy = guiGetPosition(AMT.gui[AMT.currentWindow].window, false)
	local wWidth, wHeight = AMT.gui[AMT.currentWindow].window_width, AMT.gui[AMT.currentWindow].window_height
	AMT.gui.left_width = 20
	AMT.gui.left_height = 20
	AMT.gui.left_x = wx + wWidth/2 - 100 - AMT.gui.left_width/2
	AMT.gui.left_y = wy + 25

	AMT.gui.right_width = 20
	AMT.gui.right_height = 20
	AMT.gui.right_x = wx + wWidth/2 + 100 - AMT.gui.right_width/2
	AMT.gui.right_y = wy + 25

	addEventHandler("onClientGUIClick", getRootElement(), editFieldHandle)
	addEventHandler("onClientGUIChanged", getRootElement(), updateAutocount)
	addEventHandler("onClientGUIChanged", getRootElement(), updateAMTFields)
	bindKey("F7", "up",
	function()
		guiSetVisible(AMT.gui[AMT.currentWindow].window, not guiGetVisible(AMT.gui[AMT.currentWindow].window))
	end)

	-- Visibility Watcher: Automatically handle preview state when window opens/closes
	-- This replaces the manual handlers and fixes the bug where clicking the background destroyed previews
	local wasVisible = false
	addEventHandler("onClientRender", getRootElement(), function()
		if not AMT.gui[1] or not isElement(AMT.gui[1].window) then return end
		
		local isVisible = guiGetVisible(AMT.gui[1].window)
		
		if isVisible ~= wasVisible then
			if isVisible then
				-- Window just opened
				if AMT.currentWindow == 1 then
					-- Only show preview if editor has an element selected
					local editorElement = exports.editor_main:getSelectedElement()
					if editorElement and editorElement ~= false and getElementType(editorElement) == "object" then
						previewUpdate()
					else
						-- No element selected in editor, clear any stale selection
						clearPreviews()
					end
				end
			else
				-- Window just closed
				clearPreviews()
				clearArrowCoordinates()
			end
			wasVisible = isVisible
		end
	end)


	setWindow(1)

	local element1_width = AMT.gui[2].window_width*0.5
	local element1_height = 25
	AMT.gui.element1 = guiCreateButton(AMT.gui[2].window_width/2 - element1_width/2, 100 - element1_height/2, element1_width, element1_height, "Select 1st element", false, AMT.gui[2].window)
	addEventHandler("onClientGUIClick", AMT.gui.element1,
		function()
			guiSetText(source, "Press on element to select...")
			AMT.selectingElement = source
		end, false)

	local element2_width = AMT.gui[2].window_width*0.5
	local element2_height = 25
	AMT.gui.element2 = guiCreateButton(AMT.gui[2].window_width/2 - element2_width/2, 150 - element2_height/2, element2_width, element2_height, "Select 2nd element", false, AMT.gui[2].window)
	addEventHandler("onClientGUIClick", AMT.gui.element2,
		function()
			guiSetText(source, "Press on element to select...")
			AMT.selectingElement = source
		end, false)

	local amount_width = 75
	local amount_height = 20
	AMT.gui.dup_amount = guiCreateEdit(AMT.gui[2].window_width/2 - amount_width/2, 190, amount_width, amount_height, "5", false, AMT.gui[2].window)
	guiSetProperty(AMT.gui.dup_amount, "ValidationString", "^[0-9]*$") -- Only allow integers
	AMT.gui.dup_amount_title = guiCreateLabel(AMT.gui[2].window_width/2 - amount_width - 10, 190, 100, 25, "Copies: ", false, AMT.gui[2].window)
	guiSetEnabled(AMT.gui.dup_amount_title, false)

	AMT.gui.dup_button = guiCreateButton(AMT.gui.gen_x, AMT.gui.gen_y, AMT.gui.gen_width, AMT.gui.gen_height, "Duplicate", false, AMT.gui[2].window)
	addEventHandler("onClientGUIClick", AMT.gui.dup_button,
		function()
			local copies = tonumber(guiGetText(AMT.gui.dup_amount))
			if(isElement(AMT.duplicateElement[1]) and isElement(AMT.duplicateElement[2]) and copies)then
				-- Clear preview before triggering actual duplication
				clearDuplicatorPreview()
				triggerServerEvent("onAMTExtendedRequestDuplicate", getLocalPlayer(), AMT.duplicateElement[1], AMT.duplicateElement[2], copies)
				-- Clear element selection for fresh state
				AMT.duplicateElement[1] = nil
				AMT.duplicateElement[2] = nil
				guiSetText(AMT.gui.element1, "Select 1st element")
				guiSetText(AMT.gui.element2, "Select 2nd element")
			elseif(not copies)then
				outputChatBox("#FF2525[AMT ERROR]: #FFFFFFCopies value is not a valid number.", 255, 25, 25, true)
			else
				outputChatBox("#FF2525[AMT ERROR]: #FFFFFFYou need to select two elements first.", 255, 25, 25, true)
			end
		end, false)

	-- Direction images for choosing direction
	AMT.img.src = "img/cimg.png"
	AMT.img.nonSelectedColor = tocolor(255, 255, 255, 255)
	AMT.img.selectedCenterColor = tocolor(255, 0, 0, 255)
	AMT.img.selectedDirColor = tocolor(0, 255, 0, 255)
	AMT.img.selectedCenter = 1 -- Select top as default
	AMT.img.selectedDir = 5 -- Select forward as default
	AMT.img.rope_color = tocolor(46, 173, 232, 255) -- color of the lines to each directional image
	AMT.img.rope_width = 20
	AMT.img.dist = 50 -- default distance from object to draw
	AMT.img.diameter = 100 -- original width and height of the image


	-- Key settings, also settings for radius and images distance
	AMT.KEY.LARGER_RADIUS = "arrow_u"
	AMT.KEY.SMALLER_RADIUS = "arrow_d"
	AMT.KEY.RADIUS_CHANGE_SPEED = 1
end)
