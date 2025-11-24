-- This script records player vehicle when playing, and shows it when stopped playing
-- A vehicle recorder - Good for making maps when you dont know where to put next object after a jump

-- Recorder state
local record = {}
record.paused = false
record.recording = false
record.playing = false
record.play_alpha = 200
record.vehicle = createVehicle(411, 0, 0, 0) -- the vehicle to show when playing
setElementAlpha(record.vehicle, record.play_alpha)
record.blip = createBlipAttachedTo(record.vehicle, 55)

-- Captures frame data
local frame = {} -- values: px, py, pz, rx, ry, rz, fps, carModel
local currentFrame = 1 -- Which frame we are showing

-- if the player is playing, then this records and restarts recording, if not; then pause and unpause playing
function recordPlayPauseUnpause()
	local playing = isPlaying(getLocalPlayer())
	if(not record.recording and playing)then
		-- if not recording then...
		-- start recording
		record.recording = true
		frame = {}
		outputChatBox("You started recording.", 25, 255, 25)
	elseif(record.recording and playing)then
		-- if player pressed play when recording, then delete all frames and start from beginning
		-- (record over)
		frame = {}
		outputChatBox("You override frames. Restarting to record from frame 1.", 75, 200, 75)
	elseif(not record.recording and not playing and not record.playing and #frame > 0)then
		-- if not recording and not playing and not showing recorded playing
		-- then start playing up
		record.playing = true
		outputChatBox("You started playing.", 25, 255, 25)
		setElementFrozen(record.vehicle, false)
	elseif(not record.recording and not playing and record.playing)then
		-- if not recording and not playing and showing recorded playing
		-- then pause
		record.playing = false
		outputChatBox("You paused.", 200, 100, 100)
		setElementFrozen(record.vehicle, true)
	end
end

-- This stoppes recording when playing
function stopRecording()
	local playing = isPlaying(getLocalPlayer())
	if(record.recording and playing)then
		-- if recording and is playing
		record.recording = false
		outputChatBox("You stopped recording.", 255, 25, 25)
	elseif(not record.recording and not playing)then
		-- if not recording and not playing, then stop showing recorded playing and set frame to 1
		-- and pause
		record.playing = false
		currentFrame = 1
		setElementFrozen(record.vehicle, true)
		outputChatBox("You stopped playing.", 255, 25, 25)
	end
end

bindKey("n", "up", recordPlayPauseUnpause)
bindKey("m", "up", stopRecording)

-- Here we save frame data when recording
-- RECORDING
addEventHandler("onClientRender", getRootElement(),
function()
	if(not record.recording)then return end
	-- if player died, then stop recording
	if(not isPlaying(getLocalPlayer()))then
		record.recording = false
		outputChatBox("You stopped recording.", 255, 25, 25)
		return 
	end
	local index = #frame + 1
	frame[index] = {}
	
	local vehicle = getPedOccupiedVehicle(getLocalPlayer())
	frame[index].px, frame[index].py, frame[index].pz = getElementPosition(vehicle)
	frame[index].rx, frame[index].ry, frame[index].rz = getElementRotation(vehicle)
	-- frame[index].fps = getFPS()
	frame[index].carModel = getElementModel(vehicle)
end)

-- Show recording when not playing and record.playing is true
-- PLAYING (show saved frame data)
addEventHandler("onClientRender", getRootElement(),
function()
	-- only make blip visible if playing up
	if(record.playing)then
		setElementDimension(record.blip, getElementDimension(getLocalPlayer()))
	else
		setElementDimension(record.blip, 150)
	end
	
	-- if recording or not playing, then return end
	if(record.recording or not record.playing)then return end
	-- if player didn't press stop and started playing... then stop automatically
	if(isPlaying(getLocalPlayer()))then
		outputChatBox("You stopped playing.", 255, 25, 25)
		record.playing = false
		currentFrame = 1
		return
	end
	local cf = currentFrame
	-- if current frame is more than recorded frames(playing ended) then freeze element and stop playing
	if(cf >= #frame)then
		record.playing = false
		currentFrame = 1
		outputChatBox("Recording ended.", 255, 25, 25)
		setElementFrozen(record.vehicle, true)
		return
	end
	-- set vehicle in same dimension as player, so player can see the vehicle
	setElementDimension(record.vehicle, getElementDimension(getLocalPlayer()))
	setElementAlpha(record.vehicle, record.play_alpha)
	setElementModel(record.vehicle, frame[cf].carModel)
	setElementPosition(record.vehicle, frame[cf].px, frame[cf].py, frame[cf].pz)
	setElementRotation(record.vehicle, frame[cf].rx, frame[cf].ry, frame[cf].rz)
	currentFrame = currentFrame + 1
end)

function isPlaying(player)
	return (getPedOccupiedVehicle(player) and true) or false
end