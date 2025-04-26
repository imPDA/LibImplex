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

LibImplex = LibImplex or {}
LibImplex.Textures = LibImplex.Textures or {}

LibImplex.Textures.Numbers = NUMBER_TEXTURES
