local Object = LibImplex.Marker._3DStatic
local GetLetterSizeCoefficients = LibImplex.Textures.Alphabet.GetSizeCoefficients
local GetLetterCoordinates = LibImplex.Textures.Alphabet.GetCharacterCoordinates
local Q = LibImplex.Q

local TOPLEFT       = TOPLEFT
local TOP           = TOP
local TOPRIGHT      = TOPRIGHT
local LEFT          = LEFT
local CENTER        = CENTER
local RIGHT         = RIGHT
local BOTTOMLEFT    = BOTTOMLEFT
local BOTTOM        = BOTTOM
local BOTTOMRIGHT   = BOTTOMRIGHT

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
            local wordLength = #word
            local wordWidth = 0

            for i = 1, wordLength do
                local letter = word:sub(i, i)
                local w, h = GetLetterSizeCoefficients(letter, self.size)

                wordWidth = wordWidth + w * 100
            end

            wordWidth = wordWidth + letterSpacing * (wordLength - 1)

            if self.maxWidth and (currentRowWidth + wordWidth + spaceWidth > self.maxWidth) then
                if wordCounter > 0 then
                    self.rows[#self.rows+1] = {table.concat(currentRow, ' ', 1, wordCounter), currentRowWidth}
                    wordCounter = 1
                    currentRow[wordCounter] = word
                    currentRowWidth = wordWidth
                else
                    self.rows[#self.rows+1] = {word, wordWidth}
                    wordCounter = 0
                    currentRowWidth = 0
                end
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

    local r = self.R

    local cursor = position

    for i = 1, rowLength do
        local letter = row:sub(i, i)

        if letter == ' ' then
            cursor = cursor + r * spaceWidth
        else
            local w, h = GetLetterSizeCoefficients(letter, self.size)

            cursor = cursor + r * w * 50

            local letterObject = Object(cursor, self.orientation, TEXTURE, {w, h}, self.color)
            letterObject.control:SetTextureCoords(GetLetterCoordinates(letter))
            letterObject.control:SetDrawLevel(self.drawLevel)
            letterObject.width = w
            letterObject.height = h

            cursor = cursor + r * w * 50

            if i < rowLength then
                cursor = cursor + r * letterSpacing
            end

            self.objects[#self.objects+1] = letterObject
        end
    end
end

local ALLOWED_ANCHOR_POINTS = {
    [TOPLEFT] = true,
    [TOP] = true,
    [CENTER] = true,
}

function Text:Render()
    self:Wipe()

    local r = self.R
    local u = self.U

    local W, H = GetLetterSizeCoefficients(self.text:sub(1, 1), self.size)

    H = H * 100
    self.rowHeight = H

    self:SplitToRows()

    local START_POSITION = self.position - u * H * 0.5  -- + RIGHT * W * 50

    if self.anchorPoint == CENTER then
        START_POSITION = START_POSITION + u * H * #self.rows * 0.5
    end

    for i = 1, #self.rows do
        if self.anchorPoint == TOPLEFT then
            self:RenderRow(i, START_POSITION - u * ((i-1) * H))
        elseif self.anchorPoint == TOP or self.anchorPoint == CENTER then
            self:RenderRow(i, START_POSITION - u * ((i-1) * H) - r * (self.rows[i][2] * 0.5))
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

    local q = Q.FromEuler(orientation[3], orientation[2], orientation[1])

    self.R = Q.RotateVectorByQuaternion({1, 0, 0}, q)
    self.U = Q.RotateVectorByQuaternion({0, 1, 0}, q)
    self.F = Q.RotateVectorByQuaternion({0, 0, 1}, q)

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

function Text:GetMaxRowWidth()
    if #self.rows < 1 then return 0 end

    local maxRowWidth = math.huge

    for rowIndex = 1, #self.rows do
        local row = self.rows[rowIndex]

        if row[2] < maxRowWidth then
            maxRowWidth = row[2]
        end
    end

    return maxRowWidth
end

--[[
function Text:GetRelativePointCoordinates(anchorPoint, offsetRight, offsetUp, offsetForward)
    local width = self:GetMaxRowWidth()
    local height = self.rowHeight * #self.rows

    if self.anchorPoint == TOP then
        if anchorPoint == TOPRIGHT then
            return self.position + self.R * (width * 0.5 + offsetRight) + self.U * (offsetUp) + self.F * (offsetForward)
        elseif anchorPoint == RIGHT then
            return self.position + self.R * (width * 0.5 + offsetRight) + self.U * (-height * 0.5 + offsetUp) + self.F * (offsetForward)
        elseif anchorPoint == BOTTOMRIGHT then
            return self.position + self.R * (width * 0.5 + offsetRight) + self.U * (-height + offsetUp) + self.F * (offsetForward)
        elseif anchorPoint == TOP then
            return self.position + self.R * (offsetRight) + self.U * (offsetUp) + self.F * (offsetForward)
        elseif anchorPoint == CENTER then
            return self.position + self.R * (offsetRight) + self.U * (-height * 0.5 + offsetUp) + self.F * (offsetForward)
        elseif anchorPoint == BOTTOM then
            return self.position + self.R * (offsetRight) + self.U * (-height + offsetUp) + self.F * (offsetForward)
        elseif anchorPoint == TOPLEFT then
            return self.position + self.R * (-width * 0.5 + offsetRight) + self.U * (offsetUp) + self.F * (offsetForward)
        elseif anchorPoint == LEFT then
            return self.position + self.R * (-width * 0.5 + offsetRight) + self.U * (-height * 0.5 + offsetUp) + self.F * (offsetForward)
        elseif anchorPoint == BOTTOMLEFT then
            return self.position + self.R * (-width * 0.5 + offsetRight) + self.U * (-height + offsetUp) + self.F * (offsetForward)
        else
            error('Wrong anchor point')
        end
    else
        error('Not implemented')
    end
end
--]]

local function getShift(anchor)
    -- center => anchor

    local right, up = 0, 0

    if     anchor == TOPLEFT     then  right = -0.5 up = 0.5
    elseif anchor == TOP         then  right = 0    up = 0.5
    elseif anchor == TOPRIGHT    then  right = 0.5  up = 0.5
    elseif anchor == LEFT        then  right = -0.5 up = 0
    elseif anchor == CENTER      then  right = 0    up = 0
    elseif anchor == RIGHT       then  right = 0.5  up = 0
    elseif anchor == BOTTOMLEFT  then  right = -0.5 up = -0.5
    elseif anchor == BOTTOM      then  right = 0    up = -0.5
    elseif anchor == BOTTOMRIGHT then  right = 0.5  up = -0.5
    else
        error('Bad anchor')
    end

    return right, up
end

function Text:GetRelativePointCoordinates(anchorPoint, offsetRight, offsetUp, offsetForward)
    local baseRight, baseUp = getShift(self.anchorPoint)
    local targetRight, targetUp = getShift(anchorPoint)

    local width = self:GetMaxRowWidth()
    local height = self.rowHeight * #self.rows

    local totalRight = (targetRight - baseRight) * width + offsetRight
    local totalUp = (targetUp - baseUp) * height + offsetUp

    return self.position + self.R * totalRight + self.U * totalUp + self.F * offsetForward
end

Text.Delete = Text.Wipe

-- ----------------------------------------------------------------------------

LibImplex = LibImplex or {}
LibImplex.Text = Text
