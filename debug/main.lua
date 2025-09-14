local TOP_LEVEL_CONTROL = LibImplex_DebugWindow
local TEXT = TOP_LEVEL_CONTROL:GetNamedChild('Text')

function LibImplex_ShowDebugWindow()
    TOP_LEVEL_CONTROL:SetHidden(false)

    EVENT_MANAGER:RegisterForUpdate('LibImplex_DebugWindow_Update', 1000/60, function()
        local text = ''

        local zoneIndex = GetUnitZoneIndex('player')
        local zoneName = GetZoneNameByIndex(zoneIndex)
        local zoneId = GetZoneId(zoneIndex)
        text = text .. ('%s (index: %d, ID: %d)\n'):format(zoneName, zoneIndex, zoneId)

        local _, prX, prY, prZ = GetUnitRawWorldPosition('player')
        text = text .. ('GetUnitRawWorldPosition: {%d, %d, %d}\n'):format(prX, prY, prZ)

        local _, pX, pY, pZ = GetUnitWorldPosition('player')
        text = text .. ('GetUnitWorldPosition: {%d, %d, %d}\n'):format(pX, pY, pZ)

        text = text .. ('Difference: {%d, %d, %d}\n'):format(prX - pX, prY - pY, prZ - pZ)

        local npX, npZ = GetNormalizedWorldPosition(zoneId, pX, pY, pZ)
        text = text .. ('GetNormalizedWorldPosition: {%.6f, %.6f}\n'):format(npX, npZ)

        local rnpX, rnpZ = GetRawNormalizedWorldPosition(zoneId, prX, prY, prZ)
        text = text .. ('GetRawNormalizedWorldPosition: {%.6f, %.6f}\n'):format(rnpX, rnpZ)

        local crsoX, crsoY, crsoZ = LibImplex_2DMarkers:Get3DRenderSpaceOrigin()
        text = text .. ('Camera render space origin: {%.6f, %.6f, %.6f}\n'):format(crsoX, crsoY, crsoZ)

        local crX, crY, crZ = GuiRender3DPositionToWorldPosition(crsoX, crsoY, crsoZ)
        text = text .. ('Camera GuiRender3DPositionToWorldPosition: {%.2f, %.2f, %.2f}\n'):format(crX, crY, crZ)

        text = text .. '\n'

        local fX, fY, fZ = LibImplex_2DMarkers:Get3DRenderSpaceForward()
        text = text .. ('Camera Forward: {%.2f, %.2f, %.2f}\n'):format(fX, fY, fZ)

        local rX, rY, rZ = LibImplex_2DMarkers:Get3DRenderSpaceRight()
        text = text .. ('Camera Right: {%.2f, %.2f, %.2f}\n'):format(rX, rY, rZ)

        local uX, uY, uZ = LibImplex_2DMarkers:Get3DRenderSpaceUp()
        text = text .. ('Camera Up: {%.2f, %.2f, %.2f}\n'):format(uX, uY, uZ)

        TEXT:SetText(text)
    end)
end