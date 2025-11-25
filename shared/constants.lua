-- shared/constants.lua
-- Global constants used across the application

VERSION = "1.1.0"  -- Keep in sync with meta.xml <info> tag
PI = math.pi
FOV = 0.01  -- Size of image relative to 3d distance
MIN_RADIUS = 1  -- Minimal allowed radius to generate with
PREVIEW_LIMIT = 500  -- Maximum number of preview elements
PREVIEW_THRESHOLD = 500  -- Threshold for showing preview warning
DEFAULT_HALF_WIDTH = 2  -- Fallback half-width for objects when bounding box is too small
MAX_PATH_SAMPLE_POINTS = 1000  -- Maximum number of sample points for path visualization
MAX_SERVER_GENERATION_OBJECTS = 10000  -- Server-side limit for total objects generated in one request

AMT = {}
AMT.gui = {}
AMT.img = {}
AMT.KEY = {}
AMT.hElements = {}
AMT.elementList = {}
AMT.duplicateElement = {}
AMT.previewElements = {}  -- Shared preview elements (used by both Generator and Duplicator)
AMT.originalBaseRotation = {x = 0, y = 0, z = 0}
AMT.VALID_DUPLICATION_TYPES = {
	["object"] = true,
	["vehicle"] = true,
	["ped"] = true
}

-- Models with special default arrow directions
-- center = Red arrow (selectedCenter), dir = Green arrow (selectedDir)
AMT.SPECIAL_ARROW_MODELS = {
	[7657] = { center = 6, dir = 1 },  -- Backward, Up
	[982]  = { center = 6, dir = 1 }   -- Backward, Up
}

