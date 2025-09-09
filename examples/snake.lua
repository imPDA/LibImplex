local snakeObjects = LibImplex.Marker('snakeExample')

local Q = LibImplex.Q
local Rotate = Q.RotateVectorByQuaternion
local HALF_PI = math.pi * 0.5

-- ----------------------------------------------------------------------------

local Cube = LibImplex.class()

function Cube:__init(position, orientation, size, color)
    self.position = LibImplex.Vector(position)
    self.orientation = orientation

    self.orientation[4] = true

    self.size = size
    self.color = color

    self.Q = Q.FromEuler(unpack(orientation))

    self.upOrientation = {Q.ToEuler(Q.FromEuler(HALF_PI, 0, 0) * self.Q)}
    self.rightOrientation = {Q.ToEuler(Q.FromEuler(0, HALF_PI, 0) * self.Q)}

    self.upOrientation[4] = true
    self.rightOrientation[4] = true

    self.F = Rotate({0, 0, 1}, self.Q)
    self.U = Rotate({0, 1, 0}, self.Q)
    self.R = Rotate({1, 0, 0}, self.Q)

    self.objects = {}
    self:Draw()
end

function Cube:Draw()
    local halfSize = self.size * 0.5 * 100

    self.objects[1] = snakeObjects._3D(
        self.position + self.F * halfSize,
        self.orientation,
        nil,
        {self.size, self.size},
        {0, 1, 0}
    )

    self.objects[2] = snakeObjects._3D(
        self.position - self.F * halfSize,
        self.orientation,
        nil,
        {self.size, self.size},
        self.color
    )

    self.objects[3] = snakeObjects._3D(
        self.position + self.U * halfSize,
        self.upOrientation,
        nil,
        {self.size, self.size},
        {0, 1, 0}
    )

    self.objects[4] = snakeObjects._3D(
        self.position - self.U * halfSize,
        self.upOrientation,
        nil,
        {self.size, self.size},
        self.color
    )

    self.objects[5] = snakeObjects._3D(
        self.position + self.R * halfSize,
        self.rightOrientation,
        nil,
        {self.size, self.size},
        {0, 1, 0}
    )

    self.objects[6] = snakeObjects._3D(
        self.position - self.R * halfSize,
        self.rightOrientation,
        nil,
        {self.size, self.size},
        self.color
    )

    -- self:DrawNormals()
end

function Cube:DrawNormals()
    for i = 1, #self.objects do
        self.objects[i]:DrawNormal()
    end
end

function Cube:Clear()
    for i = 1, #self.objects do
        self.objects[i]:Delete()
        self.objects[i] = nil
    end
end

function Cube:SetColor(color)
    self.color = color

    for i = 1, #self.objects do
        self.objects[i]:SetColor(unpack(color))
    end
end

local function snakeExample()
    local startPosition = LibImplex.Vector({5230, 13460, 155820})
    local f = LibImplex.Vector({0, 0, 60})
    local s = LibImplex.Vector({60, 0, 0})

    local changes = {
        {0, 0},
        {1, 0},
        {1, 0},
        {1, 0},
        {0, 1},
        {1, 0},
        {1, 0},
        {0, -1},
        {0, -1},
        {0, -1},
        {0, -1},
        {1, 0},
        {1, 0},
        {1, 0},
        {1, 0},
        {0, 1},
        {0, 1},
        {0, 1},
        {0, 1},
        {0, 1},
        {0, 1},
    }

    local position = startPosition

    local body = {}
    for i = 1, #changes do
        position = position + f * changes[i][1] + s * changes[i][2]
        body[i] = Cube(
            position,  -- position in 3D {x, y, z}
            {0, 0, 0},  -- orientation {yaw, pitch, roll}
            0.5,  -- size in meters
            {50 / 255, 200 / 255, 50 / 255}  -- color {r, g, b, a}
        )
    end

    body[1]:SetColor({50 / 255, 150 / 255, 0})
end


do
    EVENT_MANAGER:RegisterForEvent('LIB_IMPLEX_EXAMPLES_SNAKE', EVENT_PLAYER_ACTIVATED, snakeExample)
end
