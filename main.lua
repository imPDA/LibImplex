local Log = LibImplex_Logger('LibImplexLogger')

-- ----------------------------------------------------------------------------

local lib = {}

lib.name = 'LibImplex'
lib.displayName = 'LibImplex'
lib.version = '0.0.1'

local EVENT_NAMESPACE = 'LIBIMPLEX_EVEN_NAMESPACE'

-- ----------------------------------------------------------------------------

local function average(tbl)
	local total = 0
	local length = #tbl

	for i = 1, length do
		total = total + tbl[i]
		tbl[i] = nil
	end

	return total / length
end

function lib:OnPlayerActivated(initial)
	local pool = LibImplex.Pool.GetPool()
	local updateVectors = LibImplex.Marker.Marker2D.UpdateVectors


	local updateArray = {}
	local counter = 0

	local function updateMarkers()
		local start = GetGameTimeMilliseconds()

		updateVectors()

		for _, obj in pairs(pool:GetActiveObjects()) do
			obj.m_Marker:Update()
		end

		local finish = GetGameTimeMilliseconds()
		counter = counter + 1
		updateArray[counter] = finish - start

		if counter >= 100 then
			Log('Avg update time: %d us', average(updateArray) * 1000)
			counter = 0
		end
	end

	EVENT_MANAGER:RegisterForUpdate(EVENT_NAMESPACE, 0, updateMarkers)
end

function lib:OnLoad()
	SLASH_COMMANDS['/r'] = SLASH_COMMANDS['/reloadui']

	EVENT_MANAGER:RegisterForEvent(EVENT_NAMESPACE, EVENT_PLAYER_ACTIVATED, function(_, initial) self:OnPlayerActivated(initial) end)
end

EVENT_MANAGER:RegisterForEvent(EVENT_NAMESPACE, EVENT_ADD_ON_LOADED, function(_, addonName)
	if addonName ~= lib.name then return end
	EVENT_MANAGER:UnregisterForEvent(lib.name, EVENT_ADD_ON_LOADED)

    lib:OnLoad()
end)
