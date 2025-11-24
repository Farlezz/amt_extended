-- shared/geometry_calculator.lua
-- Calculates position and rotation for loop/wallride generation based on center and direction
-- This eliminates ~400 lines of duplicated code across client and server files

-- Phase offset constant for loop geometry calculations
-- This 90-degree offset positions the first object at the "top" of the circular path
local LOOP_PHASE_OFFSET = 90

-- Geometry configuration lookup table
-- Each entry defines how to calculate position (nx, ny, nz) and rotation (rx, ry, rz)
-- based on center (1-6) and direction (1-6) combinations
-- NOTE: Offset is NO LONGER part of position calculation - it's applied separately in local space
local GEOMETRY_CONFIGS = {
	-- Center == Top (1)
	[1] = {
		[5] = { -- Forward
			pos = function(rot, i, radius)
				return 0, cos(rot*i - LOOP_PHASE_OFFSET)*radius, sin(rot*i - LOOP_PHASE_OFFSET)*radius + radius
			end,
			rot = function(rot, i) return rot*i, 0, 0 end,
			offsetDir = {1, 0, 0} -- Offset along +X axis
		},
		[6] = { -- Backward
			pos = function(rot, i, radius)
				return 0, -cos(rot*i - LOOP_PHASE_OFFSET)*radius, sin(rot*i - LOOP_PHASE_OFFSET)*radius + radius
			end,
			rot = function(rot, i) return -rot*i, 0, 0 end,
			offsetDir = {-1, 0, 0} -- Offset along -X axis
		},
		[3] = { -- Left
			pos = function(rot, i, radius)
				return -cos(rot*i - LOOP_PHASE_OFFSET)*radius, 0, sin(rot*i - LOOP_PHASE_OFFSET)*radius + radius
			end,
			rot = function(rot, i) return 0, rot*i, 0 end,
			offsetDir = {0, 1, 0} -- Offset along +Y axis
		},
		[4] = { -- Right
			pos = function(rot, i, radius)
				return cos(rot*i - LOOP_PHASE_OFFSET)*radius, 0, sin(rot*i - LOOP_PHASE_OFFSET)*radius + radius
			end,
			rot = function(rot, i) return 0, -rot*i, 0 end,
			offsetDir = {0, -1, 0} -- Offset along -Y axis
		}
	},

	-- Center == Down (2)
	[2] = {
		[5] = { -- Forward
			pos = function(rot, i, radius)
				return 0, cos(rot*i - LOOP_PHASE_OFFSET)*radius, -sin(rot*i - LOOP_PHASE_OFFSET)*radius - radius
			end,
			rot = function(rot, i) return -rot*i, 0, 0 end,
			offsetDir = {-1, 0, 0} -- Offset along -X axis
		},
		[6] = { -- Backward
			pos = function(rot, i, radius)
				return 0, -cos(rot*i - LOOP_PHASE_OFFSET)*radius, -sin(rot*i - LOOP_PHASE_OFFSET)*radius - radius
			end,
			rot = function(rot, i) return rot*i, 0, 0 end,
			offsetDir = {1, 0, 0} -- Offset along +X axis
		},
		[3] = { -- Left
			pos = function(rot, i, radius)
				return -cos(rot*i - LOOP_PHASE_OFFSET)*radius, 0, -sin(rot*i - LOOP_PHASE_OFFSET)*radius - radius
			end,
			rot = function(rot, i) return 0, -rot*i, 0 end,
			offsetDir = {0, -1, 0} -- Offset along -Y axis
		},
		[4] = { -- Right
			pos = function(rot, i, radius)
				return cos(rot*i - LOOP_PHASE_OFFSET)*radius, 0, -sin(rot*i - LOOP_PHASE_OFFSET)*radius - radius
			end,
			rot = function(rot, i) return 0, rot*i, 0 end,
			offsetDir = {0, 1, 0} -- Offset along +Y axis
		}
	},

	-- Center == Left (3)
	[3] = {
		[5] = { -- Forward
			pos = function(rot, i, radius)
				return -sin(rot*i - LOOP_PHASE_OFFSET)*radius - radius, cos(rot*i - LOOP_PHASE_OFFSET)*radius, 0
			end,
			rot = function(rot, i) return 0, 0, rot*i end,
			offsetDir = {0, 0, 1} -- Offset along +Z axis
		},
		[6] = { -- Backward
			pos = function(rot, i, radius)
				return -sin(rot*i - LOOP_PHASE_OFFSET)*radius - radius, -cos(rot*i - LOOP_PHASE_OFFSET)*radius, 0
			end,
			rot = function(rot, i) return 0, 0, -rot*i end,
			offsetDir = {0, 0, -1} -- Offset along -Z axis
		},
		[1] = { -- Top
			pos = function(rot, i, radius)
				return -sin(rot*i - LOOP_PHASE_OFFSET)*radius - radius, 0, cos(rot*i - LOOP_PHASE_OFFSET)*radius
			end,
			rot = function(rot, i) return 0, -rot*i, 0 end,
			offsetDir = {0, -1, 0} -- Offset along -Y axis
		},
		[2] = { -- Bottom
			pos = function(rot, i, radius)
				return -sin(rot*i - LOOP_PHASE_OFFSET)*radius - radius, 0, -cos(rot*i - LOOP_PHASE_OFFSET)*radius
			end,
			rot = function(rot, i) return 0, rot*i, 0 end,
			offsetDir = {0, 1, 0} -- Offset along +Y axis
		}
	},

	-- Center == Right (4)
	[4] = {
		[5] = { -- Forward
			pos = function(rot, i, radius)
				return sin(rot*i - LOOP_PHASE_OFFSET)*radius + radius, cos(rot*i - LOOP_PHASE_OFFSET)*radius, 0
			end,
			rot = function(rot, i) return 0, 0, -rot*i end,
			offsetDir = {0, 0, -1} -- Offset along -Z axis
		},
		[6] = { -- Backward
			pos = function(rot, i, radius)
				return sin(rot*i - LOOP_PHASE_OFFSET)*radius + radius, -cos(rot*i - LOOP_PHASE_OFFSET)*radius, 0
			end,
			rot = function(rot, i) return 0, 0, rot*i end,
			offsetDir = {0, 0, 1} -- Offset along +Z axis
		},
		[1] = { -- Top
			pos = function(rot, i, radius)
				return sin(rot*i - LOOP_PHASE_OFFSET)*radius + radius, 0, cos(rot*i - LOOP_PHASE_OFFSET)*radius
			end,
			rot = function(rot, i) return 0, rot*i, 0 end,
			offsetDir = {0, 1, 0} -- Offset along +Y axis
		},
		[2] = { -- Bottom
			pos = function(rot, i, radius)
				return sin(rot*i - LOOP_PHASE_OFFSET)*radius + radius, 0, -cos(rot*i - LOOP_PHASE_OFFSET)*radius
			end,
			rot = function(rot, i) return 0, -rot*i, 0 end,
			offsetDir = {0, -1, 0} -- Offset along -Y axis
		}
	},

	-- Center == Forward (5)
	[5] = {
		[1] = { -- Up
			pos = function(rot, i, radius)
				return 0, sin(rot*i - LOOP_PHASE_OFFSET)*radius + radius, cos(rot*i - LOOP_PHASE_OFFSET)*radius
			end,
			rot = function(rot, i) return -rot*i, 0, 0 end,
			offsetDir = {-1, 0, 0} -- Offset along -X axis
		},
		[2] = { -- Down
			pos = function(rot, i, radius)
				return 0, sin(rot*i - LOOP_PHASE_OFFSET)*radius + radius, -cos(rot*i - LOOP_PHASE_OFFSET)*radius
			end,
			rot = function(rot, i) return rot*i, 0, 0 end,
			offsetDir = {-1, 0, 0} -- Offset along -X axis
		},
		[3] = { -- Left
			pos = function(rot, i, radius)
				return -cos(rot*i - LOOP_PHASE_OFFSET)*radius, sin(rot*i - LOOP_PHASE_OFFSET)*radius + radius, 0
			end,
			rot = function(rot, i) return 0, 0, -rot*i end,
			offsetDir = {0, 0, -1} -- Offset along -Z axis
		},
		[4] = { -- Right
			pos = function(rot, i, radius)
				return cos(rot*i - LOOP_PHASE_OFFSET)*radius, sin(rot*i - LOOP_PHASE_OFFSET)*radius + radius, 0
			end,
			rot = function(rot, i) return 0, 0, rot*i end,
			offsetDir = {0, 0, 1} -- Offset along +Z axis
		}
	},

	-- Center == Backward (6)
	[6] = {
		[1] = { -- Up
			pos = function(rot, i, radius)
				return 0, -sin(rot*i - LOOP_PHASE_OFFSET)*radius - radius, cos(rot*i - LOOP_PHASE_OFFSET)*radius
			end,
			rot = function(rot, i) return rot*i, 0, 0 end,
			offsetDir = {1, 0, 0} -- Offset along +X axis
		},
		[2] = { -- Down
			pos = function(rot, i, radius)
				return 0, -sin(rot*i - LOOP_PHASE_OFFSET)*radius - radius, -cos(rot*i - LOOP_PHASE_OFFSET)*radius
			end,
			rot = function(rot, i) return -rot*i, 0, 0 end,
			offsetDir = {1, 0, 0} -- Offset along +X axis
		},
		[3] = { -- Left
			pos = function(rot, i, radius)
				return -cos(rot*i - LOOP_PHASE_OFFSET)*radius, -sin(rot*i - LOOP_PHASE_OFFSET)*radius - radius, 0
			end,
			rot = function(rot, i) return 0, 0, rot*i end,
			offsetDir = {0, 0, 1} -- Offset along +Z axis
		},
		[4] = { -- Right
			pos = function(rot, i, radius)
				return cos(rot*i - LOOP_PHASE_OFFSET)*radius, -sin(rot*i - LOOP_PHASE_OFFSET)*radius - radius, 0
			end,
			rot = function(rot, i) return 0, 0, -rot*i end,
			offsetDir = {0, 0, -1} -- Offset along -Z axis
		}
	}
}

-- Calculate position and rotation for a single element in a loop/wallride
-- @param center: Center position (1=top, 2=down, 3=left, 4=right, 5=forward, 6=backward)
-- @param dir: Direction (1=up, 2=down, 3=left, 4=right, 5=forward, 6=backward)
-- @param index: Current element index in the loop
-- @param rot: Rotation step (360/objects)
-- @param radius: Loop radius
-- @return nx, ny, nz, rx, ry, rz, offsetDirX, offsetDirY, offsetDirZ: Position, rotation, and offset direction
function calculateElementGeometry(center, dir, index, rot, radius)
	local config = GEOMETRY_CONFIGS[center]
	if not config then
		error("Invalid center value: " .. tostring(center))
	end

	local dirConfig = config[dir]
	if not dirConfig then
		error("Invalid direction value: " .. tostring(dir) .. " for center: " .. tostring(center))
	end

	local nx, ny, nz = dirConfig.pos(rot, index, radius)
	local rx, ry, rz = dirConfig.rot(rot, index)
	local offsetDir = dirConfig.offsetDir

	-- Safety check: ensure offsetDir exists
	if not offsetDir then
		error("Missing offsetDir for center: " .. tostring(center) .. ", dir: " .. tostring(dir))
	end

	return nx, ny, nz, rx, ry, rz, offsetDir[1], offsetDir[2], offsetDir[3]
end
