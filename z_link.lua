local Pool

local function GetPool()
    if not Pool then
        -- local function factoryFunction(objectPool)
        --     local linkControl = ZO_ObjectPool_CreateNamedControl('$(parent)_Link', 'Pathfinder_LinkTemplate', objectPool, Pathfinder_Links)

        --     return linkControl
        -- end

        Pool = ZO_ControlPool:New('Pathfinder_LinkTemplate', Pathfinder_Links, 'Link')
    end

    return Pool
end

local function AcquireLink()
    local linkControl, linkKey = GetPool():AcquireObject()
    linkControl.key = linkKey

    linkControl:SetHidden(false)

    return linkControl
end

local function ReleaseLink(linkControl)
    GetPool():ReleaseObject(linkControl.key)
    linkControl.key = nil
end

PATHFINDER_Links = {
    -- GetPool = GetPool,
    AcquireLink = AcquireLink,
    ReleaseLink = ReleaseLink,
}
