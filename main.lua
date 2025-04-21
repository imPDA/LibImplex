local Log = LibImplex_Logger('LibImplexLogger')

local function class(base)
	local cls = {}

	if type(base) == 'table' then
		for k, v in pairs(base) do
			cls[k] = v
		end

		cls.base = base
	end

	cls.__index = cls

	setmetatable(cls, {
        __call = function(self, ...)
            local obj = setmetatable({}, cls)

            if self.__init then
                self.__init(obj, ...)
            elseif base ~= nil and base.__init ~= nil then
                base.__init(obj, ...)
            end

            return obj
        end
	})

	return cls
end

-- ----------------------------------------------------------------------------

local addon = {}

addon.name = 'LibImplex'
addon.displayName = 'LibImplex'
addon.version = '0.0.1'

local EVENT_NAMESPACE = 'LIBIMPLEX_EVEN_NAMESPACE'

-- ----------------------------------------------------------------------------

local MARKER_TEXTURE = 'EsoUI/Art/UnitAttributeVisualizer/attributeBar_dynamic_fill.dds'

-- ----------------------------------------------------------------------------

-- local PM = PATHFINDER_Markers

-- ----------------------------------------------------------------------------

local Vector = LibImplex_Markers.Vector

-- local statusBar = LibImplex_Bar

function addon:OnPlayerActivated(initial)
	local function keepUnderPlayer(marker)
		Set3DRenderSpaceToCurrentCamera('LibImplex_MI')

		-- local _, x, y, z = GetUnitWorldPosition('player')
		local wX, wY, wZ = Lib3D:ComputePlayerRenderSpacePosition()
		marker.control:Set3DRenderSpaceOrigin(wX, wY+marker.offset, wZ)

		marker.control:Set3DRenderSpaceForward	(LibImplex_MI:Get3DRenderSpaceForward()	)
		marker.control:Set3DRenderSpaceRight	(LibImplex_MI:Get3DRenderSpaceRight()	)
		marker.control:Set3DRenderSpaceUp		(LibImplex_MI:Get3DRenderSpaceUp()		)

		-- local fX, fY, fZ = LibImplex_MI:Get3DRenderSpaceForward()
		-- marker.control:Set3DRenderSpaceForward	(fX, fY, fZ)
		-- marker.control:Set3DRenderSpaceRight	(-fZ, 0, fX)
		-- marker.control:Set3DRenderSpaceUp		(
		-- 	- fX * fY,
		-- 	fX * fX + fZ * fZ,
		-- 	- fZ * fY
		-- )
	end

	local m = LibImplex_Markers.Marker3D({0, 0, 0, 0, 0, 0}, MARKER_TEXTURE, {150, 6}, {0, 0, 1}, keepUnderPlayer, true)
	local s = LibImplex_Markers.Marker3D({0, 0, 0, 0, 0, 0}, MARKER_TEXTURE, {150, 6}, {0, 1, 0}, keepUnderPlayer, true)
	m.control:Set3DLocalDimensions(2, 0.07)
	s.control:Set3DLocalDimensions(2, 0.07)

	m.offset = 2.2
	s.offset = 2

	local function updatePosition()
		-- LibImplex_Markers.Marker2D.UpdateVectors()
		m:Update()
		s:Update()
		-- s.control:SetAnchor(TOP, m.control, BOTTOM)
	end

	local function setPower(_, unitTag, powerIndex, powerType, powerValue, powerMax, powerEffectiveMax)
		local w = powerValue / powerMax

		if powerType == POWERTYPE_MAGICKA then
			-- m.control:SetWidth(w)
			m.control:Set3DLocalDimensions(2 * w, 0.07)
			return
		end

		if powerType == POWERTYPE_STAMINA then
			s.control:Set3DLocalDimensions(2 * w, 0.07)
			return
		end
	end

	EVENT_MANAGER:RegisterForUpdate(EVENT_NAMESPACE, 5, updatePosition)
	EVENT_MANAGER:RegisterForEvent(EVENT_NAMESPACE, EVENT_POWER_UPDATE, setPower)
end

function addon:OnLoad()
	SLASH_COMMANDS['/r'] = SLASH_COMMANDS['/reloadui']

	EVENT_MANAGER:RegisterForEvent(EVENT_NAMESPACE, EVENT_PLAYER_ACTIVATED, function(_, initial) self:OnPlayerActivated(initial) end)

	ZO_PostHook(ZO_ChampionSkillStar, 'ShowKeyboardTooltip', function(championSkillStar)
		local championSkillData = championSkillStar:GetChampionSkillData()
		ChampionSkillTooltip:AddLine(('ID: %d'):format(championSkillData:GetId()))
	end)

	GLOBAL_SLOTTABLE_CHAMPION_SKILLS_IDS = {}
	local function canBeSlotted(skillId)
		return CHAMPION_DATA_MANAGER:GetChampionSkillData(skillId):IsTypeSlottable()
	end
	for discipline = 1, 3 do
		local disciplineSkills = GetNumChampionDisciplineSkills(discipline)
		Log(('%s: %d skills'):format(GetChampionDisciplineName(discipline), disciplineSkills))
		for i = 1, disciplineSkills do
			local skillId = GetChampionSkillId(discipline, i)
			local slottable = canBeSlotted(skillId)
			Log(('ID: %03d, slottable: %s, %s'):format(skillId, tostring(slottable), GetChampionSkillName(skillId)))
			if slottable then
				table.insert(GLOBAL_SLOTTABLE_CHAMPION_SKILLS_IDS, skillId)
			end
		end
	end

	-- ZO_PreHook(_G, 'ZO_GroupFinder_AdditionalFilters_OnInitialized', function()
	-- 	SetGroupFinderFilterEnforceRoles(false)
	-- end)

	SetGroupFinderFilterEnforceRoles(false)
	GROUPFINDER_ADDITIONAL_FILTERS_KEYBOARD:Refresh()

	ZO_PostHook(AbilityTooltip, 'SetCraftedAbilityScript', function(tooltip)
		tooltip:AddLine()
	end)
end

EVENT_MANAGER:RegisterForEvent(EVENT_NAMESPACE, EVENT_ADD_ON_LOADED, function(_, addonName)
	if addonName ~= addon.name then return end
	EVENT_MANAGER:UnregisterForEvent(addon.name, EVENT_ADD_ON_LOADED)

    addon:OnLoad()
end)
