local Log = LibImplex_Logger('LibImplexLogger')

-- ----------------------------------------------------------------------------

local lib = {}

lib.name = 'LibImplex'
lib.displayName = 'LibImplex'
lib.version = '0.0.1'

local EVENT_NAMESPACE = 'LIBIMPLEX_EVEN_NAMESPACE'

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

	local N = 200
	local updateArray = {}
	local counter = 0

	local function updateMarkers()
		local start = GetGameTimeMilliseconds()

		for _ = 1, N do
			updateVectors()

			for _, obj in pairs(pool:GetActiveObjects()) do
				obj.m_Marker:Update()
			end
		end

		local finish = GetGameTimeMilliseconds()
		counter = counter + 1
		updateArray[counter] = (finish - start) / N

		if counter >= 100 then
			local avg, max = stats(updateArray)
			Log('Avg update time: %d us, max: %d us', avg * 1000, max * 1000)
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
