-- local Log = LibImplex_Logger()

local WorldPositionToGuiRender3DPosition = WorldPositionToGuiRender3DPosition
local GuiRender3DPositionToWorldPosition = GuiRender3DPositionToWorldPosition
local GetWorldDimensionsOfViewFrustumAtDepth = GetWorldDimensionsOfViewFrustumAtDepth
local Set3DRenderSpaceToCurrentCamera = Set3DRenderSpaceToCurrentCamera
local GetUnitWorldPosition = GetUnitWorldPosition
local GetUnitRawWorldPosition = GetUnitRawWorldPosition

local lerp = zo_lerp
local clampedPercentBetween = zo_clampedPercentBetween
local distance3D = zo_distance3D
local sqrt = math.sqrt
local tan = math.tan
local floor = math.floor

-- local PI_360 = math.pi / 360
-- local function getK()
--     local fov = GetSetting(SETTING_TYPE_CAMERA, CAMERA_SETTING_THIRD_PERSON_FIELD_OF_VIEW)
--     return 2 * tan(fov * PI_360)  -- 2 * tan(FOV/2 in rad)
-- end

-- ----------------------------------------------------------------------------

local MarkersPool
local StaticMarkersPool

local POOL_CONTROL = LibImplex_MarkersControl
local MARKER_TEMPLATE_NAME = 'LibImplex_MarkerTemplate'

-- ----------------------------------------------------------------------------

local function GetPool()
    if not MarkersPool then
        local function factoryFunction(objectPool)
            local marker = ZO_ObjectPool_CreateNamedControl('$(parent)_Marker', MARKER_TEMPLATE_NAME, objectPool, POOL_CONTROL)
            assert(marker ~= nil, 'Marker was not created')

            return marker
        end

        local function resetFunction(control)
            for i = 1, control:GetNumChildren() do
                local childControl = control:GetChild(i)
                childControl:SetHidden(true)
            end

            control:SetHidden(true)
        end

        MarkersPool = ZO_ObjectPool:New(factoryFunction, resetFunction)
    end

    return MarkersPool
end

local function GetStaticPool()
    if not StaticMarkersPool then
        local function factoryFunction(objectPool)
            local marker = ZO_ObjectPool_CreateNamedControl('$(parent)_StaticMarker', MARKER_TEMPLATE_NAME, objectPool, POOL_CONTROL)
            assert(marker ~= nil, 'Marker was not created')

            return marker
        end

        local function resetFunction(control)
            for i = 1, control:GetNumChildren() do
                local childControl = control:GetChild(i)
                childControl:SetHidden(true)
            end

            control:SetHidden(true)
        end

        StaticMarkersPool = ZO_ObjectPool:New(factoryFunction, resetFunction)
    end

    return StaticMarkersPool
end

-- ----------------------------------------------------------------------------

--- @class Marker
--- @field position table|Vector Position
--- @field texture string Texture
--- @field control ZO_Object Control
--- @field updateFunction function|nil Update function
--- @field base Marker Base class
local Marker = LibImplex.class()

--- Constructor for Marker
--- @param position table|Vector X Y Z
--- @param orientation table Pitch Yaw Roll
--- @param texture string Texture
--- @param size table W x H
--- @param color table RGB
--- @param updateFunction function|nil Update function
function Marker:__init(position, orientation, texture, size, color, updateFunction)
    self.position = position
    self.orientation = orientation

    if updateFunction then
        self.Update = updateFunction
        self.pool = GetPool()
    else
        self.pool = GetStaticPool()
    end

    local control, objectKey = self.pool:AcquireObject()

    self.objectKey = objectKey
    control.m_Marker = self

    control:SetTexture(texture)
    if color then control:SetColor(unpack(color)) end

    self.control = control
end

-- function Marker:Update(...)
--     self:updateFunction(...)
-- end

--[[
--- Get distance to point
--- @param point Vector
--- @return number @Distance to point in space
function Marker:DistanceTo(point)
    return (point - self.position):len()
end
--]]

function Marker:DistanceXZ(point)
    local dx = point[1] - self.position[1]
    local dz = point[3] - self.position[3]

    return sqrt(dx * dx + dz * dz)
end

function Marker:Delete()
    self.control.m_Marker = nil
    self.pool:ReleaseObject(self.objectKey)
    self.pool = nil
    self.Update = nil
end

-- ----------------------------------------------------------------------------

--- @class Marker2D : Marker
local Marker2D = LibImplex.class(Marker)

local MARKERS_CONTROL_2D = LibImplex_2DMarkers
local MARKERS_CONTROL_2D_NAME = 'LibImplex_2DMarkers'

local UI_WIDTH, UI_HEIGHT = GuiRoot:GetDimensions()
local NEGATIVE_UI_HEIGHT = -UI_HEIGHT
-- UI_HEIGHT_K = NEGATIVE_UI_HEIGHT / getK()

local cX, cY, cZ = 0, 0, 0
local rX, rY, rZ = 0, 0, 0
local uX, uY, uZ = 0, 0, 0
local fX, fY, fZ = 0, 0, 0
local pwX, pwY, pwZ = 0, 0, 0
local prwX, prwY, prwZ = 0, 0, 0

function Marker2D:__init(position, orientation, texture, size, color, ...)
    local function update(marker)
        local markerControl = marker.control
        local x, y, z = self.position[1], self.position[2], self.position[3]

        local dX, dY, dZ = x - cX, y - cY, z - cZ

        local Z = fX * dX + fY * dY + fZ * dZ

        if Z < 0 then
            markerControl:SetHidden(true)
            return
        end

        -- --------------------------------------------------------------------

        -- local distance = distance3D(x, y, z, pX, pY, pZ)
        local diffX = prwX - x
        local diffY = prwY - y
        local diffZ = prwZ - z
        local distance = sqrt(diffX * diffX + diffY * diffY + diffZ * diffZ)

        local updateFunctions = marker.updateFunctions
        for i = 1, #updateFunctions do
            if updateFunctions[i](marker, distance, prwX, prwY, prwZ, fX, fY, fZ, rX, rY, rZ, uX, uY, uZ) then return end
        end

        -- --------------------------------------------------------------------

        local X = rX * dX + rZ * dZ  -- rY * dY can be ignored, rY = 0 because it is vector in XZ plane
        local Y = uX * dX + uY * dY + uZ * dZ

        local w, h = GetWorldDimensionsOfViewFrustumAtDepth(Z)
        local scaleW = UI_WIDTH / w
        local scaleH = NEGATIVE_UI_HEIGHT / h

        markerControl:SetAnchor(CENTER, GuiRoot, CENTER, X * scaleW, Y * scaleH)

        markerControl:SetDrawLevel(-Z)
        markerControl:SetHidden(false)
    end

    self.base.__init(self, position, orientation, texture, size, color, update)
    self.updateFunctions = {...}

    local control = self.control

    if size then control:SetDimensions(unpack(size)) end

    self.distanceLabel = control:GetNamedChild('DistanceLabel')
end

function Marker2D:Delete()
    self.base.Delete(self)
    self.distanceLabel:SetHidden(true)
end

function Marker2D.UpdateVectors()
    Set3DRenderSpaceToCurrentCamera(MARKERS_CONTROL_2D_NAME)

    cX, cY, cZ = GuiRender3DPositionToWorldPosition(MARKERS_CONTROL_2D:Get3DRenderSpaceOrigin()) -- RW
    fX, fY, fZ = MARKERS_CONTROL_2D:Get3DRenderSpaceForward()
    rX, rY, rZ = MARKERS_CONTROL_2D:Get3DRenderSpaceRight()
    uX, uY, uZ = MARKERS_CONTROL_2D:Get3DRenderSpaceUp()
    -- TODO: normalize?

    _, pwX, pwY, pwZ = GetUnitWorldPosition('player')
    _, prwX, prwY, prwZ = GetUnitRawWorldPosition('player')
end

-- ----------------------------------------------------------------------------

--- @class Marker3D : Marker
local Marker3D = LibImplex.class(Marker)

function Marker3D:__init(position, orientation, texture, size, color, ...)
    local updateFunctions = {...}

    local function update(marker)
        local markerControl = self.control
        local x, y, z = self.position[1], self.position[2], self.position[3]

        -- local distance = distance3D(x, y, z, pX, pY, pZ)
        local diffX = prwX - x
        local diffY = prwY - y
        local diffZ = prwZ - z
        local distance = sqrt(diffX * diffX + diffY * diffY + diffZ * diffZ)

        for i = 1, #updateFunctions do
            if updateFunctions[i](marker, distance, prwX, prwY, prwZ, fX, fY, fZ, rX, rY, rZ, uX, uY, uZ) then return end
        end

        local dX, dY, dZ = x - cX, y - cY, z - cZ
        local Z = fX * dX + fY * dY + fZ * dZ

        markerControl:SetDrawLevel(-Z)
    end

    self.base.__init(self, position, orientation, texture, size, color, update)

    local control = self.control

    size = size or {1, 1}

    control:Create3DRenderSpace()
    control:Set3DLocalDimensions(unpack(size))

    local pitch, yaw, roll, depthBuffer = unpack(orientation)
    pitch = pitch or 0
    yaw = yaw or 0
    roll = roll or 0

    -- worlds coordinates to render coordinates
    local rendX, rendY, rendZ = WorldPositionToGuiRender3DPosition(unpack(position))

	control:Set3DRenderSpaceOrigin(rendX, rendY, rendZ)
	control:Set3DRenderSpaceOrientation(pitch, yaw, roll)
    control:Set3DRenderSpaceUsesDepthBuffer(depthBuffer)

    control:SetHidden(false)
end

--- @class MarkerStatic3D : Marker
local Marker3DStatic = LibImplex.class(Marker)

function Marker3DStatic:__init(position, orientation, texture, size, color)
    self.base.__init(self, position, orientation, texture, size, color)  -- TODO: refactor

    local control = self.control

    size = size or {1, 1}

    control:Create3DRenderSpace()
    control:Set3DLocalDimensions(unpack(size))

    local pitch, yaw, roll, depthBuffer = unpack(orientation)
    pitch = pitch or 0
    yaw = yaw or 0
    roll = roll or 0

    -- worlds coordinates to render coordinates
    local rendX, rendY, rendZ = WorldPositionToGuiRender3DPosition(unpack(position))

	control:Set3DRenderSpaceOrigin(rendX, rendY, rendZ)
	control:Set3DRenderSpaceOrientation(pitch, yaw, roll)
    control:Set3DRenderSpaceUsesDepthBuffer(depthBuffer)

    control:SetHidden(false)
end

-- ----------------------------------------------------------------------------
-- TODO: optimize lerp and clamp functions

local function ChangeAlphaWithDistance(minAlpha, maxAlpha, minDistance, maxDistance)
    local function inner(marker, distance)
        marker.control:SetAlpha(lerp(minAlpha, maxAlpha, clampedPercentBetween(minDistance, maxDistance, distance)))
    end

    return inner
end

local function Change3DLocalDimensionsWithDistance(minDimensions, maxDimensions, minDistance, maxDistance)
    local function inner(marker, distance)
        local d = lerp(minDimensions, maxDimensions, clampedPercentBetween(minDistance, maxDistance, distance))
        marker.control:Set3DLocalDimensions(d, d)
    end

    return inner
end

local function HideIfTooFar(maxDistance)
    local function inner(marker, distance)
        marker.control:SetHidden(distance > maxDistance)
    end

    return inner
end

local function HideIfTooClose(minDistance)
    local function inner(marker, distance)
        marker.control:SetHidden(distance < minDistance)
    end

    return inner
end

-- ----------------------------------------------------------------------------

LibImplex = LibImplex or {}

LibImplex.Marker = {
    subclass = function() return LibImplex.class(Marker) end,
    Marker2D = Marker2D,
    Marker3D = Marker3D,
    Marker3DStatic = Marker3DStatic,

    _2D = Marker2D,
    _3D = Marker3D,
    _3DStatic = Marker3DStatic,
}

-- LibImplex.Player = {
--     GetVector = GetPlayerVector,
--     GetVector = function() return VP end,
--     GetCoordinates = function() return VP[1], VP[2], VP[3] end,
--     GetOnScreenCoordinates = GetPlayerOnScreenCoordinates,
-- }

LibImplex.Pool = {
    GetPool = GetPool,
}

LibImplex.GetVectorForward = function() return {fX, fY, fZ} end
LibImplex.GetVectorRight = function() return {rX, rY, rZ} end
LibImplex.GetVectorUp = function() return {uX, uY, uZ} end
LibImplex.GetCameraPosition = function() return cX, cY, cZ end

local function calculateEulerAngles()
    local pitch = math.asin(-fY)
    local yaw = math.atan2(fX, fZ)
    local roll = math.atan2(rY, uY)

    return pitch, yaw, roll
end

LibImplex.Camera = {
    GetOrientation = calculateEulerAngles
}

LibImplex.UpdateFunction = {
    HideIfTooFar = HideIfTooFar,
    HideIfTooClose = HideIfTooClose,
    ChangeAlphaWithDistance = ChangeAlphaWithDistance,
    ChangeSize3DWithDistance = Change3DLocalDimensionsWithDistance,
}
