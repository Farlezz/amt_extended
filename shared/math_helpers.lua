-- shared/math_helpers.lua
-- Mathematical helper functions used across client and server

-- Convert degrees to radians and calculate cosine
function cos(deg)
	return math.cos(math.rad(deg))
end

-- Convert degrees to radians and calculate sine
function sin(deg)
	return math.sin(math.rad(deg))
end

-- Calculate atan2 and convert to degrees
function atan2(offX, offY)
	return math.deg(math.atan2(offX, offY))
end

-- Get count of elements with same model
function getElementCount(element)
	local model = getElementModel(element)
	local count = 0
	local elements = getElementsByType(getElementType(element))
	for i = 1, #elements do
		local tModel = getElementModel(elements[i])
		if(tModel == model)then
			count = count + 1
		end
	end
	return count
end
