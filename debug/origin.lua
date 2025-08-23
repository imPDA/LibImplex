local originObjects = LibImplex.Marker('origin')
local TEXTURE = '/LibImplex/textures/arrow256x256.dds'

local HALF_PI = math.pi * 0.5
local SIZE = {1, 1.5}
local O = {0, 0, 0}

local RED = {1, 0, 0}
local GREEN = {0, 1, 0}
local BLUE = {0, 0, 1}
-- ----------------------------------------------------------------------------

local function updateX(marker, distance, prwX, prwY, prwZ, fX, fY, fZ, rX, rY, rZ, uX, uY, uZ)
    marker:Move({prwX + 200, prwY + 100, prwZ})
end

local function updateY(marker, distance, prwX, prwY, prwZ, fX, fY, fZ, rX, rY, rZ, uX, uY, uZ)
    marker:Move({prwX, prwY + 300, prwZ})

    marker.control:Set3DRenderSpaceForward(fX, fY, fZ)
    marker.control:Set3DRenderSpaceRight(rX, rY, rZ)
end

local function updateZ(marker, distance, prwX, prwY, prwZ, fX, fY, fZ, rX, rY, rZ, uX, uY, uZ)
    marker:Move({prwX, prwY + 100, prwZ + 200})
end

-- ----------------------------------------------------------------------------

local ORIGIN = {}

local function DeleteOrigin()
    for i = 1, #ORIGIN do
        ORIGIN[i]:Delete()
        ORIGIN[i] = nil
    end
end

function LibImplex_ShowOrigin()
    DeleteOrigin()

    ORIGIN[1] = originObjects._3D(O, {0, HALF_PI, -HALF_PI, true},  TEXTURE, SIZE, RED, updateX)
    ORIGIN[2] = originObjects._3D(O, {0, 0, 0, true},               TEXTURE, SIZE, GREEN, updateY)
    ORIGIN[3] = originObjects._3D(O, {HALF_PI, 0, 0, true},         TEXTURE, SIZE, BLUE, updateZ)
end

LibImplex_HideOrigin = DeleteOrigin
