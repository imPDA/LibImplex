local sqrt = math.sqrt
local sin = math.sin
local cos = math.cos

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

local function FromEuler(yaw, pitch, roll)
    local cy = cos(yaw * 0.5)
    local sy = sin(yaw * 0.5)
    local cp = cos(pitch * 0.5)
    local sp = sin(pitch * 0.5)
    local cr = cos(roll * 0.5)
    local sr = sin(roll * 0.5)

    return {
        --[[w]] cr * cp * cy + sr * sp * sy,
        --[[i]] sr * cp * cy - cr * sp * sy,
        --[[j]] cr * sp * cy + sr * cp * sy,
        --[[k]] cr * cp * sy - sr * sp * cy,
    }
end

local function copysign(x, y)
    return (y >= 0 and math.abs(x)) or -math.abs(x)
end

local function ToEuler(q)  -- TODO: imports, etc.
    local w, x, y, z = q[1], q[2], q[3], q[4]

    -- Roll (x-axis rotation)
    local sinr_cosp = 2 * (w * x + y * z)
    local cosr_cosp = 1 - 2 * (x * x + y * y)
    local roll = math.atan2(sinr_cosp, cosr_cosp)

    -- Pitch (y-axis rotation)
    local sinp = 2 * (w * y - z * x)
    local pitch
    if math.abs(sinp) >= 1 then
        -- Use 90 degrees if out of range
        pitch = copysign(math.pi / 2, sinp)
    else
        pitch = math.asin(sinp)
    end

    -- Yaw (z-axis rotation)
    local siny_cosp = 2 * (w * z + x * y)
    local cosy_cosp = 1 - 2 * (y * y + z * z)
    local yaw = math.atan2(siny_cosp, cosy_cosp)

    return yaw, pitch, roll
end

local function RotateVectorByQuaternion(v, q)
    local s = q[1]
    local u = Vector({q[2], q[3], q[4]})

    local dot = u:dot(v)
    local cross = u:cross(v)

    local a = s * s - (u[1] * u[1] + u[2] * u[2] + u[3] * u[3])

    return Vector({
        v[1] * a + 2 * (dot * u[1] + s * cross[1]),
        v[2] * a + 2 * (dot * u[2] + s * cross[2]),
        v[3] * a + 2 * (dot * u[3] + s * cross[3])
    })
end

local function Sum(q1, q2)
    return {
        q1[1] + q2[1],
        q1[2] + q2[2],
        q1[3] + q2[3],
        q1[4] + q2[4],
    }
end

-- ----------------------------------------------------------------------------

LibImplex = LibImplex or {}

LibImplex.Vector = Vector

LibImplex.Q = {
    FromEuler = FromEuler,
    ToEuler = ToEuler,
    RotateVectorByQuaternion = RotateVectorByQuaternion,
    Sum = Sum,
}
