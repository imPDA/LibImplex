local Log = LibImplex_Logger()
local TEST_ENVIRONMENT = false

-- ----------------------------------------------------------------------------

local lib = {}

lib.name = 'LibImplex'
lib.displayName = 'LibImplex'
lib.version = '0.0.3'

local EVENT_NAMESPACE = 'LIBIMPLEX_EVEN_NAMESPACE'
local EVENT_BEFORE_UPDATE = 1
local EVENT_AFTER_UPDATE = 2

local EVENT_NAMES = {
	[EVENT_BEFORE_UPDATE] = 'EVENT_BEFORE_UPDATE',
	[EVENT_AFTER_UPDATE] = 'EVENT_AFTER_UPDATE',
}

lib.callbacks = {
	[EVENT_BEFORE_UPDATE] = {},
	[EVENT_AFTER_UPDATE] = {},
}

-- ----------------------------------------------------------------------------

local function stats(tbl)
	local total = 0
	local max = 0
	local length = #tbl

	for i = 1, length do
		if tbl[i] > max then
			max = tbl[i]
		end
		total = total + tbl[i]
		tbl[i] = nil
	end

	return total / length, max
end

function lib:OnPlayerActivated(initial)
	local pool = LibImplex.Pool.GetPool()
	local updateVectors = LibImplex.Marker.Marker2D.UpdateVectors

	local N = 10
	local updateArray = {}
	local counter = 0

	local function updateMarkersTest()
		local start = GetGameTimeMilliseconds()

		for _ = 1, N do
			self:FireCallbacks(EVENT_BEFORE_UPDATE)
			updateVectors()

			for _, obj in pairs(pool:GetActiveObjects()) do
				obj.m_Marker:Update()
			end

			self:FireCallbacks(EVENT_AFTER_UPDATE)
		end

		local finish = GetGameTimeMilliseconds()
		counter = counter + 1
		updateArray[counter] = (finish - start) / N

		if counter >= 100 then
			local avg, max = stats(updateArray)
			Log('Updating %d markers, avg update time: %d us, max: %d us', pool:GetActiveObjectCount(), avg * 1000, max * 1000)
			counter = 0
		end
	end

	local function updateMarkersRegular()
		self:FireCallbacks(EVENT_BEFORE_UPDATE)
		updateVectors()

		for _, obj in pairs(pool:GetActiveObjects()) do
			obj.m_Marker:Update()
		end

		self:FireCallbacks(EVENT_AFTER_UPDATE)
	end

	local updateMarkers = TEST_ENVIRONMENT and updateMarkersTest or updateMarkersRegular

	EVENT_MANAGER:RegisterForUpdate(EVENT_NAMESPACE, 0, updateMarkers)
end

function lib:RegisterForEvent(namespace, event, callback)
	if self.callbacks[event][namespace] then
		error(('Event %s for %s already registered'):format(EVENT_NAMES[event], namespace))
	end

	self.callbacks[event][namespace] = callback
end

function lib:UnregisterForEvent(namespace, event)
	self.callbacks[event][namespace] = nil
end

function lib:FireCallbacks(event)
	for _, callback in pairs(self.callbacks[event]) do
		callback()  -- TODO: pcall
	end
end

function lib:OnLoad()
	if TEST_ENVIRONMENT then
		SLASH_COMMANDS['/r'] = SLASH_COMMANDS['/reloadui']
		LibImplex_ShowDebugWindow()
	end

	EVENT_MANAGER:RegisterForEvent(EVENT_NAMESPACE, EVENT_PLAYER_ACTIVATED, function(_, initial) self:OnPlayerActivated(initial) end)
end

EVENT_MANAGER:RegisterForEvent(EVENT_NAMESPACE, EVENT_ADD_ON_LOADED, function(_, addonName)
	if addonName ~= lib.name then return end
	EVENT_MANAGER:UnregisterForEvent(lib.name, EVENT_ADD_ON_LOADED)

    lib:OnLoad()
end)

LibImplex = LibImplex or {}

LibImplex.EVENT_MANAGER = {
	RegisterForEvent = function(...) lib:RegisterForEvent(...) end,
	UnregisterForEvent = function(...) lib:UnregisterForEvent(...) end,
	EVENT_BEFORE_UPDATE = EVENT_BEFORE_UPDATE,
	EVENT_AFTER_UPDATE = EVENT_AFTER_UPDATE,
}
