local Log = LibImplex_Logger()

-- ----------------------------------------------------------------------------

local pow = math.pow
local sqrt = math.sqrt

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

local Pool

local function GetPool()
    if not Pool then
        local function factoryFunction(objectPool)
            local marker = ZO_ObjectPool_CreateNamedControl('$(parent)_Marker', 'LibImplex_MarkerTemplate', objectPool, LibImplex_2DMarkers)
            assert(marker ~= nil, 'Marker was not created')

            return marker
        end

        Pool = ZO_ObjectPool:New(factoryFunction, ZO_ObjectPool_DefaultResetControl)
    end

    return Pool
end

-- ----------------------------------------------------------------------------
--[[
--- @class Vector
--- @field c table|integer Coordinates
--- @field base table|nil Ancestor class
local Vector = class()

function Vector:__init(x, y, z)
    self.c = {x, y, z}
end

function Vector.eq(v1, v2)
    return v1.c[1] == v2.c[1] and v1.c[2] == v2.c[2] and v1.c[3] == v2.c[3]
end

function Vector.len(v)
    return sqrt(pow(v.c[1], 2) + pow(v.c[2], 2) + pow(v.c[3], 2))
end

function Vector.add(v1, v2)
    return Vector({
        v1.c[1] + v2.c[1],
        v1.c[2] + v2.c[2],
        v1.c[3] + v2.c[3]
    })
end

function Vector.sub(v1, v2)
    return Vector({
        v1.c[1] - v2.c[1],
        v1.c[2] - v2.c[2],
        v1.c[3] - v2.c[3]
    })
end

function Vector.negate(v)
    return Vector({-v.c[1], -v.c[2], -v.c[3]})
end

function Vector.dot(v1, v2)
    return v1.c[1] * v2.c[1] + v1.c[2] * v2.c[2] + v1.c[3] * v2.c[3]
end

function Vector.cross(v1, v2)
    return Vector({
        v1.c[2] * v2.c[3] - v1.c[3] * v2.c[2],
        v1.c[3] * v2.c[1] - v1.c[1] * v2.c[3],
        v1.c[1] * v2.c[2] - v1.c[2] * v2.c[1]
    })
end

Vector.__eq = Vector.eq
Vector.__len = Vector.len
Vector.__add = Vector.add
Vector.__sub = Vector.sub
Vector.__unm = Vector.negate
]]
-- ----------------------------------------------------------------------------

local mt = {
    __call = function(cls, obj)
        return setmetatable(obj, cls)
    end
}

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
    assert(type(scalar) == 'number', 'Scalar must be numeric type value, got %s instead', type(scalar))
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
    return {v[1], v[2], v[3]}
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

local floor = math.floor
local function x_(num)
    return floor(num * 0.1 + 0.5) / 0.1
end

local function GetPlayerVector()
    local zoneId, x, y, z = GetUnitRawWorldPosition('player')
    return Vector({x, y, z})
end

local function GetPlayerCoordinates()
    local zoneId, x, y, z = GetUnitRawWorldPosition('player')
    return x, y, z
end

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
function Marker:__init(position, texture, size, color, updateFunction)
    self.position = Vector(position)
    -- self.texture = texture
    self.updateFunction = updateFunction

    local control, objectKey = GetPool():AcquireObject()
    self.objectKey = objectKey
    control.m_Marker = self

    control:SetTexture(texture)
    control:SetDimensions(unpack(size))
    control:SetColor(unpack(color))

    -- control.timeline = ANIMATION_MANAGER:CreateTimelineFromVirtual('IMP_Pathfinder_TrailAnimation', control)
    -- control.timeline.object = control

    self.control = control
    self.active = true
end

function Marker:Update(...)
    self.control:SetHidden(self.hidden)
    if self.hidden then return end

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

function Marker:Hide()
    self.hidden = true
    -- self.control:SetHidden(true)
end

function Marker:Show()
    self.hidden = self.active and false
    -- self.control:SetHidden(false)
end

function Marker:Delete()
    self.hidden = true
    self.active = false
    GetPool():ReleaseObject(self.objectKey)
end

-- ----------------------------------------------------------------------------

--- @class Marker2D : Marker
local Marker2D = class(Marker)

local MARKERS_CONTROL_2D = LibImplex_2DMarkers
local UI_WIDTH, UI_HEIGHT = GuiRoot:GetDimensions()
local VF, VR, VU, VC

function Marker2D:__init(position, texture, size, color, updateFunction)
    local function update(...)
        local D = self.position - VC

        local pZ = VF:dot(D)

        if pZ < 0 then
            self.control:SetHidden(true)
            return
        end

        local pX = VR:dot(D)
        local pY = VU:dot(D)

        local w, h = GetWorldDimensionsOfViewFrustumAtDepth(pZ)
        local scale = UI_WIDTH / w

        -- self.control:ClearAnchors()
        self.control:SetAnchor(CENTER, MARKERS_CONTROL_2D, CENTER, pX * scale, -pY * scale)

        if updateFunction then updateFunction(...) end
    end

    self.base.__init(self, position, texture, size, color, update)
end

function Marker2D.UpdateVectors()
    Set3DRenderSpaceToCurrentCamera(MARKERS_CONTROL_2D:GetName())

    local cX, cY, cZ = GuiRender3DPositionToWorldPosition(MARKERS_CONTROL_2D:Get3DRenderSpaceOrigin())
    local fX, fY, fZ = MARKERS_CONTROL_2D:Get3DRenderSpaceForward()
    local rX, rY, rZ = MARKERS_CONTROL_2D:Get3DRenderSpaceRight()
    local uX, uY, uZ = MARKERS_CONTROL_2D:Get3DRenderSpaceUp()

    VC = Vector({cX, cY, cZ})
	VF = Vector({fX, fY, fZ})
	VR = Vector({rX, rY, rZ})
	VU = Vector({uX, uY, uZ})
end

local function GetPlayerOnScreenCoordinates()
    if not VF then return end

    local playerPosition = GetPlayerVector()
    local D = playerPosition - VC

    local pX = VR:dot(D)
    local pY = VU:dot(D)
    local pZ = VF:dot(D)

    local w, h = GetWorldDimensionsOfViewFrustumAtDepth(pZ)
    local scale = UI_WIDTH / w

    return pX * scale, -pY * scale, pZ
end

-- ----------------------------------------------------------------------------

--- @class Marker3D : Marker
local Marker3D = class(Marker)

function Marker3D:__init(position, texture, size, color, updateFunction, useDepthBuffer)
    self.base.__init(self, position, texture, size, color, updateFunction)
    -- self.useDepthBuffer = useDepthBuffer

    local control = self.control

    control:Create3DRenderSpace()
    control:Set3DLocalDimensions(1, 1)
    control:Set3DRenderSpaceUsesDepthBuffer(useDepthBuffer)

    local pitch, yaw, roll = select(3, unpack(position))
    pitch = pitch or 0
    yaw = yaw or 0
    roll = roll or 0

	control:Set3DRenderSpaceOrigin(unpack(position))
	control:Set3DRenderSpaceOrientation(pitch, yaw, roll)
    -- control:Set3DRenderSpaceUp(norm_dx, norm_dy, norm_dz)
	-- control:Set3DRenderSpaceRight(norm_tx, norm_ty, norm_tz)
end

-- ----------------------------------------------------------------------------

LibImplex_Markers = {
    Marker2D = Marker2D,
    Marker3D = Marker3D,
    GetPlayerVector = GetPlayerVector,
    GetPlayerCoordinates = GetPlayerCoordinates,
    GetPlayerOnScreenCoordinates = GetPlayerOnScreenCoordinates,
    GetPool = GetPool,
    Vector = Vector,
}
