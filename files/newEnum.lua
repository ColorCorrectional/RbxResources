function newEnum(name: string, members: {string})
	local enum = {} 

	for i, member in members do
		enum[member] = {
			Name = member,
			Value = i,
			EnumType = name
		}
	end

	return setmetatable(enum, 
		{
			__index = function(_, key)
				error(`{key} is not in {name}!`, 2)
			end,
			__newindex = function()
				error(`Creating new members in {name} is not allowed!`, 2)
			end,
		})
end
