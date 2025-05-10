local Log = LibImplex_Logger()

local WorldPositionToGuiRender3DPosition = WorldPositionToGuiRender3DPosition
local GuiRender3DPositionToWorldPosition = GuiRender3DPositionToWorldPosition
local GetWorldDimensionsOfViewFrustumAtDepth = GetWorldDimensionsOfViewFrustumAtDepth
local Set3DRenderSpaceToCurrentCamera = Set3DRenderSpaceToCurrentCamera
local GetUnitRawWorldPosition = GetUnitWorldPosition

local lerp = zo_lerp
local clampedPercentBetween = zo_clampedPercentBetween
local distance3D = zo_distance3D
local sqrt = math.sqrt

-- ----------------------------------------------------------------------------

local MarkersPool

local POOL_CONTROL = LibImplex_MarkersControl
local MARKER_TEMPLATE_NAME = 'LibImplex_MarkerTemplate'

-- ----------------------------------------------------------------------------

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

-- ----------------------------------------------------------------------------

--- @class Marker
--- @field position table|Vector Position
--- @field texture string Texture
--- @field control ZO_Object Control
--- @field updateFunction function|nil Update function
--- @field base Marker Base class
local Marker = class()

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

    self.updateFunction = updateFunction

    local control, objectKey = GetPool():AcquireObject()
    self.objectKey = objectKey
    control.m_Marker = self

    control:SetTexture(texture)
    if color then control:SetColor(unpack(color)) end

    self.control = control
end

function Marker:Update(...)
    if self.updateFunction then
        self:updateFunction(...)
    end
end

--[[
--- Get distance to point
--- @param point Vector
--- @return number @Distance to point in space
function Marker:DistanceTo(point)
    return (point - self.position):len()
end

function Marker:DistanceXZ(point)
    local dist = (point - self.position)
    return sqrt(pow(dist[1], 2) + pow(dist[3], 2))
end
--]]

function Marker:Delete()
    GetPool():ReleaseObject(self.objectKey)
end

-- ----------------------------------------------------------------------------

--- @class Marker2D : Marker
local Marker2D = class(Marker)

local MARKERS_CONTROL_2D = LibImplex_2DMarkers
local MARKERS_CONTROL_2D_NAME = 'LibImplex_2DMarkers'

local UI_WIDTH, UI_HEIGHT = GuiRoot:GetDimensions()
UI_HEIGHT = -UI_HEIGHT

local cX, cY, cZ = 0, 0, 0
local rX, rY, rZ = 0, 0, 0
local uX, uY, uZ = 0, 0, 0
local fX, fY, fZ = 0, 0, 0
local pX, pY, pZ = 0, 0, 0

function Marker2D:__init(position, orientation, texture, size, color, ...)
    local updateFunctions = {...}

    local function update(marker)
        local markerControl = marker.control
        local x, y, z = self.position[1], self.position[2], self.position[3]

        local dX, dY, dZ = x - cX, y - cY, z - cZ

        local Z = fX * dX + fY * dY + fZ * dZ

        if Z < 0 then
            markerControl:SetHidden(true)
            return
        end

        markerControl:SetHidden(false)  -- TODO: optimizable?

        -- --------------------------------------------------------------------

        local distance = distance3D(x, y, z, pX, pY, pZ)

        for i = 1, #updateFunctions do
            updateFunctions[i](marker, distance, {pX, pY, pZ})
            if markerControl:IsHidden() then return end
        end

        -- --------------------------------------------------------------------

        local X = rX * dX + rZ * dZ  -- rY * dY can be ignored, rY = 0 because it is vector in XZ plane
        local Y = uX * dX + uY * dY + uZ * dZ

        local w, h = GetWorldDimensionsOfViewFrustumAtDepth(Z)
        local scaleW = UI_WIDTH / w
        local scaleH = UI_HEIGHT / h

        markerControl:SetAnchor(CENTER, GuiRoot, CENTER, X * scaleW, Y * scaleH)

        markerControl:SetDrawLevel(-Z)
    end

    self.base.__init(self, position, orientation, texture, size, color, update)

    local control = self.control

    if size then control:SetDimensions(unpack(size)) end
end

local MarkerPOI = class(Marker)

function MarkerPOI:__init(position, texture, size, color, minDistance, maxDistance, minAlpha, maxAlpha)
    assert(minDistance ~= maxDistance, 'Min and max distance must be different!')

    local distanceSection = maxDistance - minDistance
    local alphaSection = maxAlpha - minAlpha

    local x, y, z = position[1], position[2], position[3]
    -- local b1, b2, b3, b4 = x + maxDistance * 100, x - maxDistance * 100, z + maxDistance * 100, z - maxDistance * 100

    local maxDistanceSq = maxDistance * maxDistance * 10000
    local minDistanceSq = minDistance * minDistance * 10000

    local function update(marker)
        local markerControl = marker.control

        -- for the future
        -- if pX > b1 or pX < b2 or pZ > b3 or pZ < b4 then
        --     markerControl:SetHidden(true)
        --     return
        -- end

        -- --------------------------------------------------------------------

        local diffX = pX - x
        local diffY = pY - y
        local diffZ = pZ - z

        local distanceSq = diffX * diffX + diffY * diffY + diffZ * diffZ

        if distanceSq > maxDistanceSq or distanceSq < minDistanceSq then
            markerControl:SetHidden(true)
            return
        end

        local distance = sqrt(distanceSq) * 0.01

        local dX, dY, dZ = x - cX, y - cY, z - cZ
        local Z = fX * dX + fY * dY + fZ * dZ

        if Z < 0 then
            markerControl:SetHidden(true)
            return
        end

        markerControl:SetHidden(false)

        local percent = (distance - minDistance) / distanceSection
        markerControl:SetAlpha(minAlpha + percent * alphaSection)

        if distance > 1000 then
            marker.distanceLabel:SetText(string.format('%.1fkm', distance * 0.001))
        else
            marker.distanceLabel:SetText(string.format('%dm', distance))
        end

        -- --------------------------------------------------------------------

        local X = rX * dX + rZ * dZ
        local Y = uX * dX + uY * dY + uZ * dZ

        local w, h = GetWorldDimensionsOfViewFrustumAtDepth(Z)
        local scaleW = UI_WIDTH / w
        local scaleH = UI_HEIGHT / h

        markerControl:SetAnchor(CENTER, GuiRoot, CENTER, X * scaleW, Y * scaleH)

        markerControl:SetDrawLevel(-Z)
        marker.distanceLabel:SetDrawLevel(-Z)
    end

    self.base.__init(self, position, nil, texture, size, color, update)

    local control = self.control

    if size then control:SetDimensions(unpack(size)) end
end

function Marker2D.UpdateVectors()
    Set3DRenderSpaceToCurrentCamera(MARKERS_CONTROL_2D_NAME)

    cX, cY, cZ = GuiRender3DPositionToWorldPosition(MARKERS_CONTROL_2D:Get3DRenderSpaceOrigin())
    fX, fY, fZ = MARKERS_CONTROL_2D:Get3DRenderSpaceForward()
    rX, rY, rZ = MARKERS_CONTROL_2D:Get3DRenderSpaceRight()
    uX, uY, uZ = MARKERS_CONTROL_2D:Get3DRenderSpaceUp()

    _, pX, pY, pZ = GetUnitRawWorldPosition('player')
end

-- ----------------------------------------------------------------------------

--- @class Marker3D : Marker
local Marker3D = class(Marker)

function Marker3D:__init(position, orientation, texture, size, color, ...)
    local updateFunctions = {...}

    local function update(marker)
        local markerControl = self.control
        local x, y, z = self.position[1], self.position[2], self.position[3]

        local distance = distance3D(x, y, z, pX, pY, pZ)

        for i = 1, #updateFunctions do
            updateFunctions[i](marker, distance, pX, pY, pZ, fX, fY, fZ, rX, rY, rZ, uX, uY, uZ)
            if markerControl:IsHidden() then return end
        end

        local dX, dY, dZ = x - cX, y - cY, z - cZ
        local Z = fX * dX + fY * dY + fZ * dZ

        markerControl:SetDrawLevel(-Z)
    end

    local needUpdates = #updateFunctions > 0

    self.base.__init(self, position, orientation, texture, size, color, needUpdates and update or nil)

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
    Marker2D = Marker2D,
    Marker3D = Marker3D,
    POI = MarkerPOI,
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
