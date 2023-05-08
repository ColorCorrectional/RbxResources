---!strict

type config = {
	once: boolean? -- Only runs the sequence once then removes it
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
		_threads = {} :: {[string]: _thread}
	}, sequencer)
end

function sequencer:runSequence(name: string, ...: any): ...any
	local thread: _thread = self._threads[name]
	if not thread then return end

	local runningCoroutine = coroutine.running() -- Gets the current environment
	
	task.defer(function(...)
		if thread.config.once then
			self:removeThreadFromSequence(name)
		end
		task.spawn(runningCoroutine, thread.func(...)) -- Runs the sequence function then resumes the callers environment.
	end, ...)
	
	return coroutine.yield() -- Yields the environment from where it has been called.
end

function sequencer:removeThreadFromSequence(name: string)
	self._threads[name] = nil
end

function sequencer:addThreadToSequence(name: string, func: thread, config: config?): (...any) -> (...any)
	self._threads[name] = {
		func = func,
		config = config or {}
	} :: _thread
	
	return function(...) -- Allowes you to run the thread without doing the string method through `self:runSequence`
		return self:runSequence(name, ...)
	end
end

return new
