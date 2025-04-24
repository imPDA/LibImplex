local TEXTURE = 'esoui/art/miscellaneous/gamepad/gp_bullet_ochre.dds'

local function followCameraView3D()
    local function inner(marker)
        marker.control:Set3DRenderSpaceForward( unpack(LibImplex.GetVectorForward())    )
        marker.control:Set3DRenderSpaceRight(   unpack(LibImplex.GetVectorRight())      )
        marker.control:Set3DRenderSpaceUp(      unpack(LibImplex.GetVectorUp())         )
    end

    return inner
end

local function followViewDirection3D()
    local function inner(marker)
        marker.control:Set3DRenderSpaceForward( unpack(LibImplex.GetVectorForward())    )
        marker.control:Set3DRenderSpaceRight(   unpack(LibImplex.GetVectorRight())      )
    end

    return inner
end

local function followUnit3D(unitTag, offsetX, offsetY, offsetZ)
    offsetX = offsetX or 0
    offsetY = offsetY or 0
    offsetZ = offsetZ or 0

    local function inner(marker)
        local _, wX, wY, wZ = GetUnitRawWorldPosition(unitTag)
        local rX, rY, rZ = WorldPositionToGuiRender3DPosition(wX+offsetX, wY+offsetY, wZ+offsetZ)
        marker.control:Set3DRenderSpaceOrigin(rX, rY, rZ)
    end

    return inner
end

local function addUnitIcon()
    LibImplex.Marker.Marker3D(
        {0, 0, 0}, {0, 0, 0, true}, TEXTURE, {0.5, 0.5}, {0.8, 0.8, 0},
        followViewDirection3D(),
        followUnit3D('player', nil, 300, nil)
    )
end

-- ----------------------------------------------------------------------------

do
    zo_callLater(addUnitIcon, 1000)
end
