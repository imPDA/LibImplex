local Text = LibImplex.class()
Text.__index = Text

function Text:__init(text, anchorPoint, position, orientation, size, color, maxWidth)
    self.text = text
    self.objects = {}

    self.anchorPoint = anchorPoint or TOPLEFT
    self.position = position or {select(2, GetUnitRawWorldPosition('player'))}
    self.size = size or 1
    self.color = color or {1, 1, 1}
    self.maxWidth = maxWidth

    self:Orient(orientation or {0, 0, 0})
end

local TEXTURE = LibImplex.Textures.Alphabet.texture
local LETTER_SPACING = 5
local SPACE_WIDTH = 40

function Text:SplitToRows()
    local spaceWidth = SPACE_WIDTH * self.size
    local letterSpacing = LETTER_SPACING * self.size

    self.rows = {}

    local splittedText = self.text:gmatch('([^\n]*)\n?')

    local currentRowWidth = 0
    local currentRow = {}
    local wordCounter = 0

    for textPart in splittedText do
        for word in textPart:gmatch('%S+') do
            df('word: %s', word)
            local wordLength = #word
            local wordWidth = 0

            for i = 1, wordLength do
                local letter = word:sub(i, i)
                local w, h = LibImplex.Textures.Alphabet.GetSizeCoefficients(letter, self.size)

                wordWidth = wordWidth + w * 100
            end

            wordWidth = wordWidth + letterSpacing * (wordLength - 1)

            if self.maxWidth and (currentRowWidth + wordWidth + spaceWidth > self.maxWidth) then
                self.rows[#self.rows+1] = {table.concat(currentRow, ' ', 1, wordCounter), currentRowWidth}
                wordCounter = 1
                currentRow[wordCounter] = word
                currentRowWidth = wordWidth
            else
                wordCounter = wordCounter + 1
                currentRow[wordCounter] = word
                currentRowWidth = currentRowWidth + wordWidth + spaceWidth
            end
        end

        if wordCounter > 0 then
            self.rows[#self.rows+1] = {table.concat(currentRow, ' ', 1, wordCounter), currentRowWidth}
            wordCounter = 0
            currentRowWidth = 0
        end
    end
end

function Text:RenderRow(index, position)
    local spaceWidth = SPACE_WIDTH * self.size
    local letterSpacing = LETTER_SPACING * self.size

    local row = self.rows[index][1]
    local rowLength = #row

    local RIGHT = self.right

    local cursor = position

    for i = 1, rowLength do
        local letter = row:sub(i, i)

        if letter == ' ' then
            cursor = cursor + RIGHT * spaceWidth
        else
            local w, h = LibImplex.Textures.Alphabet.GetSizeCoefficients(letter, self.size)

            cursor = cursor + RIGHT * w * 50

            local letterObject = LibImplex.Marker._3DStatic(cursor, self.orientation, TEXTURE, {w, h}, self.color)
            letterObject.control:SetTextureCoords(LibImplex.Textures.Alphabet.GetCharacterCoordinates(letter))
            letterObject.control:SetDrawLevel(self.drawLevel)
            letterObject.width = w
            letterObject.height = h

            cursor = cursor + RIGHT * w * 50

            if i < rowLength then
                cursor = cursor + RIGHT * letterSpacing
            end

            self.objects[#self.objects+1] = letterObject
        end
    end
end

local ALLOWED_ANCHOR_POINTS = {
    [TOPLEFT] = true,
    [TOP] = true,
}

function Text:Render()
    self:Wipe()

    local RIGHT = self.right
    local UP = self.up

    local W, H = LibImplex.Textures.Alphabet.GetSizeCoefficients(self.text:sub(1, 1), self.size)

    local START_POSITION = self.position - UP * H * 50  -- + RIGHT * W * 50

    H = H * 100

    self:SplitToRows()
    for i = 1, #self.rows do
        if self.anchorPoint == TOPLEFT then
            self:RenderRow(i, START_POSITION - UP * ((i-1) * H))
        elseif self.anchorPoint == TOP then
            self:RenderRow(i, START_POSITION - UP * ((i-1) * H) - RIGHT * (self.rows[i][2] * 0.5))
        end
    end
end

function Text:Rerender()
    if #self.objects > 0 then
        self:Render()
    end
end

function Text:Anchor(anchorPoint, position)
    assert(ALLOWED_ANCHOR_POINTS[anchorPoint], 'Bad anchor point')

    self.anchorPoint = anchorPoint
    self.position = position

    self:Rerender()
end

function Text:SetSize(size)
    self.size = size

    self:Rerender()
end

function Text:SetDrawLevel(drawLevel)
    self.drawLevel = drawLevel

    self:Rerender()
end

function Text:Orient(orientation)
    self.orientation = orientation

    local Q = LibImplex.Q.FromEuler(orientation[3], orientation[2], orientation[1])
    local RIGHT = LibImplex.Q.RotateVectorByQuaternion({1, 0, 0}, Q)
    local UP = LibImplex.Q.RotateVectorByQuaternion({0, 1, 0}, Q)
    local FORWARD = LibImplex.Q.RotateVectorByQuaternion({0, 0, 1}, Q)

    self.q = Q
    self.right = RIGHT
    self.up = UP
    self.f = FORWARD

    self:Rerender()
end

function Text:SetAlpha(alpha)
    self.alpha = alpha

    local objects = self.objects
    for i = 1, #objects do
        objects[i].control:SetAlpha(alpha)
    end
end

function Text:SetColor(color)
    self.color = color

    local objects = self.objects
    for i = 1, #objects do
        objects[i].control:SetColor(unpack(color))
    end
end

function Text:SetMaxWidth(maxWidth)
    self.maxWidth = maxWidth

    self:Rerender()
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
