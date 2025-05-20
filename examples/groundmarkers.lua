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
        LibImplex.Marker.Marker3D(
            MARKER_POSITIONS[i],
            ORIENTATION,
            TEXTURES[i-1],
            {1.5, 1.5},  -- size (x1.5)
            COLOR
        )
    end

    local someText = LibImplex.String('lorem ipsum')
    someText:Render(TEXT_POSITION, {0, 0.938 * PI, 0, true}, 1, COLOR)

    --[[
    local USE_BUFFER = true

	local M1 = {162864, 18500, 333339}
	local M2 = {162550, 18500, 332985}
	local M3 = {162180, 18500, 332560}

    LibImplex.Marker.Marker3D(M1, {0, 0, 0, USE_BUFFER}, TEXTURES[1], {3, 3}, COLOR)
    LibImplex.Marker.Marker3D(M2, {0, 0, 0, USE_BUFFER}, TEXTURES[2], {3, 3}, COLOR)
    LibImplex.Marker.Marker3D(M3, {0, 0, 0, USE_BUFFER}, TEXTURES[3], {3, 3}, COLOR)
    --]]

    local bank = LibImplex.String('bank')
    bank:Render({162260, 18608, 330059}, {-0.5 * PI, -0.15 * PI, 0, true}, 1, COLOR)

    local respec = LibImplex.String('respec')
    respec:Render({159998, 18420, 331774}, {-0.5 * PI, 0.44 * PI, 0, true}, 1, COLOR)
end

do
    EVENT_MANAGER:RegisterForEvent('LIB_IMPLEX_EXAMPLES_GROUNDMARKERS_SUMMERSET', EVENT_PLAYER_ACTIVATED, placeMarkers)
end