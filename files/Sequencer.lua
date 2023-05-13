--!strict

type config = {
	once: boolean? -- runs once then removes the thread.
}

type _thread = {
	func: (...any?) -> (...any?),
	config: config
}

--[[
	@class Sequencer
	
	runs functions & a scripts enviroment once a sequence has been completed.
	by coroutine.yield() then using a task.defer(corotine.running()) to successfully yield
	and continue when done & will return whatever the thread returns. 
]]

local sequencer = {}
sequencer.__index = sequencer

local function new()
	return setmetatable({
		_threads = {} :: {[string]: _thread},
	}, sequencer)
end

local function _run(taskfunc: (thread) -> ()): ...any
	local enviroment = coroutine.running()
	task.defer(taskfunc, enviroment)
	
	return coroutine.yield()
end

function sequencer:runSequenceWithDelay(name: string, delayTime: number, args: {any}): ...any
	local thread: _thread = self._threads[name]
	
	if not thread then return end
	args = args or {}
	
	return _run(function(enviroment)
		task.delay(delayTime, function()
			if thread.config.once then
				self:removeThreadFromSequence(name)
			end
			task.spawn(enviroment, thread.func(unpack(args)))
		end)
	end)
end

function sequencer:runSequence(name: string, args: {any}): ...any
	local thread: _thread = self._threads[name]
	
	if not thread then return end
	args = args or {}
	
	return _run(function(enviroment)
		if thread.config.once then
			self:removeThreadFromSequence(name)
		end
		task.spawn(enviroment, thread.func(unpack(args)))
	end)
end

function sequencer:removeThreadFromSequence(name: string)
	self._threads[name] = nil
end

function sequencer:addThreadToSequence(name: string, func: thread, config: config?): ({any}) -> (...any?)
	self._threads[name] = {
		func = func,
		config = config or {}
	}
	
	return function(args: {any})
		return self:runSequence(name, args)
	end
end

return new
