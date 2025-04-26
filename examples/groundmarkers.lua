-- Go to Summerset, Alinor Wayshrine

local PI = math.pi

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

local ORIENTATION = {-PI * 0.5, -PI * 0.36, 0, true}

local function placeMarkers()
    if GetZoneId(GetUnitZoneIndex('player')) ~= ZONE_ID then return end

    for i = 1, #MARKER_POSITIONS do
        LibImplex.Marker.Marker3D(
            MARKER_POSITIONS[i],
            ORIENTATION,
            TEXTURES[i-1],
            {1.5, 1.5},  -- size (x1.5)
            {173 / 255, 216 / 255, 230 / 255}  -- color, #add8e6
        )
    end
end

do
    EVENT_MANAGER:RegisterForEvent('LIB_IMPLEX_EXAMPLES_GROUNDMARKERS_SUMMERSET', EVENT_PLAYER_ACTIVATED, placeMarkers)
end