-- client/gui_helpers.lua
-- GUI helper functions to reduce code duplication and improve maintainability
-- Provides reusable builders for common UI patterns

-- Make GUIBuilder global so it's accessible in all client scripts
GUIBuilder = {}

-- Highlighting constants
local HIGHLIGHT_OPACITY_ACTIVE = 1.0
local HIGHLIGHT_OPACITY_DIMMED = 0.5
local HIGHLIGHT_COLOR_CYAN = {r = 100, g = 220, b = 255}
local HIGHLIGHT_COLOR_WHITE = {r = 255, g = 255, b = 255}

-- Direction arrow to rotation axis mapping
-- Determines which curve rotation axis is most relevant based on loop direction
local DIRECTION_TO_AXIS = {
	[1] = "Z", [2] = "Z",  -- Up/Down direction → Z-axis progression
	[3] = "X", [4] = "X",  -- Left/Right direction → X-axis progression
	[5] = "Y", [6] = "Y",  -- Forward/Backward direction → Y-axis progression
}

---Creates a rotation group with rotX, rotY, rotZ fields
---@param parent element The parent GUI element
---@param x number X position
---@param y number Y position
---@param label string Section label text
---@param prefix string Prefix for AMT.gui references (e.g., "twist", "additional", "conrot")
---@param handler function|nil Optional event handler for onClientGUIChanged
---@return table group Table containing all created elements
function GUIBuilder.createRotationGroup(parent, x, y, label, prefix, handler)
	local group = {}
	
	-- Section label
	group.sectionLabel = guiCreateLabel(x + 30, y, 200, 20, label, false, parent)
	guiSetEnabled(group.sectionLabel, false)
	
	-- Create rotX, rotY, rotZ fields
	local axes = {"X", "Y", "Z"}
	for i, axis in ipairs(axes) do
		local fieldX = x + (i-1) * 70
		
		-- Axis label (rotX:, rotY:, rotZ:)
		group[axis.."_label"] = guiCreateLabel(fieldX, y+15, 50, 20, 
			"rot"..axis..":", false, parent)
		guiSetEnabled(group[axis.."_label"], false)
		
		-- Input field
		group[axis.."_field"] = guiCreateEdit(fieldX, y+30, 50, 20, 
			"0", false, parent)
		guiSetProperty(group[axis.."_field"], "ValidationString", "^[0-9%.%-]*$")
		guiSetEnabled(group[axis.."_field"], false)
		
		-- Attach event handler if provided
		if handler then
			addEventHandler("onClientGUIChanged", group[axis.."_field"], handler, false)
		end
		
		-- Store in AMT.gui for compatibility with existing code
		AMT.gui[prefix.."_rot"..axis.."_label"] = group[axis.."_label"]
		AMT.gui[prefix.."_rot"..axis.."_field"] = group[axis.."_field"]
	end
	
	return group
end

---Creates a label + edit field pair
---@param parent element The parent GUI element
---@param x number X position
---@param y number Y position
---@param label string Label text
---@param defaultValue string Default field value
---@param fieldWidth number Width of edit field
---@param options table|nil Optional configuration {labelWidth, disabled, validation}
---@return table object Table with {label, field, nextX}
function GUIBuilder.createLabeledField(parent, x, y, label, defaultValue, fieldWidth, options)
	options = options or {}
	local labelWidth = options.labelWidth or 50
	fieldWidth = fieldWidth or 60
	
	local obj = {}
	
	-- Label
	obj.label = guiCreateLabel(x, y, labelWidth, 20, label, false, parent)
	guiSetEnabled(obj.label, false)
	
	-- Edit field
	obj.field = guiCreateEdit(x + labelWidth, y, fieldWidth, 20, 
		defaultValue, false, parent)
	
	-- Apply validation pattern (default to numbers)
	local validation = options.validation or "^[0-9%.%-]*$"
	guiSetProperty(obj.field, "ValidationString", validation)
	
	-- Disable if requested
	if options.disabled then
		guiSetEnabled(obj.field, false)
	end
	
	-- Calculate next available X position
	obj.nextX = x + labelWidth + fieldWidth
	
	return obj
end

---Builds a horizontal row of elements
---@param parent element The parent GUI element
---@param y number Y position for the row
---@param elements table Array of element definitions
---@param spacing number Horizontal spacing between elements
---@return table created Array of created elements
function GUIBuilder.buildRow(parent, y, elements, spacing)
	spacing = spacing or 15
	local x = 25  -- Default start X position
	local created = {}
	
	for _, elem in ipairs(elements) do
		if elem.type == "labeled_field" then
			local obj = GUIBuilder.createLabeledField(parent, x, y, 
				elem.label, elem.default, elem.width, elem.options)
			
			-- Store reference if specified
			if elem.ref then
				AMT.gui[elem.ref] = obj.field
			end
			
			created[#created+1] = obj
			x = obj.nextX + spacing
			
		elseif elem.type == "checkbox" then
			local cb = guiCreateCheckBox(x, y, elem.width or 130, 20, 
				elem.label, elem.checked or false, false, parent)
			
			-- Store reference if specified
			if elem.ref then
				AMT.gui[elem.ref] = cb
			end
			
			created[#created+1] = {checkbox = cb}
			x = x + (elem.width or 130) + spacing
			
		elseif elem.type == "label" then
			local lbl = guiCreateLabel(x, y, elem.width or 50, 20, 
				elem.text, false, parent)
			guiSetEnabled(lbl, false)
			
			if elem.ref then
				AMT.gui[elem.ref] = lbl
			end
			
			created[#created+1] = {label = lbl}
			x = x + (elem.width or 50) + spacing
			
		elseif elem.type == "edit" then
			local field = guiCreateEdit(x, y, elem.width or 60, 20, 
				elem.default or "", false, parent)
			guiSetProperty(field, "ValidationString", "^[0-9%.%-]*$")
			
			if elem.disabled then
				guiSetEnabled(field, false)
			end
			
			if elem.ref then
				AMT.gui[elem.ref] = field
			end
			
			created[#created+1] = {field = field}
			x = x + (elem.width or 60) + spacing
		end
	end
	
	return created
end

---Highlights a rotation group section with a subtle visual effect
---@param group table The rotation group to highlight
---@param opacity number Opacity value (0.5 for dimmed, 1.0 for highlighted)
function GUIBuilder.setRotationGroupHighlight(group, opacity)
	-- Adjust opacity for all elements in the group
	for key, element in pairs(group) do
		if type(element) ~= "function" and isElement(element) then
			guiSetAlpha(element, opacity)
		end
	end
end

---Highlights a specific axis field within a rotation group
---@param group table The rotation group
---@param axis string The axis to highlight ("X", "Y", or "Z")
---@param highlight boolean True to highlight, false to remove highlight
function GUIBuilder.highlightAxis(group, axis, highlight)
	local label = group[axis.."_label"]
	if not label then return end

	local color = highlight and HIGHLIGHT_COLOR_CYAN or HIGHLIGHT_COLOR_WHITE
	guiLabelSetColor(label, color.r, color.g, color.b)
	-- Note: Input field text color stays black (default) for readability
end

---Clears all axis highlights in a rotation group
---@param group table The rotation group
function GUIBuilder.clearAxisHighlights(group)
	for _, axis in ipairs({"X", "Y", "Z"}) do
		GUIBuilder.highlightAxis(group, axis, false)
	end
end

---Updates section highlighting based on workflow state
---@param isPreviewMode boolean True if in preview mode, false if in edit mode
function GUIBuilder.updateWorkflowHighlighting(isPreviewMode)
	-- Determine opacity levels based on workflow state
	local previewOpacity = isPreviewMode and HIGHLIGHT_OPACITY_ACTIVE or HIGHLIGHT_OPACITY_DIMMED
	local editOpacity = isPreviewMode and HIGHLIGHT_OPACITY_DIMMED or HIGHLIGHT_OPACITY_ACTIVE

	-- Curve rotation: active in preview mode
	if AMT.gui.twist_group then
		GUIBuilder.setRotationGroupHighlight(AMT.gui.twist_group, previewOpacity)
	end

	-- Additional/Continuous rotation: active in edit mode (after generation)
	if AMT.gui.additional_group then
		GUIBuilder.setRotationGroupHighlight(AMT.gui.additional_group, editOpacity)
	end

	if AMT.gui.conrot_group then
		GUIBuilder.setRotationGroupHighlight(AMT.gui.conrot_group, editOpacity)
	end
end

---Updates curve rotation axis highlighting based on selected direction arrow
---@param directionArrow number The direction arrow selection (1-6)
function GUIBuilder.updateCurveAxisHighlight(directionArrow)
	if not AMT.gui.twist_group then return end

	-- Clear all highlights first
	GUIBuilder.clearAxisHighlights(AMT.gui.twist_group)

	-- Determine which axis is most relevant based on direction
	-- The direction determines the progression path, and curving along that path
	-- requires rotation around the corresponding axis
	local relevantAxis = DIRECTION_TO_AXIS[directionArrow]

	-- Highlight the relevant axis
	if relevantAxis then
		GUIBuilder.highlightAxis(AMT.gui.twist_group, relevantAxis, true)
	end
end

---Centralized function to set generate mode and update all related UI state
---This ensures highlighting is ALWAYS updated when the mode changes
---@param isGenerateMode boolean True for preview/generate mode, false for edit/save mode
function GUIBuilder.setGenerateMode(isGenerateMode)
	AMT.generate = isGenerateMode

	-- Update button text
	if AMT.gui.gen_button then
		local buttonText = isGenerateMode and AMT.gui.gen_title_generate or AMT.gui.gen_title_save
		guiSetText(AMT.gui.gen_button, buttonText)
	end

	-- Update highlighting
	GUIBuilder.updateWorkflowHighlighting(isGenerateMode)

	-- Re-enable curve rotation (twist) fields when switching back to generate mode
	-- These fields are disabled during generation and need to be unlocked on undo/save
	if isGenerateMode then
		if AMT.gui.twist_rotX_field then
			guiSetEnabled(AMT.gui.twist_rotX_field, true)
		end
		if AMT.gui.twist_rotY_field then
			guiSetEnabled(AMT.gui.twist_rotY_field, true)
		end
		if AMT.gui.twist_rotZ_field then
			guiSetEnabled(AMT.gui.twist_rotZ_field, true)
		end
	end
end

-- Return the GUIBuilder table for use in other files
return GUIBuilder
