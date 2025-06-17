local TOP_LEVEL_CONTROL = LibImplex_DebugWindow
local TEXT = TOP_LEVEL_CONTROL:GetNamedChild('Text')

function LibImplex_ShowDebugWindow()
    TOP_LEVEL_CONTROL:SetHidden(false)

    EVENT_MANAGER:RegisterForUpdate('LibImplex_DebugWindow_Update', 1000/60, function()
        local zoneId = GetZoneId(GetUnitZoneIndex('player'))

        local text = ''

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

        TEXT:SetText(text)
    end)
end