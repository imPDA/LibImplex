local Log = LibImplex_Logger()

local sub = string.sub
local PI = math.pi

local ROOT = 'LibImplex/textures'

local NUMBER_TEXTURES = {
    'one', 'two', 'three', 'four', 'five', 'six', 'seven', 'eight', 'nine', [0] = 'zero'
}

do
    for i, textureName in pairs(NUMBER_TEXTURES) do
        NUMBER_TEXTURES[i] = string.format('%s/%s.dds', ROOT, textureName)
    end
end

-- ----------------------------------------------------------------------------

local SCALE_FACTOR = 75
local ALPHABET = {
    path='LibImplex/textures/sansserif100.dds',
    characterCoordinates = {
        ['a'] = {  7,  55,   0, 122},
        ['b'] = { 71, 122,   0, 122},
        ['c'] = {129, 175,   0, 122},
        ['d'] = {181, 231,   0, 122},
        ['e'] = {243, 294,   0, 122},
        ['f'] = {302, 338,   0, 122},
        ['g'] = {338, 389,   0, 122},
        ['h'] = {404, 452,   0, 122},
        ['i'] = {466, 479,   0, 122},

        ['j'] = {  0,  30, 122, 244},
        ['k'] = { 45,  96, 122, 244},
        ['l'] = {104, 115, 122, 244},
        ['m'] = {131, 213, 122, 244},
        ['n'] = {228, 276, 122, 244},
        ['o'] = {287, 341, 122, 244},
        ['p'] = {352, 403, 122, 244},
        ['q'] = {411, 461, 122, 244},

        ['r'] = { 11,  48, 244, 366},
        ['s'] = { 52,  96, 244, 366},
        ['t'] = {100, 136, 244, 366},
        ['u'] = {144, 193, 244, 366},
        ['v'] = {203, 257, 244, 366},
        ['w'] = {262, 338, 244, 366},
        ['x'] = {343, 398, 244, 366},
        ['y'] = {403, 458, 244, 366},
        ['z'] = {463, 509, 244, 366},

        [' '] = {7, 55, 366, 488},
    },
    fullSize = 512,
}

-- ----------------------------------------------------------------------------

local String = LibImplex.class()
String.__index = String

function String:__init(string)
    self.text = string:lower()
    self.objects = {}
end

function String:Render(position, orientation, size, color)
    self:Wipe()

    local pos = LibImplex.Vector(position)

    local lastPlacedObject = nil
    local TEXTURE = LibImplex.Textures.Alphabet.texture
    local Q = LibImplex.Q.FromEuler(orientation[3], orientation[2], orientation[1])
    local DIRECTION

    for i = 1, #self.text do
        local character = sub(self.text, i, i)
        Log('Placing `%s`', character)
        local w, h = LibImplex.Textures.Alphabet.GetSizeCoefficients(character, size)

        if lastPlacedObject then
            DIRECTION = LibImplex.Q.RotateVectorByQuaternion({lastPlacedObject.control:Get3DRenderSpaceRight()}, Q)
            pos = lastPlacedObject.position + DIRECTION * (lastPlacedObject.width + w) * 50
        end

        local object = LibImplex.Marker.Marker3D(pos, orientation, TEXTURE, {w, h}, color)
        object.control:SetTextureCoords(LibImplex.Textures.Alphabet.GetCharacterCoordinates(character))
        object.width = w
        object.height = h

        Log('Character placed at (%d, %d, %d)', object.position[1], object.position[2], object.position[3])

        lastPlacedObject = object
        self.objects[i] = object
    end
end

function String:Wipe()
    for i = 1, #self.objects do
        self.objects[i]:Delete()
        self.objects[i] = nil
    end
end

String.Delete = String.Wipe

-- ----------------------------------------------------------------------------

LibImplex = LibImplex or {}
LibImplex.Textures = LibImplex.Textures or {}

LibImplex.Textures.Numbers = NUMBER_TEXTURES

LibImplex.Textures.Alphabet = {
    texture = ALPHABET.path,
    GetCharacterCoordinates = function(character)
        local l, r, t, b = unpack(ALPHABET.characterCoordinates[character])
        local full = ALPHABET.fullSize

        return l/full, r/full, t/full, b/full
    end,
    GetSizeCoefficients = function(character, size)
        local l, r, t, b = unpack(ALPHABET.characterCoordinates[character])

        local w = size * (r - l) / SCALE_FACTOR
        local h = size * (b - t) / SCALE_FACTOR

        Log('%s - w: %.2f, h: %2.f', character, w, h)

        return w, h
    end,
}

LibImplex.String = String
