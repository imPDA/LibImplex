local utf8len = utf8.len
local utf8off = utf8.offset

local Q = LibImplex.Q

local writingContext = LibImplex.Marker('writing')

local TOPLEFT       = TOPLEFT
local TOP           = TOP
local TOPRIGHT      = TOPRIGHT
local LEFT          = LEFT
local CENTER        = CENTER
local RIGHT         = RIGHT
local BOTTOMLEFT    = BOTTOMLEFT
local BOTTOM        = BOTTOM
local BOTTOMRIGHT   = BOTTOMRIGHT

-- ----------------------------------------------------------------------------

local Font = LibImplex.class()

function Font:__init(name, ...)
    self.name = name

    self._coordinates = {}
    self._paths = {}
    self._widthToHeight = {}

    for _, language in pairs({...}) do
        local textureSize = language.fullSize
        local texturePath = language.path

        for letter, c in pairs(language.characterCoordinates) do
            self._coordinates[letter] = {
                c[1] / textureSize,
                c[2] / textureSize,
                c[3] / textureSize,
                c[4] / textureSize,
            }
            self._paths[letter] = texturePath
            self._widthToHeight[letter] = (c[2] - c[1]) / (c[4] - c[3])
        end
    end
end

function Font:Get(letter, size)
    return self._paths[letter], self._widthToHeight[letter] * size, size, unpack(self._coordinates[letter])
end
local Univers67 = Font('Univers 67', LibImplex.Textures.Alphabet.UNIVERS67.EN, LibImplex.Textures.Alphabet.UNIVERS67.RU)
local _Monospace = Font('_Monospace', LibImplex.Textures.Alphabet.UNIVERS67.MONOSPACE)

LibImplex.Fonts = {
    Univers67 = Univers67,
    _Monospace = _Monospace,
}

-- ----------------------------------------------------------------------------

local Text = LibImplex.class()

local Object = writingContext._3D
local StaticObject = writingContext._3DStatic
Text.OBJECT_FACTORIES = {
    Object = Object,
    StaticObject = StaticObject,
}

function Text:__init(text, anchorPoint, position, orientation, size, color, maxWidth, enableOutline, objectFactory, font)
    self.text = text
    self.objects = {}

    self.anchorPoint = anchorPoint or TOPLEFT
    self.position = position or {select(2, GetUnitRawWorldPosition('player'))}
    self.size = size or 1
    self.color = color or {1, 1, 1}
    self.maxWidth = maxWidth

    self:Orient(orientation or {0, 0, 0})

    self.enableOutline = enableOutline
    self.outline = {}

    self.objectFactory = objectFactory or StaticObject
    self.font = font or Univers67
end

local LETTER_SPACING = 5
local SPACE_WIDTH = 30

-- local function splitToChars(word)
--     local chars = {}

--     local previousOffset = 1
--     for i = 1, utf8len(word) do
--         local offset = utf8off(word, i+1)
--         local letter = word:sub(previousOffset, offset-1)
--         previousOffset = offset
--         chars[i] = letter
--     end

--     return chars
-- end

local function splitToChars(s)
    local chars = {}
    local i = 1
    local len = #s

    while i <= len do
        local byte = s:byte(i)
        local char_len = 1

        if byte >= 0x00 and byte <= 0x7F then
            char_len = 1
        elseif byte >= 0xC2 and byte <= 0xDF then
            char_len = 2
        elseif byte >= 0xE0 and byte <= 0xEF then
            char_len = 3
        elseif byte >= 0xF0 and byte <= 0xF4 then
            char_len = 4
        end

        if i + char_len - 1 > len then
            char_len = 1
        end

        local char = s:sub(i, i + char_len - 1)
        table.insert(chars, char)

        i = i + char_len
    end

    -- d({s:byte(1, #s)})
    -- d(chars)
    -- d('------------')

    return chars
end

function Text:SplitToRows()
    local spaceWidth = SPACE_WIDTH * self.size
    local letterSpacing = LETTER_SPACING * self.size

    self.rows = {}

    local splittedText = self.text:gmatch('([^\n]*)\n?')

    local currentRowWidth = 0
    local words = {}

    for textPart in splittedText do
        -- for word in textPart:gmatch('%S+') do
        for word in textPart:gmatch('([^ ]+)') do
            local chars = splitToChars(word)

            local wordLength = #chars
            local wordWidth = 0

            for i = 1, wordLength do
                local texture, w, h, left, right, top, bottom = self.font:Get(chars[i], self.size)
                wordWidth = wordWidth + w * 100
            end

            wordWidth = wordWidth + letterSpacing * (wordLength - 1)

            if self.maxWidth and (currentRowWidth + wordWidth + spaceWidth > self.maxWidth) then
                if #words > 0 then
                    self.rows[#self.rows+1] = {words, currentRowWidth}

                    words = {chars, }
                    currentRowWidth = wordWidth
                else
                    self.rows[#self.rows+1] = {{chars}, wordWidth}
                    currentRowWidth = 0
                end
            else
                words[#words+1] = chars
                currentRowWidth = currentRowWidth + wordWidth

                if #words > 1 then
                    currentRowWidth = currentRowWidth + spaceWidth
                end
            end
        end

        if #words > 0 then
            self.rows[#self.rows+1] = {words, currentRowWidth}
            words = {}
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

    local objectFactory = self.objectFactory
    for i = 1, rowLength do
        local word = row[i]
        local wordLength = #word

        for j = 1, wordLength do
            local texture, w, h, left, right, top, bottom = self.font:Get(word[j], self.size)

            cursor = cursor + r * w * 50

            local letterObject = objectFactory(cursor, self.orientation, texture, {w, h}, self.color)
            letterObject:SetTextureCoords(left, right, top, bottom)
            letterObject:SetDrawLevel(self.drawLevel)
            letterObject.width = w
            letterObject.height = h

            -- TODO: add function to draw normal for text object, not for each letter separately
            -- letterObject:DrawNormal(300)

            cursor = cursor + r * w * 50

            if i < wordLength then
                cursor = cursor + r * letterSpacing
            end

            self.objects[#self.objects+1] = letterObject
        end

        if i < rowLength then
            cursor = cursor + r * spaceWidth
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
    self.rowHeight = self.size * 100  -- TODO: move to new place since font simplified things a bit

    local r = self.R
    local u = self.U

    local RH = self.rowHeight

    self:SplitToRows()

    local START_POSITION = self.position - u * RH * 0.5  -- + RIGHT * W * 50

    if self.anchorPoint == CENTER then
        START_POSITION = START_POSITION + u * RH * #self.rows * 0.5
    end

    for i = 1, #self.rows do
        if self.anchorPoint == TOPLEFT then
            self:RenderRow(i, START_POSITION - u * ((i-1) * RH))
        elseif self.anchorPoint == TOP or self.anchorPoint == CENTER then
            self:RenderRow(i, START_POSITION - u * ((i-1) * RH) - r * (self.rows[i][2] * 0.5))
        elseif self.anchorPoint == LEFT then
            self:RenderRow(i, START_POSITION + u * RH * 0.5)
        elseif self.anchorPoint == RIGHT then
            self:RenderRow(i, START_POSITION + u * RH * 0.5 - r * (self.rows[i][2]))
        elseif self.anchorPoint == BOTTOM then
            self:RenderRow(i, START_POSITION + u * RH - r * (self.rows[i][2] * 0.5))
        end
    end

    if self.enableOutline then
        self:Outline()
    end
end

function Text:Outline()
    self:RemoveOutline()

    local tl = self:GetRelativePointCoordinates(TOPLEFT)
    local tr = self:GetRelativePointCoordinates(TOPRIGHT)
    local br = self:GetRelativePointCoordinates(BOTTOMRIGHT)
    local bl = self:GetRelativePointCoordinates(BOTTOMLEFT)

    self.outline[1] = LibImplex.Lines.Line(tl, tr)
    self.outline[2] = LibImplex.Lines.Line(tr, br)
    self.outline[3] = LibImplex.Lines.Line(br, bl)
    self.outline[4] = LibImplex.Lines.Line(bl, tl)
end

function Text:RemoveOutline()
    for i = 1, #self.outline do
        self.outline[i]:Delete()
        self.outline[i] = nil
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
    -- TODO: recheck if I can do something with it
    self.orientation = {orientation[3], orientation[2], orientation[1], orientation[4]}

    local q = Q.FromEuler(unpack(self.orientation))

    self.R = Q.RotateVectorByQuaternion({1, 0, 0}, q)
    self.U = Q.RotateVectorByQuaternion({0, 1, 0}, q)
    self.F = Q.RotateVectorByQuaternion({0, 0, 1}, q)

    self:Rerender()
end

function Text:SetAlpha(alpha)
    self.alpha = alpha

    local objects = self.objects
    for i = 1, #objects do
        objects[i]:SetAlpha(alpha)
    end
end

function Text:SetColor(color)
    self.color = color

    local objects = self.objects
    for i = 1, #objects do
        objects[i]:SetColor(unpack(color))
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

    self:RemoveOutline()
end

function Text:GetMaxRowWidth()
    if #self.rows < 1 then return 0 end

    local maxRowWidth = 0

    for rowIndex = 1, #self.rows do
        local row = self.rows[rowIndex]

        if row[2] > maxRowWidth then
            maxRowWidth = row[2]
        end
    end

    return maxRowWidth
end

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
    offsetRight = offsetRight or 0
    offsetUp = offsetUp or 0
    offsetForward = offsetForward or 0

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
