-- local Log = LibImplex_Logger()

-- ----------------------------------------------------------------------------

local lib = {}

lib.name = 'LibImplex'
lib.displayName = 'LibImplex'

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

local function stats(tbl, length)
	local total = 0
	local max = 0
	length = length or #tbl

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
	local updateVectors = LibImplex.Marker.UpdateVectors
	local getUpdateableObjects = LibImplex.GetUpdateableObjects
	-- local clearCache = LibImplex.ClearCache

	local function updateMarkers()
		self:FireCallbacks(EVENT_BEFORE_UPDATE)
		-- clearCache()
		updateVectors()

		for object, _ in pairs(getUpdateableObjects()) do
			object:Update()
		end

		self:FireCallbacks(EVENT_AFTER_UPDATE)
	end

	if self.sv.debugEnabled then
		local updateArray = {}
		local counter = 0

		local function timeIt(func)
			local function inner()
				local repetitions = self.sv.repetitions
				local start = GetGameTimeMilliseconds()

				for _ = 1, repetitions do
					func()
				end

				local finish = GetGameTimeMilliseconds()
				counter = counter + 1
				updateArray[counter] = (finish - start) / repetitions
			end

			return inner
		end

		updateMarkers = timeIt(updateMarkers)

		EVENT_MANAGER:RegisterForUpdate(EVENT_NAMESPACE..'DebugWindow', 1000 * 1, function()
			local repetitions = self.sv.repetitions
			local avg, max = stats(updateArray, counter)
			local totalTime = avg * repetitions

			local stats = LibImplex.Context.GetContextStats()
			local stats_table = {}
			for context, counts in pairs(stats) do
				stats_table[#stats_table+1] = ('%s: %d / %d'):format(context, counts[1], counts[2])
			end

			LibImplex_DebugWindowText2:SetText(
				(
[[|c00EE00%dx|r repetition(s)

Objects per context (active/total):
%s

Avg: %.3f ms (max: %.3f ms)
Total: %.3f ms
Max FPS: ~%d (low: ~%d)
Current FPS: ~%d (low: ~%d)]]
				):format(
					repetitions,
					table.concat(stats_table, '\n'),
					avg,
					max,
					totalTime,
					750 / avg,
					750 / max,
					750 / totalTime,
					750 / (max * repetitions)
				)
			)
			counter = 0
		end)
	end

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

function lib:AddSettings()
	local LAM = LibAddonMenu2

	if not LAM then return end

	local panelName = self.name .. 'SettingsPanelControl'
	local panelData = {
        type = 'panel',
        name = '[DEV] '..self.displayName,
        author = '@imPDA',
    }

    local panel = LAM:RegisterAddonPanel(panelName, panelData)

    local optionsData = {
		{
			type = 'checkbox',
			name = 'Enable',
			getFunc = function() return self.sv.debugEnabled end,
			setFunc = function(value) self.sv.debugEnabled = value end,
			requiresReload = true,
		},
		{
			type = 'slider',
			name = 'Repetitions',
			getFunc = function() return self.sv.repetitions end,
			setFunc = function(value)
				self.sv.repetitions = value
			end,
			disabled = function() return not self.sv.debugEnabled end,
			min = 1,
			max = 300,
		},
		{
			type = 'checkbox',
			name = 'Show 3D Origin',
			getFunc = function() return self.sv.showOrigin end,
			setFunc = function(value)
				self.sv.showOrigin = value
				if value then
					LibImplex_ShowOrigin()
				else
					LibImplex_HideOrigin()
				end
			end,
			disabled = function() return not self.sv.debugEnabled end,
		}
    }

    LAM:RegisterOptionControls(panelName, optionsData)
end

function lib:OnLoad()
	self.sv = ZO_SavedVars:NewAccountWide('LibImplexSavedVariables', 1, nil, {
		debugEnabled = false,
		repetitions = 1,
		devMode = false,
	})

	if self.sv.devMode then
		SLASH_COMMANDS['/r'] = SLASH_COMMANDS['/reloadui']
		self:AddSettings()

		if self.sv.debugEnabled then
			LibImplex_ShowDebugWindow()
			if self.sv.showOrigin then
				LibImplex_ShowOrigin()
			end
		end
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
