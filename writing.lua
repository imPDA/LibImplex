local sub = string.sub

-- ----------------------------------------------------------------------------

local Text = LibImplex.class()
Text.__index = Text

function Text:__init(text)
    self.text = text
    self.objects = {}
end

local TEXTURE = LibImplex.Textures.Alphabet.texture
local LETTER_SPACING = 5
local SPACE_WIDTH = 40

function Text:Render(anchorPoint, position, orientation, size, color, maxWidth)
    self:Wipe()

    local Q = LibImplex.Q.FromEuler(orientation[3], orientation[2], orientation[1])
    local RIGHT = LibImplex.Q.RotateVectorByQuaternion({1, 0, 0}, Q)
    local UP = LibImplex.Q.RotateVectorByQuaternion({0, 1, 0}, Q)
    -- local FORWARD = LibImplex.Q.RotateVectorByQuaternion({0, 0, 1}, Q)

    local cursor = LibImplex.Vector(position)

    local currentRowWidth = 0
    local previousRowStart = cursor

    local w, h

    for word in self.text:gmatch("%S+") do
        local wordLength = #word
        local wordWidth = 0

        for i = 1, wordLength do
            local letter = sub(word, i, i)
            w, h = LibImplex.Textures.Alphabet.GetSizeCoefficients(letter, size)

            wordWidth = wordWidth + w * 100
        end

        wordWidth = wordWidth + LETTER_SPACING * (wordLength - 1)

        if maxWidth and (currentRowWidth + wordWidth + SPACE_WIDTH > maxWidth) then
            cursor = previousRowStart - UP * h * 100
            previousRowStart = cursor
            currentRowWidth = wordWidth
        else
            currentRowWidth = currentRowWidth + wordWidth + SPACE_WIDTH
            cursor = cursor + RIGHT * SPACE_WIDTH
        end

        for i = 1, wordLength do
            local letter = sub(word, i, i)
            w, h = LibImplex.Textures.Alphabet.GetSizeCoefficients(letter, size)

            cursor = cursor + RIGHT * w * 50

            local letterObject = LibImplex.Marker._3DStatic(cursor, orientation, TEXTURE, {w, h}, color)
            letterObject.control:SetTextureCoords(LibImplex.Textures.Alphabet.GetCharacterCoordinates(letter))
            letterObject.width = w
            letterObject.height = h

            cursor = cursor + RIGHT * w * 50

            if i < wordLength then
                cursor = cursor + RIGHT * LETTER_SPACING
            end

            self.objects[i] = letterObject
        end
    end
end

function Text:Wipe()
    for i = 1, #self.objects do
        self.objects[i]:Delete()
        self.objects[i] = nil
    end
end

Text.Delete = Text.Wipe

-- ----------------------------------------------------------------------------

LibImplex = LibImplex or {}
LibImplex.Text = Text
