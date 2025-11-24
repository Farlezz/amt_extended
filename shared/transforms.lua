-- shared/transforms.lua
-- Rotation and transformation functions used across client and server

-- XYZ euler rotation to YXZ euler rotation
function convertRotationToMTA(rx, ry, rz)
	rx, ry, rz = math.rad(rx), math.rad(ry), math.rad(rz)
	local sinX = math.sin(rx)
	local cosX = math.cos(rx)
	local sinY = math.sin(ry)
	local cosY = math.cos(ry)
	local sinZ = math.sin(rz)
	local cosZ = math.cos(rz)

	local newRx = math.asin(cosY * sinX)

	local newRy = math.atan2(sinY, cosX * cosY)

	local newRz = math.atan2(cosX * sinZ - cosZ * sinX * sinY,
		cosX * cosZ + sinX * sinY * sinZ)

	return math.deg(newRx), math.deg(newRy), math.deg(newRz)
end

-- YXZ rotation to XYZ rotation
function convertRotationFromMTA(rx, ry, rz)
	rx = math.rad(rx)
	ry = math.rad(ry)
	rz = math.rad(rz)

	local sinX = math.sin(rx)
	local cosX = math.cos(rx)
	local sinY = math.sin(ry)
	local cosY = math.cos(ry)
	local sinZ = math.sin(rz)
	local cosZ = math.cos(rz)

	return math.deg(math.atan2(sinX, cosX * cosY)), math.deg(math.asin(cosX * sinY)), math.deg(math.atan2(cosZ * sinX * sinY + cosY * sinZ,
		cosY * cosZ - sinX * sinY * sinZ))
end

-- Rotate around X axis
function rotateX(rx, ry, rz, add)
	rx, ry, rz = convertRotationFromMTA(rx, ry, rz)
	rx = rx + add
	rx, ry, rz = convertRotationToMTA(rx, ry, rz)
	return rx, ry, rz
end

-- Rotate around Y axis
function rotateY(rx, ry, rz, add)
	return rx, ry + add, rz
end

-- Rotate around Z axis
function rotateZ(rx, ry, rz, add)
	ry = ry + 90
	rx, ry, rz = convertRotationFromMTA(rx, ry, rz)
	rx = rx - add
	rx, ry, rz = convertRotationToMTA(rx, ry, rz)
	ry = ry - 90
	return rx, ry, rz
end

-- Get element transformation matrix
function getElementMatrix(element)
	local rx, ry, rz = getElementRotation(element)
	rx = math.rad(rx)
	ry = math.rad(ry)
	rz = math.rad(rz)
	local matrix = {}
	matrix[1] = {}
	matrix[1][1] = math.cos(rz)*math.cos(ry) - math.sin(rz)*math.sin(rx)*math.sin(ry)
	matrix[1][2] = math.cos(ry)*math.sin(rz) + math.cos(rz)*math.sin(rx)*math.sin(ry)
	matrix[1][3] = -math.cos(rx)*math.sin(ry)

	matrix[2] = {}
	matrix[2][1] = -math.cos(rx)*math.sin(rz)
	matrix[2][2] = math.cos(rz)*math.cos(rx)
	matrix[2][3] = math.sin(rx)

	matrix[3] = {}
	matrix[3][1] = math.cos(rz)*math.sin(ry) + math.cos(ry)*math.sin(rz)*math.sin(rx)
	matrix[3][2] = math.sin(rz)*math.sin(ry) - math.cos(rz)*math.cos(ry)*math.sin(rx)
	matrix[3][3] = math.cos(rx)*math.cos(ry)

	matrix[4] = {}
	matrix[4][1], matrix[4][2], matrix[4][3] = getElementPosition(element)

	return matrix
end

-- Get transformation matrix from position and rotation
function getMatrix(posX, posY, posZ, rotX, rotY, rotZ)
	local rx, ry, rz = rotX, rotY, rotZ
	rx = math.rad(rx)
	ry = math.rad(ry)
	rz = math.rad(rz)
	local matrix = {}
	matrix[1] = {}
	matrix[1][1] = math.cos(rz)*math.cos(ry) - math.sin(rz)*math.sin(rx)*math.sin(ry)
	matrix[1][2] = math.cos(ry)*math.sin(rz) + math.cos(rz)*math.sin(rx)*math.sin(ry)
	matrix[1][3] = -math.cos(rx)*math.sin(ry)

	matrix[2] = {}
	matrix[2][1] = -math.cos(rx)*math.sin(rz)
	matrix[2][2] = math.cos(rz)*math.cos(rx)
	matrix[2][3] = math.sin(rx)

	matrix[3] = {}
	matrix[3][1] = math.cos(rz)*math.sin(ry) + math.cos(ry)*math.sin(rz)*math.sin(rx)
	matrix[3][2] = math.sin(rz)*math.sin(ry) - math.cos(rz)*math.cos(ry)*math.sin(rx)
	matrix[3][3] = math.cos(rx)*math.cos(ry)

	matrix[4] = {}
	matrix[4][1], matrix[4][2], matrix[4][3] = posX, posY, posZ

	return matrix
end

-- Get transformed position from element and offset
function getTransformedElementPosition(element, dx, dy, dz)
	local m = getElementMatrix(element)
	if not m then return false end
	local offX = dx * m[1][1] + dy * m[2][1] + dz * m[3][1] + 1 * m[4][1]
	local offY = dx * m[1][2] + dy * m[2][2] + dz * m[3][2] + 1 * m[4][2]
	local offZ = dx * m[1][3] + dy * m[2][3] + dz * m[3][3] + 1 * m[4][3]
	return offX, offY, offZ
end

-- Get transformed position from position/rotation and offset
function getTransformedPosition(posX, posY, posZ, rotX, rotY, rotZ, dx, dy, dz)
	local m = getMatrix(posX, posY, posZ, rotX, rotY, rotZ)
	if not m then return false end
	local offX = dx * m[1][1] + dy * m[2][1] + dz * m[3][1] + 1 * m[4][1]
	local offY = dx * m[1][2] + dy * m[2][2] + dz * m[3][2] + 1 * m[4][2]
	local offZ = dx * m[1][3] + dy * m[2][3] + dz * m[3][3] + 1 * m[4][3]
	return offX, offY, offZ
end

-- Rotate a direction vector by a rotation (without translation)
-- This transforms a local direction vector into world space based on rotation
function rotateVector(rotX, rotY, rotZ, dx, dy, dz)
	local m = getMatrix(0, 0, 0, rotX, rotY, rotZ)
	if not m then return false end
	-- Only use rotation part of matrix (no translation)
	local outX = dx * m[1][1] + dy * m[2][1] + dz * m[3][1]
	local outY = dx * m[1][2] + dy * m[2][2] + dz * m[3][2]
	local outZ = dx * m[1][3] + dy * m[2][3] + dz * m[3][3]
	return outX, outY, outZ
end

-- Apply inverse twist to rotation for curved loops
-- This undoes the base twist to get rotation relative to original base
-- Must use rotation composition (not subtraction) because Euler angles don't subtract linearly
-- @param rotX, rotY, rotZ: Current rotation
-- @param twistX, twistY, twistZ: Twist amounts to invert
-- @return rotX, rotY, rotZ: Rotation with inverse twist applied
function applyInverseTwist(rotX, rotY, rotZ, twistX, twistY, twistZ)
	-- Apply inverse in reverse order: Z, Y, X (opposite of forward X, Y, Z)
	-- Only apply if twist value is non-zero to avoid unnecessary calculations
	if twistZ and twistZ ~= 0 then
		rotX, rotY, rotZ = rotateZ(rotX, rotY, rotZ, -twistZ)
	end
	if twistY and twistY ~= 0 then
		rotX, rotY, rotZ = rotateY(rotX, rotY, rotZ, -twistY)
	end
	if twistX and twistX ~= 0 then
		rotX, rotY, rotZ = rotateX(rotX, rotY, rotZ, -twistX)
	end
	return rotX, rotY, rotZ
end

-- Apply offset in local space (transforms offset direction by rotation and applies it)
-- This fixes the offset + curved loop bug by applying offset AFTER curved loop transformation
-- @param posX, posY, posZ: Base world position
-- @param rotX, rotY, rotZ: Object rotation
-- @param offsetAmount: How far to offset
-- @param offsetDirX, offsetDirY, offsetDirZ: Local offset direction vector
-- @return newPosX, newPosY, newPosZ: Position with offset applied, or original position if offset is invalid
function applyOffsetInLocalSpace(posX, posY, posZ, rotX, rotY, rotZ, offsetAmount, offsetDirX, offsetDirY, offsetDirZ)
	-- Validate inputs
	if not offsetAmount or offsetAmount == 0 then
		return posX, posY, posZ
	end
	if not offsetDirX or not offsetDirY or not offsetDirZ then
		return posX, posY, posZ
	end

	-- Transform offset direction vector to world space using object's rotation
	local offsetWorldX, offsetWorldY, offsetWorldZ = rotateVector(rotX, rotY, rotZ, offsetDirX, offsetDirY, offsetDirZ)

	-- Only apply if rotation succeeded
	if not offsetWorldX then
		return posX, posY, posZ
	end

	-- Apply offset in the transformed direction
	return posX + offsetWorldX * offsetAmount,
	       posY + offsetWorldY * offsetAmount,
	       posZ + offsetWorldZ * offsetAmount
end

-- Get rotation from element matrix
function getTransformedRotation(element)
	local matrix = getElementMatrix(element)
	if not matrix then return false end
	local rotX = math.deg(math.asin(matrix[2][3]))
	local rotY = math.deg(math.atan2(-matrix[1][3], matrix[3][3]))
	local rotZ = math.deg(math.atan2(-matrix[2][1], matrix[2][2]))
	return rotX, rotY, rotZ
end
