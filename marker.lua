local Log = LibImplex_Logger()

local WorldPositionToGuiRender3DPosition = WorldPositionToGuiRender3DPosition
local GuiRender3DPositionToWorldPosition = GuiRender3DPositionToWorldPosition
local GetWorldDimensionsOfViewFrustumAtDepth = GetWorldDimensionsOfViewFrustumAtDepth
local Set3DRenderSpaceToCurrentCamera = Set3DRenderSpaceToCurrentCamera
local GetUnitRawWorldPosition = GetUnitWorldPosition

local pow = math.pow
local sqrt = math.sqrt
local floor = math.floor
local lerp = zo_lerp
local clampedPercentBetween = zo_clampedPercentBetween
local distance3D = zo_distance3D

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

local mt = {
    __call = function(cls, obj)
        return setmetatable(obj, cls)
    end
}

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

--- @class Vector
local Vector = setmetatable({}, mt)
Vector.__index = Vector

function Vector.len(v)
    return sqrt(v:dot(v))
end

function Vector.add(v1, v2)
    return Vector({
        v1[1] + v2[1],
        v1[2] + v2[2],
        v1[3] + v2[3]
    })
end

function Vector.sub(v1, v2)
    return Vector({
        v1[1] - v2[1],
        v1[2] - v2[2],
        v1[3] - v2[3]
    })
end

function Vector.negate(v)
    return Vector({-v[1], -v[2], -v[3]})
end

function Vector.multiply(v, scalar)
    -- TODO: get rid of assertion
    -- assert(type(scalar) == 'number', 'Scalar must be numeric type value, got %s instead', type(scalar))
    return Vector({v[1] * scalar, v[2] * scalar, v[3] * scalar})
end

function Vector.dot(v1, v2)
    return v1[1] * v2[1] + v1[2] * v2[2] + v1[3] * v2[3]
end

function Vector.cross(v1, v2)
    return Vector({
        v1[2] * v2[3] - v1[3] * v2[2],
        v1[3] * v2[1] - v1[1] * v2[3],
        v1[1] * v2[2] - v1[2] * v2[1]
    })
end

function Vector.unit(v)
    local inverse_length = 1 / v:len()
    return v * inverse_length
end

function Vector.coordinates(v)
    return v[1], v[2], v[3]
end

-- function Vector.lt(v1, v2)
--     return v1:dot(v1) < v2:dot(v2)
-- end

-- function Vector.le(v1, v2)
--     return v1:dot(v1) <= v2:dot(v2)
-- end

function Vector.eq(v1, v2)
    return v1[1] == v2[1] and v1[2] == v2[2] and v1[3] == v2[3]
end

Vector.__eq = Vector.eq
Vector.__len = Vector.len
Vector.__add = Vector.add
Vector.__sub = Vector.sub
Vector.__unm = Vector.negate
Vector.__mul = Vector.multiply
-- Vector.__lt = Vector.lt
-- Vector.__le = Vector.le

-- ----------------------------------------------------------------------------

-- local function GetPlayerVector()
--     local zoneId, x, y, z = GetUnitRawWorldPosition('player')
--     return Vector({x, y, z})
-- end

-- local function GetPlayerCoordinates()
--     local zoneId, x, y, z = GetUnitRawWorldPosition('player')
--     return x, y, z
-- end

--[[
* GetUnitWorldPosition(*string* _unitTag_)
** _Returns:_ *integer* _zoneId_, *integer* _worldX_, *integer* _worldY_, *integer* _worldZ_

* GetUnitRawWorldPosition(*string* _unitTag_)
** _Returns:_ *integer* _zoneId_, *integer* _worldX_, *integer* _worldY_, *integer* _worldZ_
]]

-- ----------------------------------------------------------------------------

--- @class Marker
--- @field position Vector Position
--- @field texture string Texture
--- @field control ZO_Object Control
--- @field updateFunction function|nil Update function
--- @field base Marker Base class
local Marker = class()

--- Constructor for Marker
--- @param position table X Y Z
--- @param texture string Texture
--- @param size table W x H
--- @param color table RGB
--- @param updateFunction function|nil Update function
function Marker:__init(position, orientation, texture, size, color, updateFunction)
    self.position = Vector(position)
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

local VF, VR, VU, VC = Vector({0, 0, 0}), Vector({0, 0, 0}), Vector({0, 0, 0}), Vector({0, 0, 0})
local VP = Vector{{0, 0, 0}}

local cX, cY, cZ = 0, 0, 0
local rX, rY, rZ = 0, 0, 0
local uX, uY, uZ = 0, 0, 0
local fX, fY, fZ = 0, 0, 0
local pX, pY, pZ = 0, 0, 0

function Marker2D:__init(position, orientation, texture, size, color, ...)
    -- local marker = self.control  -- TODO: will this increase performance?
    local updateFunctions = ... and {...}

    local function update(marker)
        local markerControl = marker.control
        local x, y, z = self.position[1], self.position[2], self.position[3]

        -- local D = self.position - VC
        local dX = x - cX
        local dY = y - cY
        local dZ = z - cZ

        -- local Z = VF:dot(D)
        -- local Z = VF[1] * D[1] + VF[2] * D[2] + VF[3] * D[3]
        -- local Z = VF[1] * Dx + VF[2] * Dy + VF[3] * Dz
        local Z = fX * dX + fY * dY + fZ * dZ

        -- if Vector.len(self.position - VP) < 2000 then
        --     Log('Difference: z: %f, distance: %f', Z, Vector.len(self.position - VP))
        -- end

        if Z < 0 then
            markerControl:SetHidden(true)
            return
        end

        markerControl:SetHidden(false)  -- optimizable?

        -- TODO: 100% optimizable
        -- local X = VR:dot(D)
        -- local Y = VU:dot(D)
        -- local X = VR[1] * D[1] + VR[2] * D[2] + VR[3] * D[3]
        -- local Y = VU[1] * D[1] + VU[2] * D[2] + VU[3] * D[3]
        -- local X = VR[1] * dX + VR[2] * dY + VR[3] * dZ
        -- local Y = VU[1] * dX + VU[2] * dY + VU[3] * dZ
        local X = rX * dX + rY * dY + rZ * dZ
        local Y = uX * dX + uY * dY + uZ * dZ

        local w, h = GetWorldDimensionsOfViewFrustumAtDepth(Z)
        local scaleW = UI_WIDTH / w
        local scaleH = UI_HEIGHT / h

        -- marker:ClearAnchors()
        markerControl:SetAnchor(CENTER, GuiRoot, CENTER, X * scaleW, Y * scaleH)

        -- if updateFunctions then
        -- local distance = marker:DistanceTo(VP)
        local distance = distance3D(x, y, z, pX, pY, pZ)

        for i = 1, #updateFunctions do
            updateFunctions[i](marker, distance)
            if markerControl:IsHidden() then return end
        end
        --end
    end

    self.base.__init(self, position, orientation, texture, size, color, update)

    local control = self.control

    if size then control:SetDimensions(unpack(size)) end
end

function Marker2D.UpdateVectors()
    Set3DRenderSpaceToCurrentCamera(MARKERS_CONTROL_2D_NAME)

    --[[
    local cX, cY, cZ = GuiRender3DPositionToWorldPosition(MARKERS_CONTROL_2D:Get3DRenderSpaceOrigin())
    local fX, fY, fZ = MARKERS_CONTROL_2D:Get3DRenderSpaceForward()
    local rX, rY, rZ = MARKERS_CONTROL_2D:Get3DRenderSpaceRight()
    local uX, uY, uZ = MARKERS_CONTROL_2D:Get3DRenderSpaceUp()

    optimization?
    VC = Vector({cX, cY, cZ})
	VF = Vector({fX, fY, fZ})
	VR = Vector({rX, rY, rZ})
	VU = Vector({uX, uY, uZ})
    --]]

    --[[
    VC[1], VC[2], VC[3] = GuiRender3DPositionToWorldPosition(MARKERS_CONTROL_2D:Get3DRenderSpaceOrigin())
	VF[1], VF[2], VF[3] = MARKERS_CONTROL_2D:Get3DRenderSpaceForward()
	VR[1], VR[2], VR[3] = MARKERS_CONTROL_2D:Get3DRenderSpaceRight()
	VU[1], VU[2], VU[3] = MARKERS_CONTROL_2D:Get3DRenderSpaceUp()

    _, VP[1], VP[2], VP[3] = GetUnitRawWorldPosition('player')
    --]]

    ---[[
    cX, cY, cZ = GuiRender3DPositionToWorldPosition(MARKERS_CONTROL_2D:Get3DRenderSpaceOrigin())
    fX, fY, fZ = MARKERS_CONTROL_2D:Get3DRenderSpaceForward()
    rX, rY, rZ = MARKERS_CONTROL_2D:Get3DRenderSpaceRight()
    uX, uY, uZ = MARKERS_CONTROL_2D:Get3DRenderSpaceUp()

    _, pX, pY, pZ = GetUnitRawWorldPosition('player')
    --]]
end

--[[
local function GetPlayerOnScreenCoordinates()
    local D = VP - VC

    local pX = VR:dot(D)
    local pY = VU:dot(D)
    local pZ = VF:dot(D)

    local w, h = GetWorldDimensionsOfViewFrustumAtDepth(pZ)
    local scaleW = UI_WIDTH / w
    local scaleH = UI_HEIGHT / h

    return pX * scaleW, -pY * scaleH, pZ
end
--]]

-- ----------------------------------------------------------------------------

--- @class Marker3D : Marker
local Marker3D = class(Marker)

function Marker3D:__init(position, orientation, texture, size, color, ...)
    local updateFunctions = ... and {...}

    local function update(marker)
        local markerControl = self.control
        local x, y, z = self.position[1], self.position[2], self.position[3]

        -- if updateFunctions then
        -- local distance = marker:DistanceTo(VP)
        local distance = distance3D(x, y, z, pX, pY, pZ)

        for i = 1, #updateFunctions do
            updateFunctions[i](marker, distance)
            if markerControl:IsHidden() then return end
        end
        -- end
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

-- ----------------------------------------------------------------------------

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
    -- return function() end

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

LibImplex = {}

LibImplex.Marker = {
    Marker2D = Marker2D,
    Marker3D = Marker3D,
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

LibImplex.Vector = Vector
LibImplex.GetVectorForward = function() return {fX, fY, fZ} end  -- function() return VF end
LibImplex.GetVectorRight = function() return {rX, rY, rZ} end  -- function() return VR end
LibImplex.GetVectorUp = function() return {uX, uY, uZ} end  -- function() return VU end

-- local function calculateEulerAngles()
--     local pitch = math.asin(-VF[2])
--     local yaw = math.atan2(VF[1], VF[3])
--     local roll = math.atan2(VR[2], VU[2])

--     return pitch, yaw, roll
-- end

-- LibImplex.Camera = {
--     GetOrientation = calculateEulerAngles
-- }

LibImplex.UpdateFunction = {
    HideIfTooFar = HideIfTooFar,
    HideIfTooClose = HideIfTooClose,
    ChangeAlphaWithDistance = ChangeAlphaWithDistance,
    ChangeSize3DWithDistance = Change3DLocalDimensionsWithDistance,
}
