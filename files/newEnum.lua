--[[
	Methods to create customized Enum's. These methods are 
	syntactic sugar for a dictionary containing dictionaries containing
	values Name, Value, and EnumType.

	```lua
	local kind = newEnum("Message", {"Info", "Error", "Warn"})
	local types = newEnum("Types", {"Info", "Error", "Warn"})

	if kind.Info ~= types.Info then
		print("Different Enums.")
	end
	```
]]

function newStrictEnum(name: string, members: { [number]: string })
	local enum = table.create(#members)

	for index, member in members do
		enum[member] = {
			Name = member,
			Value = index,
			EnumType = name
		}
	end

	return setmetatable(enum, {
		__index = function(_, key)
			error(`{key} is not in {name}!`, 2)
		end,

		__newindex = function()
			error(`Creating new members in {name} is not allowed!`, 2)
		end,
	})
end

function newEnum(name: string, members: { [number]: string })
	local enum = table.create(#members)

	for index, member in members do
		enum[member] = {
			Name = member,
			Value = index,
			EnumType = name
		}
	end

	return enum
end
