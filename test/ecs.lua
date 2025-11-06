local Core = {
    entities = setmetatable({}, {__mode = 'k'}),
    components = {},
    systems = {}
}


function Core:CreateEntity()
    local entity = {
        components = {},
        enabled = true
    }
    self.entities[entity] = true
    return entity
end


function Core:AddComponent(entity, componentType, ...)
    if not self.components[componentType] then
        self.components[componentType] = setmetatable({}, {__mode = 'k'})
    end

    local component = {type = componentType, ...}

    entity.components[componentType] = component
    self.components[componentType][entity] = component

    return component
end


function Core:RemoveComponent(entity, componentType)
    entity.components[componentType] = nil
    self.components[componentType][entity] = nil
end


function Core:HasComponent(entity, componentType)
    return entity.components[componentType] ~= nil
end


function Core:AddSystem(system)
    self.systems[#self.systems+1] = system
end


function Core:Update(deltaTime)
    local systems = self.systems
    for i = 1, #systems do
        systems[i]:Execute()
    end
end

-- ----------------------------------------------------------------------------

local Components = {
    Position = function(x, y, z)
        return {x = x, y = y, z = z}
    end,

    Visual = function(texture, size, color)
        return {
            texture = texture,
            size = size or {32, 32},
            color = color or {1, 1, 1, 1},
            alpha = 1,
            hidden = false
        }
    end,

    DistanceAlpha = function(minAlpha, maxAlpha, minDistance, maxDistance)
        return {
            minAlpha = minAlpha or 0.3,
            maxAlpha = maxAlpha or 1.0,
            minDistance = minDistance or 0,
            maxDistance = maxDistance or 1000,
            enabled = true
        }
    end,

    AutoHide = function(maxDistance, minDistance)
        return {
            maxDistance = maxDistance or 500,
            minDistance = minDistance or 0,
            enabled = true
        }
    end,

    Pulsing = function(minAlpha, maxAlpha, pulseSpeed)
        return {
            minAlpha = minAlpha or 0.5,
            maxAlpha = maxAlpha or 1.0,
            pulseSpeed = pulseSpeed or 2.0,
            currentTime = 0,
            enabled = true
        }
    end,

    ScreenClamp = function(insets)
        return {
            insets = insets or {10, 10, 10, 10}, -- left, right, top, bottom
            enabled = true
        }
    end,

    Selected = function()
        return {selected = true}
    end,

    Highlighted = function()
        return {highlighted = true}
    end
}

-- ----------------------------------------------------------------------------

local POOL_CONTROL = LibImplex_MarkersControl
local MARKER_TEMPLATE_NAME = 'LibImplex_MarkerTemplate'

local pools = {}

local function createNewPool(context, markerTemplateName, prefix)
    if not pools[context] then
        local function factoryFunction(objectPool)
            local marker = ZO_ObjectPool_CreateNamedControl(('$(parent)_%s_%s'):format(context, prefix or 'Marker'), markerTemplateName or MARKER_TEMPLATE_NAME, objectPool, POOL_CONTROL)
            assert(marker ~= nil, 'Control was not created!')

            return marker
        end

        local function resetFunction(control)
            for i = 1, control:GetNumChildren() do
                local childControl = control:GetChild(i)
                childControl:SetHidden(true)
            end

            control:SetHidden(true)
        end

        pools[context] = ZO_ObjectPool:New(factoryFunction, resetFunction)
    end

    return pools[context]
end

local function getContextStats()
    local stats = {}
    for context, pool in pairs(pools) do
        stats[context] = {
            pool:GetActiveObjectCount(),
            pool:GetTotalObjectCount(),
        }
    end
    return stats
end

local DEFAULT_POOL_NAME = 'default'
local DEFAULT_POOL = createNewPool(DEFAULT_POOL_NAME)

-- ----------------------------------------------------------------------------

local MARKERS_CONTROL_2D = LibImplex_2DMarkers
local MARKERS_CONTROL_2D_NAME = 'LibImplex_2DMarkers'

local cX, cY, cZ = 0, 0, 0
local rX, rY, rZ = 0, 0, 0
local uX, uY, uZ = 0, 0, 0
local fX, fY, fZ = 0, 0, 0
-- local pwX, pwY, pwZ = 0, 0, 0
local prwX, prwY, prwZ = 0, 0, 0
local cPitch, cYaw, cRoll = 0, 0, 0

local UI_WIDTH, UI_HEIGHT = GuiRoot:GetDimensions()
local NEGATIVE_UI_HEIGHT = -UI_HEIGHT

local function UpdateVectors()
    Set3DRenderSpaceToCurrentCamera(MARKERS_CONTROL_2D_NAME)

    cX, cY, cZ = GuiRender3DPositionToWorldPosition(MARKERS_CONTROL_2D:Get3DRenderSpaceOrigin()) -- RW
    fX, fY, fZ = MARKERS_CONTROL_2D:Get3DRenderSpaceForward()
    rX, rY, rZ = MARKERS_CONTROL_2D:Get3DRenderSpaceRight()
    uX, uY, uZ = MARKERS_CONTROL_2D:Get3DRenderSpaceUp()
    -- TODO: normalize?

    -- _, pwX, pwY, pwZ = GetUnitWorldPosition('player')
    _, prwX, prwY, prwZ = GetUnitRawWorldPosition('player')

    -- cPitch, cYaw, cRoll = MARKERS_CONTROL_2D:Get3DRenderSpaceOrientation()
end

local Systems = {}

Systems.RenderSystem = {
    enabled = true,
    filter = function(entity)
        return entity.components.Position and entity.components.Visual
    end,

    Execute = function(self)
        UpdateVectors()

        for entity in pairs(Core.entities) do
            if self.filter(entity) and entity.enabled then
                self:RenderMarker(entity)
            end
        end
    end,

    RenderMarker = function(self, entity)
        local pos = entity.components.Position
        local visual = entity.components.Visual

        if not visual.control then
            visual.control = self:CreateControl(entity)
        end

        if visual.hidden then
            visual.control:SetHidden(true)
            return
        end

        local x, y, z = pos.x, pos.y, pos.z
        local dX, dY, dZ = x - cX, y - cY, z - cZ

        local Z = fX * dX + fY * dY + fZ * dZ
        if Z < 0 then
            visual.control:SetHidden(true)
            return
        end

        local X = rX * dX + rZ * dZ
        local Y = uX * dX + uY * dY + uZ * dZ

        local w, h = GetWorldDimensionsOfViewFrustumAtDepth(Z)
        local scaleW = UI_WIDTH / w
        local scaleH = NEGATIVE_UI_HEIGHT / h

        visual.control:SetAnchor(CENTER, GuiRoot, CENTER, X * scaleW, Y * scaleH)
        visual.control:SetDrawLevel(-Z)
        visual.control:SetAlpha(visual.alpha)
        visual.control:SetHidden(false)
    end,

    CreateControl = function(self, entity)
        local control, key = DEFAULT_POOL:AcquireObject()
        local visual = entity.components.Visual

        control:SetTexture(visual.texture)
        control:SetDimensions(unpack(visual.size))
        control:SetColor(unpack(visual.color))

        return control
    end
}

-- Systems.DistanceAlphaSystem = {
--     enabled = true,
--     filter = function(entity)
--         return entity.components.Position and entity.components.Visual and entity.components.DistanceAlpha
--     end,
    
--     Execute = function(self, deltaTime)
--         for entity in pairs(Core.entities) do
--             if self.filter(entity) and entity.enabled then
--                 self:UpdateAlpha(entity)
--             end
--         end
--     end,
    
--     UpdateAlpha = function(self, entity)
--         local distanceAlpha = entity.components.DistanceAlpha
--         if not distanceAlpha.enabled then return end
        
--         local pos = entity.components.Position
--         local visual = entity.components.Visual
        
--         local diffX = prwX - pos.x
--         local diffY = prwY - pos.y
--         local diffZ = prwZ - pos.z
--         local distance = sqrt(diffX * diffX + diffY * diffY + diffZ * diffZ)
        
--         local alpha = lerp(
--             distanceAlpha.minAlpha, 
--             distanceAlpha.maxAlpha, 
--             clampedPercentBetween(distanceAlpha.minDistance, distanceAlpha.maxDistance, distance)
--         )
        
--         visual.alpha = alpha
--     end
-- }

-- Systems.AutoHideSystem = {
--     enabled = true,
--     filter = function(entity)
--         return entity.components.Position and entity.components.Visual and entity.components.AutoHide
--     end,
    
--     Execute = function(self, deltaTime)
--         for entity in pairs(Core.entities) do
--             if self.filter(entity) and entity.enabled then
--                 self:UpdateVisibility(entity)
--             end
--         end
--     end,
    
--     UpdateVisibility = function(self, entity)
--         local autoHide = entity.components.AutoHide
--         if not autoHide.enabled then return end
        
--         local pos = entity.components.Position
--         local visual = entity.components.Visual
        
--         local diffX = prwX - pos.x
--         local diffY = prwY - pos.y
--         local diffZ = prwZ - pos.z
--         local distance = sqrt(diffX * diffX + diffY * diffY + diffZ * diffZ)
        
--         visual.hidden = (distance > autoHide.maxDistance or distance < autoHide.minDistance)
--     end
-- }

-- Systems.PulsingSystem = {
--     enabled = true,
--     filter = function(entity)
--         return entity.components.Visual and entity.components.Pulsing
--     end,
    
--     Execute = function(self, deltaTime)
--         for entity in pairs(Core.entities) do
--             if self.filter(entity) and entity.enabled then
--                 self:UpdatePulse(entity, deltaTime)
--             end
--         end
--     end,
    
--     UpdatePulse = function(self, entity, deltaTime)
--         local pulsing = entity.components.Pulsing
--         local visual = entity.components.Visual
        
--         if not pulsing.enabled then return end
        
--         pulsing.currentTime = pulsing.currentTime + deltaTime * pulsing.pulseSpeed
--         local pulseValue = (math.sin(pulsing.currentTime) + 1) / 2 -- 0 to 1
        
--         local pulseAlpha = lerp(pulsing.minAlpha, pulsing.maxAlpha, pulseValue)
        
--         -- Combine with existing alpha if distance alpha is also applied
--         if entity.components.DistanceAlpha then
--             visual.alpha = visual.alpha * pulseAlpha
--         else
--             visual.alpha = pulseAlpha
--         end
--     end
-- }

-- Systems.ScreenClampSystem = {
--     enabled = true,
--     filter = function(entity)
--         return entity.components.Visual and entity.components.ScreenClamp
--     end,
    
--     Execute = function(self, deltaTime)
--         for entity in pairs(Core.entities) do
--             if self.filter(entity) and entity.enabled then
--                 self:UpdateClamping(entity)
--             end
--         end
--     end,
    
--     UpdateClamping = function(self, entity)
--         local screenClamp = entity.components.ScreenClamp
--         local visual = entity.components.Visual
        
--         if not screenClamp.enabled or not visual.control then return end
        
--         visual.control:SetClampedToScreen(true)
--         visual.control:SetClampedToScreenInsets(unpack(screenClamp.insets))
--     end
-- }

-- ----------------------------------------------------------------------------

LibImplex.Marker2D = {}

function LibImplex.Marker2D.Create(position, texture, size, color)
    local entity = Core:CreateEntity()

    Core:AddComponent(entity, Components.Position, position[1], position[2], position[3])
    Core:AddComponent(entity, Components.Visual, texture, size, color)

    return entity
end

-- function LibImplex.Marker2D.AddDistanceAlpha(entity, minAlpha, maxAlpha, minDistance, maxDistance)
--     return Core:AddComponent(entity, "DistanceAlpha", minAlpha, maxAlpha, minDistance, maxDistance)
-- end

-- function LibImplex.Marker2D.RemoveDistanceAlpha(entity)
--     Core:RemoveComponent(entity, "DistanceAlpha")
-- end

-- function LibImplex.Marker2D.SetDistanceAlphaEnabled(entity, enabled)
--     if entity.components.DistanceAlpha then
--         entity.components.DistanceAlpha.enabled = enabled
--     end
-- end

-- function LibImplex.Marker2D.AddAutoHide(entity, maxDistance, minDistance)
--     return Core:AddComponent(entity, "AutoHide", maxDistance, minDistance)
-- end

-- function LibImplex.Marker2D.RemoveAutoHide(entity)
--     Core:RemoveComponent(entity, "AutoHide")
-- end

-- function LibImplex.Marker2D.AddPulsing(entity, minAlpha, maxAlpha, pulseSpeed)
--     return Core:AddComponent(entity, "Pulsing", minAlpha, maxAlpha, pulseSpeed)
-- end

-- function LibImplex.Marker2D.AddScreenClamp(entity, insets)
--     return Core:AddComponent(entity, "ScreenClamp", insets)
-- end

-- function LibImplex.Marker2D.Select(entity)
--     Core:AddComponent(entity, "Selected")
--     -- Disable auto-hide and distance alpha for selected markers
--     if entity.components.AutoHide then
--         entity.components.AutoHide.enabled = false
--     end
--     if entity.components.DistanceAlpha then
--         entity.components.DistanceAlpha.enabled = false
--     end
--     -- Ensure full visibility
--     entity.components.Visual.alpha = 1.0
--     entity.components.Visual.hidden = false
-- end

-- function LibImplex.Marker2D.Deselect(entity)
--     Core:RemoveComponent(entity, "Selected")
--     -- Re-enable systems
--     if entity.components.AutoHide then
--         entity.components.AutoHide.enabled = true
--     end
--     if entity.components.DistanceAlpha then
--         entity.components.DistanceAlpha.enabled = true
--     end
-- end

function LibImplex.Marker2D.Delete(entity)
    if entity.components.Visual and entity.components.Visual.control then
        DEFAULT_POOL:ReleaseObject(entity.components.Visual.control.objectKey)
    end
    Core.entities[entity] = nil
end

for _, system in pairs(Systems) do
    Core:AddSystem(system)
end

function LibImplex.Marker2D.Update()
    Core:Update()
end
