local function class(base)
	local cls = {}

	if type(base) == 'table' then
		for k, v in pairs(base) do
			cls[k] = v
		end

		cls.base = base  -- TODO: make use of it or remove
	end

	cls.__index = cls

	setmetatable(cls, {
        __call = function(self, ...)
            local obj = setmetatable({}, cls)

            if self.__init then
                self.__init(obj, ...)
            elseif base ~= nil and base.__init ~= nil then
                base.__init(obj, ...)
            end

            return obj
        end
	})

	return cls
end

-- ----------------------------------------------------------------------------

LibImplex = LibImplex or {}
LibImplex.class = class