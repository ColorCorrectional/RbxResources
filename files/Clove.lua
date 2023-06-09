--!nocheck

--[[
	Clove
	ColorCorrectional
	9th June 2023
]]

type ErrorContexts = '#cleaning' | '#cleanupMethod' | string

type CombindOptions = {
	Transfer: boolean?
}

--[[
	@under Clove
	Backend helper methods for handling cleanup & errors
]]

local function GetErrorContext(s: ErrorContexts, ...)
	local scriptline, referenceName = debug.info(3, 'ln')
	
	if s == '#cleaning' then
		return `Cannot Clove:{referenceName}() while cleaning`
	elseif s == '#cleanupMethod' then
		return `Unable to get cleanup function for object type({...})`
	end
	return `Clove:{scriptline}:{referenceName}: "{s}"`
end

local function CreateError(message: ErrorContexts, ...)
	error(GetErrorContext(message, ...))
end

local function GetObjectCleanMethod(objectType, cleanMethod)
	if objectType == 'function' then 
		return objectType
	elseif objectType == 'thread' then 
		return objectType
	elseif cleanMethod then 
		return cleanMethod
	elseif objectType == 'Instance' then 
		return 'Destroy'
	elseif objectType == 'RBXScriptConnection' then 
		return 'Disconnect'
	end
	return CreateError('#cleanupMethod', objectType)
end

local function cleanupObject(object, cleanMethod)
	if cleanMethod == 'function' then
		object()
	elseif cleanMethod == 'thread' then
		coroutine.close(object)
	else
		object[cleanMethod](object)
	end
end

local function findAndRemoveFromObjects(objects, tofind, RuncleanupMethod: boolean)
	for key, obj in objects do
		if obj[1] ~= tofind then continue end
		table.remove(objects, key)
		
		if RuncleanupMethod then
			cleanupObject(obj[1], obj[2])
		end
		return true
	end
	return false
end

--[=[
	@class Clove
	Clove is a helpful module to track and store any type of object
	that needs to be cleaned up.
]=]
local Clove = {}
Clove.__index = Clove

--[[
	@param object <T> : object to add to the cache
	@param string? cleanupMethod : How to cleanup the @object
	@return @object
	
	Adds the given object to the cache ready to be cleaned up at any point.
]]
function Clove:Add<T>(object: T, cleanupMethod: string?)
	if self._cleaning then 
		CreateError('#cleaning')
	end
	table.insert(self._objects, {object, GetObjectCleanMethod(type(object), cleanupMethod)})
	return object
end

--[[
	@params inherit :Add() 
						 :replace objects: {}
	                     :cleanMethod overwrites on all objects.
	@return void
	
	Iterates through the objects & Adds them to the cache.
]]
function Clove:BulkAdd<T>(objects: {T}, cleanMethod: string?)
	if self._cleaning then 
		CreateError('#cleaning')
	end
	for _, obj in objects do
		print(objects, obj)
		self:Add(obj, cleanMethod)
	end
end

--[[
	@param object : the same object you added to the cache
	@return boolean : Whether the object has been removed
	
	Iterates through the object cache until it finds the first instance
	that equals to the @object & Runs cleanup method
]]

function Clove:Remove<object>(object: object): boolean
	if self._cleaning then 
		CreateError('#cleaning') 
	end
	return findAndRemoveFromObjects(self._objects, object, true)
end

--[[
	@param Instance : The Instance to :Clone()
	@return @Instance : The Cloned @Instance
	
	Clones the Instance & Adds it to the cache
]]

function Clove:Clone<object>(instance: object & Instance): object
	if self._cleaning then
		CreateError('#cleaning') 
	end
	return self:Add(instance:Clone())
end

--[[
	@param Signal | RBXSCRIPTSIGNAL : The Signal to be referenced
	@param string : How you want the @Signal to be called
	@param function : The function to be Connected
	@return @Signal
]]

function Clove:Signal(signal, RBXCallSignal: 'Connect' | 'ConnectParallel' | string, fn: (...any) -> (...any)): RBXScriptConnection?
	if self._cleaning then 
		CreateError('#cleaning') 
	end
	return self:Add(signal[RBXCallSignal](signal, fn))
end

--[[
	@Construct
	
	@param any <T> : @class object
	@param string? : How the @class should be cleaned up
	@param ...any : Values to send to the @class
	
	Easier way of Adding classes & functions 
]]

function Clove:Construct<T>(class: T, cleanMethod: string?, ...)
	if self._cleaning then
		CreateError('#cleaning')
	end
	local classType = type(class)
	
	if classType == 'table' then
		class = class.new(...)
	elseif classType == 'function' then
		class = class(...)
	end
	
	return self:Add(class, cleanMethod) :: T
end

--[[
	@param class Clove
	@param CombindOptions: 
						@param Clove
						Transfer: Removes Instances from param
	@return void
	Combinds another Clove objects together.
	
	CombindOptions
]]

function Clove:Combind(clove: typeof(Clove), CombindOptions: CombindOptions)
	for _, val in clove._objects do
		table.insert(self._objects, val)
	end
	
	if CombindOptions.Transfer then
		clove._objects = {}
	end
end

--[[
	@return void
	
	Iterates through the cache, runs each of the objects cleanup method,
	empties the cache.
]]

function Clove:Clean()
	if self._cleaning then return end
	self._cleaning = true
	
	for _, obj in self._objects do
		cleanupObject(obj[1], obj[2])
	end
	
	table.clear(self._objects)
	self._cleaning = nil
end

return {
	--[[
		@return Clove
		Constructs a Clove class.
	]]
	new = function()
		return setmetatable({_objects = {}} :: {any}, Clove)
	end,
}
