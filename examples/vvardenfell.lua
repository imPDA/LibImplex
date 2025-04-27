local Log = LibImplex_Logger()

local PI = math.pi
local Vector = LibImplex.Vector

local WAYSHRINES = {
    Vector({249439, 12091, 438017}),  -- Suran
    Vector({345173, 11251, 453454}),  -- Molag Mar
    Vector({373173, 11697, 341597}),  -- Sadrith Mora
    Vector({213378, 11606, 495055}),  -- Vivec City
    Vector({236384, 12598, 515354}),  -- Vivec Temple
    Vector({174941, 11737, 415329}),  -- Balmora
    Vector({296751, 11444, 388208}),  -- Nchuleftingth
    Vector({303092, 12065, 249367}),  -- Tel Mora
    Vector({265403, 12041, 222293}),  -- Walley of the Wind
    Vector({116815, 11513, 224680}),  -- Urshilaku Camp
    Vector({84291, 12582, 282820}),  -- Gnisis
    Vector({130181, 12216, 309716}),  -- West Gash
    Vector({163633, 13489, 325761}),  -- Ald'runh
}

local PUBLIC_DUNGEONS = {
    {Vector({302678, 14371, 405426}), {0, PI + 0.77224952698846, 0}},  -- Nchuleftingth
    {Vector({233404, 10793, 224486}), {0, PI - 2.4951841930746, 0}},  -- Forgotten Wastes
}

local GROUP_BOSSES = {
    {Vector({319018, 11642, 371045}), {0, PI + 1.5735128800565, 0}},  -- Missir-Dadalit Egg Mine
    {Vector({307993, 12882, 279984}), {0, PI - 2.6850652710713, 0}},  -- Dubdil Alar Tower
    {Vector({120992, 11593, 280737}), {0, PI + 1.9277065630842, 0}},  -- Salothan's Council
    {Vector({168629, 12315, 365683}), {0, PI + 0.18065891516559, 0}},  -- Nilthog's Hollow
    {Vector({242467, 12709, 386794}), {0, PI - 2.2322306092538, 0}},  -- Sulipund Grange
}

local SKYSHARDS = {
    Vector({293358, 12945, 358762}),
    Vector({190315, 11542, 223894}),
    Vector({72188, 11143, 242602}),
}

local DELVES = {
    {Vector({302175, 11565, 297826}), {0, PI + 1.3313721157335, 0}},  -- Pulk
    {Vector({275085, 13056, 256989}), {0, PI - 1.5711721499647, 0}},  -- Nchuleft
    {Vector({104305, 13645, 230911}), {0, PI - 1.2858189602375, 0}},  -- Ashalmawia
    {Vector({110143, 11081, 333315}), {0, PI - 2.5039004910824, 0}},  -- Khartag Point

}

local NAMES = {
    WAYSHRINES = {
        'Suran',
        'Molag Mar',
        'Sadrith Mora',
        'Vivec City',
        'Vivec Temple',
        'Balmora',
        'Nchuleftingth',
    }
}

-- ----------------------------------------------------------------------------

local WAYSHRINE_TEXTURE = 'esoui/art/zonestories/completiontypeicon_wayshrine.dds'
local PUBLIC_DUNGEON_TEXTURE = 'EsoUI/Art/ZoneStories/completionTypeIcon_publicDungeon.dds'
local GROUP_BOSS_TEXTURE = '/esoui/art/icons/poi/poi_groupboss_complete.dds'
local SKYSHARD_TEXTURE = '/esoui/art/mappins/skyshard_complete.dds'
local DELVE_TEXTURE = '/esoui/art/icons/poi/poi_delve_complete.dds'

local TEXTURE_SIZE_2D = {48, 48}
local TEXTURE_DIMENSIONS_3D = {8, 8}
local COLOR1 = {0.2, 0.9, 0.2}
local COLOR2 = {1, 0.55, 0}

-- ----------------------------------------------------------------------------

local function addDistanceLabel(marker)
    local existedLabel = marker.control:GetNamedChild('DistanceLabel')
    if existedLabel then
        marker.distanceLabel = existedLabel
        existedLabel:SetHidden(false)
    else
        marker.distanceLabel = CreateControlFromVirtual('$(parent)DistanceLabel', marker.control, 'LibImplex_DistanceLabelTemplate')
    end
end

local function updateDistanceLabel(marker, distance)
    distance = distance * 0.01

    if distance > 1000 then
        marker.distanceLabel:SetText(string.format('%.1fkm', distance / 1000))
    else
        marker.distanceLabel:SetText(string.format('%dm', distance))
    end
end

-- ----------------------------------------------------------------------------

local animationTimeline
local animatedMarker

local function initializeWayshrineAnimation()
    animationTimeline = ANIMATION_MANAGER:CreateTimeline()

    animationTimeline:SetPlaybackType(ANIMATION_PLAYBACK_LOOP, LOOP_INDEFINITELY)
    local rotateAnimation = animationTimeline:InsertAnimation(ANIMATION_ROTATE3D, nil, 0)

    rotateAnimation:SetDuration(8 * 1000)
    rotateAnimation:SetStartYaw(0)
    rotateAnimation:SetEndYaw(2 * PI)
end

local function addWayshrineSignAnimation(marker)
    if marker == animatedMarker then return end

    for i = 1, animationTimeline:GetNumAnimations() do
        local animation = animationTimeline:GetAnimation(i)
        animation:SetAnimatedControl(marker.control)
    end

    animatedMarker = marker
end

-- ----------------------------------------------------------------------------

local A_BIT_HIGER = Vector({0, 350, 0})
local HIGHER = Vector({0, 1400, 0})

local function POIMarker(position, texture)
    local poiMarker = LibImplex.Marker.POI(
        position + A_BIT_HIGER,
        texture,
        TEXTURE_SIZE_2D,
        COLOR2,
        5,
        235,
        1,
        0.2
    )

    addDistanceLabel(poiMarker)

    return poiMarker
end

local function addUnknownPOI()
    if not Lib3D then return end

    local CLOSE_THRESHOLD = 4000^2

    local function close(x1, y1, z1, x2, y2, z2)
        local diff = (x2 - x1)^2 + (z2 - z1)^2
        return diff < CLOSE_THRESHOLD
    end

    local function exists(zoneIndex, x, y, z)
        if zoneIndex ~= 469 then return end

        for i = 1, #WAYSHRINES do
            local w = WAYSHRINES[i]
            if close(w[1], w[2], w[3], x, y, z) then return true end
        end

        for i = 1, #PUBLIC_DUNGEONS do
            local pd = PUBLIC_DUNGEONS[i][1]
            if close(pd[1], pd[2], pd[3], x, y, z) then return true end
        end

        for i = 1, #GROUP_BOSSES do
            local gb = GROUP_BOSSES[i][1]
            if close(gb[1], gb[2], gb[3], x, y, z) then return true end
        end

        for i = 1, #SKYSHARDS do
            local s = SKYSHARDS[i]
            if close(s[1], s[2], s[3], x, y, z) then return true end
        end

        for i = 1, #DELVES do
            local d = DELVES[i][1]
            if close(d[1], d[2], d[3], x, y, z) then return true end
        end
    end

    local zoneIndex = GetUnitZoneIndex('player')
    for i = 1, GetNumPOIs(zoneIndex) do
        local poiNX, poiNZ, pinType, texture = GetPOIMapInfo(zoneIndex, i)

        local poiX, poiZ = Lib3D:LocalToWorld(poiNX, poiNZ)
        poiX, poiZ = poiX * 100, poiZ * 100

        Log('POI: %d %d', poiX, poiZ)

        if not exists(zoneIndex, poiX, nil, poiZ) then
            Log('Adding unknown POI: %d %d', poiX, poiZ)
            POIMarker({poiX, 14000, poiZ}, texture)
        end
    end
end

-- Vvardenfell: zoneIdnex 469, zoneId 849
local function vvardenfell()
    LibImplex.Pool.GetPool():ReleaseAllObjects()
    if GetZoneId(GetUnitZoneIndex('player')) ~= 849 then return end

    -- local hideMarkerIfClose = LibImplex.UpdateFunction.HideIfTooClose(500)
    -- local changeAlphaWithDistance = LibImplex.UpdateFunction.ChangeAlphaWithDistance(0.2, 1, 20000, 5000)

    -- local hideDistantWayshrineMarker = HIDE_DISTANT and LibImplex.UpdateFunction.HideIfTooFar(21500) or function() end
    local hideDistantWayshrineSign = LibImplex.UpdateFunction.HideIfTooFar(12000)

    for i = 1, #WAYSHRINES do
        local wayshrinePosition = WAYSHRINES[i]

        --[[
        local wayshrineMarker = LibImplex.Marker.Marker2D(
            wayshrinePosition + A_BIT_HIGER,    -- position, can be array {x, y, z} or Vector({x, y ,z})
            nil,                                -- orientation {pitch, yaw, roll, [useDistanceBuffer]}, only for 3D markers! 2D markers ignores this
            WAYSHRINE_TEXTURE,                  -- texture file
            TEXTURE_SIZE_2D,                    -- size in pixels for 2D and scale for 3D
            COLOR1,                             -- color, simple array {r, g, b}

            hideMarkerIfClose,                  -- update functions, you can use as many as you wish
            hideDistantWayshrineMarker,         -- each update function must be callable with [marker, distance] arguments 
            changeAlphaWithDistance,            -- (distance = distance from player to a marker)
            updateDistanceLabel                 -- you can use some predefined functions from LibImplex.UpdateFunction or write custom like this one
        )
        ]]

        local wayshrineMarker = LibImplex.Marker.POI(
            wayshrinePosition + A_BIT_HIGER,
            WAYSHRINE_TEXTURE,
            TEXTURE_SIZE_2D,
            COLOR1,
            5,
            215,
            1,
            0.2
        )

        addDistanceLabel(wayshrineMarker)

        -- sign on top of a wayshrine
        LibImplex.Marker.Marker3D(
            wayshrinePosition + HIGHER,
            {0, 0, 0, true},
            WAYSHRINE_TEXTURE,
            TEXTURE_DIMENSIONS_3D,
            COLOR1,
            hideDistantWayshrineSign,
            addWayshrineSignAnimation
        )
    end

    for i = 1, #PUBLIC_DUNGEONS do
        local publicDungeonPosition = PUBLIC_DUNGEONS[i][1]
        POIMarker(publicDungeonPosition, PUBLIC_DUNGEON_TEXTURE)

        --[[
        local textureOrientation = PUBLIC_DUNGEONS[i][2]
        textureOrientation[4] = false

        LibImplex.Marker.Marker3D(
            publicDungeonPosition + A_BIT_HIGER,
            textureOrientation,
            PUBLIC_DUNGEON_TEXTURE,
            {2, 2},
            COLOR2,
            hideIfTooFar(21000),
            hideIfTooClose(500),
            changeDimensionsWithDistance(8, 2, 20000, 100),
            changeAlphaWithDistance(0.4, 1, 20000, 5000)
        )
        --]]
    end

    for i = 1, #GROUP_BOSSES do
        local groupBossPosition = GROUP_BOSSES[i][1]
        POIMarker(groupBossPosition, GROUP_BOSS_TEXTURE)
    end

    for i = 1, #SKYSHARDS do
        local skyshardPosition = SKYSHARDS[i]
        POIMarker(skyshardPosition, SKYSHARD_TEXTURE)
    end

    for i = 1, #DELVES do
        local delvePosition = DELVES[i][1]
        POIMarker(delvePosition, DELVE_TEXTURE)
    end

    animationTimeline:PlayFromStart()
end

--[[ big error :(
local function getNearbyPOIExactCoordinates()
    local zoneId, pX, pY, pZ = GetUnitRawWorldPosition('player')

    Log('Player: %f %f', pX, pZ)

    local function close(x, z)
        local diff = (x - pX)^2 + (z - pZ)^2

        Log('%d, %d - %d', x, z, diff)

        return diff < 10000
    end

    local zoneIndex = GetZoneIndex(zoneId)
    for i = 1, GetNumPOIs(zoneIndex) do
        local poiNX, poiNZ = GetPOIMapInfo(zoneIndex, i)

        local poiX, poiZ = Lib3D:LocalToWorld(poiNX, poiNZ)
        poiX, poiZ = poiX * 100, poiZ * 100

        -- Log(poiX, poiZ)

        if close(poiX, poiZ) then
            Log(poiX, pY, poiZ)
        end
    end
end
--]]

-- ----------------------------------------------------------------------------

do
    initializeWayshrineAnimation()
    EVENT_MANAGER:RegisterForEvent('LIB_IMPLEX_EXAMPLES_VVARDENFELL', EVENT_PLAYER_ACTIVATED, function() 
        vvardenfell()
        addUnknownPOI()
    end)
end
