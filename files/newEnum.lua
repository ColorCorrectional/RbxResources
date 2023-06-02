--!strict

--[[
	@func Enum
	
	StrictEnum & Enum work exactly the same way but with better checking if a Enum exists
	or not with an error handler.
	
	```lua
		local kind = newEnum('Message', {'Info', 'Error', 'Warn'})
		
		kind.Info
			>
			.Name : member[i] ('Info')
			.Value : members[i] (1)
			.EnumType : name ('Message')
	```
]]

function newStrictEnum(name: string, members: {string})
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

function newEnum(name: string, members: {string})
	local enum = {}
	
	for i, member in members do
		enum[member] = {
			Name = member,
			Value = i,
			EnumType = name
		}
	end
	
	return table.freeze(enum)
end
