local Log = LibImplex_Logger()

-- local TEXTURE = 'esoui/art/miscellaneous/gamepad/gp_bullet_ochre.dds'
local ARROW = 'LibImplex/textures/arrowwithstroke.dds'

local TEXTURES = LibImplex.Textures.Numbers

local function followCameraDirection3D(marker, distance, pX, pY, pZ, fX, fY, fZ, rX, rY, rZ, uX, uY, uZ)
    local markerControl = marker.control

    markerControl:Set3DRenderSpaceForward(fX, fY, fZ)
    markerControl:Set3DRenderSpaceRight(rX, rY, rZ)
    markerControl:Set3DRenderSpaceUp(uX, uY, uZ)
end


local function followViewDirection3D(marker, distance, pX, pY, pZ, fX, fY, fZ, rX, rY, rZ, uX, uY, uZ)
    local markerControl = marker.control

    markerControl:Set3DRenderSpaceForward(fX, fY, fZ)
    markerControl:Set3DRenderSpaceRight(rX, rY, rZ)
end


local function followUnit3D(unitTag, offsetX, offsetY, offsetZ)
    offsetX = offsetX or 0
    offsetY = offsetY or 0
    offsetZ = offsetZ or 0

    local function inner(marker, distance, pX, pY, pZ)
        local _, wX, wY, wZ = GetUnitRawWorldPosition(unitTag)
        local renderX, renderY, renderZ = WorldPositionToGuiRender3DPosition(wX+offsetX, wY+offsetY, wZ+offsetZ)
        marker.control:Set3DRenderSpaceOrigin(renderX, renderY, renderZ)
    end

    return inner
end

local function createUnitIcon(unitName, texture)
    return LibImplex.Marker.Marker3D(
        {0, 0, 0}, {0, 0, 0, true}, texture, {0.5, 0.5}, nil,
        followViewDirection3D,
        followUnit3D(unitName, nil, 500, nil)
    )
end

local function createPlayerIcon()
    local icon = LibImplex.Marker.Marker3D(
        {0, 0, 0}, {0, 0, 0, true}, ARROW, {0.7, 0.7}, nil,
        followViewDirection3D,
        followUnit3D('player', nil, 250, nil)
    )

    icon.control:SetAlpha(0.9)

    return icon
end

local GROUP_MARKERS = {nil, nil}

local function onGroupUpdate()
    local groupSize = GetGroupSize()
    local groupMarkers = #GROUP_MARKERS

    Log('There are %d markers atm, group size: %d', groupMarkers, groupSize)

    if groupSize > groupMarkers then
        Log('Lets add markers')
        for i = 1, groupSize - groupMarkers do
            local next = groupMarkers + i
            Log('Adding #%d', next)
            GROUP_MARKERS[next] = createUnitIcon('group' .. next, TEXTURES[next])
        end
    elseif groupSize < groupMarkers then
        Log('Lets remove markers')
        for i = 1, groupMarkers - groupSize do
            local last = groupMarkers + i - 1
            Log('Removing #%d', last)
            GROUP_MARKERS[last]:Delete()
            GROUP_MARKERS[last] = nil
        end
    end
end

-- ----------------------------------------------------------------------------

do
    EVENT_MANAGER:RegisterForEvent('LIB_IMPLEX_EXAMPLES_UNITS', EVENT_GROUP_UPDATE, onGroupUpdate)
    zo_callLater(onGroupUpdate, 2000)
    zo_callLater(createPlayerIcon, 2000)
end
