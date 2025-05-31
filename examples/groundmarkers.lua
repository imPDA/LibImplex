-- Go to Summerset, Alinor Wayshrine

local PI = math.pi

local Vector = LibImplex.Vector

local TEXTURES = LibImplex.Textures.Numbers
local ZONE_ID = 1011

local MARKER_POSITIONS = {
    --[[0]] {163311, 18355, 331544},
    --[[1]] {163555, 18355, 332016},
    --[[2]] {163799, 18355, 332488},
    --[[3]] {164043, 18355, 332960},
    --[[4]] {164287, 18355, 333432},
    --[[5]] {162877, 18355, 331769},
    --[[6]] {163121, 18355, 332241},
    --[[7]] {163365, 18355, 332713},
    --[[8]] {163609, 18355, 333185},
    --[[9]] {163853, 18355, 333657},
}

local TEXT_POSITION = Vector({164664, 18740, 336661})

local COLOR = {173 / 255, 216 / 255, 230 / 255}  -- #add8e6

local function placeMarkers()
    if GetZoneId(GetUnitZoneIndex('player')) ~= ZONE_ID then return end

    local ORIENTATION = {-PI * 0.5, -PI * 0.36, 0, true}
    for i = 1, #MARKER_POSITIONS do
        local m = LibImplex.Marker._3DStatic(
            MARKER_POSITIONS[i],
            ORIENTATION,
            TEXTURES[i-1],
            {1.5, 1.5},  -- size (x1.5)
            COLOR
        )

        m.control:SetGradientColors(ORIENTATION_VERTICAL, 0, 1, 0, 1, 1, 0, 1, 1)
        m.control:SetPixelRoundingEnabled()
    end

    local LOREM_IPSUM = 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Praesent sed lorem dapibus orci ultricies laoreet vel a lectus. Donec hendrerit malesuada convallis. Morbi congue elit at ipsum finibus feugiat. Morbi eget ex in massa vulputate semper quis eu sem. In pretium, ipsum eu ornare placerat, risus ante tincidunt turpis, vitae semper justo turpis nec diam. Etiam tellus eros, accumsan in vehicula vel, mollis quis ex. Donec luctus laoreet lacus in pellentesque.'

    -- local someText = LibImplex.String(LOREM_IPSUM)
    -- someText:Render(TOPLEFT, TEXT_POSITION, {0.2, 0.938 * PI, 0.1, true}, 1, COLOR)

    local someText2 = LibImplex.Text(LOREM_IPSUM)
    someText2:Render(TOPLEFT, TEXT_POSITION + LibImplex.Vector({0.5, 6000, 0}), {PI / 3, 0.938 * PI, 0, true}, 1.7, COLOR, 3500)

    --[[
    local USE_BUFFER = true

	local M1 = {162864, 18500, 333339}
	local M2 = {162550, 18500, 332985}
	local M3 = {162180, 18500, 332560}

    LibImplex.Marker.Marker3D(M1, {0, 0, 0, USE_BUFFER}, TEXTURES[1], {3, 3}, COLOR)
    LibImplex.Marker.Marker3D(M2, {0, 0, 0, USE_BUFFER}, TEXTURES[2], {3, 3}, COLOR)
    LibImplex.Marker.Marker3D(M3, {0, 0, 0, USE_BUFFER}, TEXTURES[3], {3, 3}, COLOR)
    --]]

    local bank = LibImplex.Text('Bank')
    bank:Render(TOPLEFT, {162260, 18608, 330059}, {-0.5 * PI, -0.15 * PI, 0, true}, 1, COLOR)

    local respec = LibImplex.Text('Respec')
    respec:Render(TOPLEFT, {159998, 18420, 331774}, {-0.5 * PI, 0.44 * PI, 0, true}, 1, COLOR)
end

do
    EVENT_MANAGER:RegisterForEvent('LIB_IMPLEX_EXAMPLES_GROUNDMARKERS_SUMMERSET', EVENT_PLAYER_ACTIVATED, placeMarkers)
end