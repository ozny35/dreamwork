--- Python-like futures, made by Retro

local std = gpm.std
local is = std.is
local error = std.error
local class = std.class
local Symbol = std.Symbol
local Queue = std.Queue
local tostring, pcall, xpcall = std.tostring, pcall, xpcall
---@type coroutinelib
local coroutine = std.coroutine
local timer_Simple = timer.Simple

---@class gpm.std.futures
local futures = std.futures or {}

---@enum gpm.std.futures.result
futures.RESULT = futures.RESULT or {
    YIELD = Symbol("futures.RESULT_YIELD"),
    ERROR = Symbol("futures.RESULT_ERROR"),
    END =  Symbol("futures.RESULT_END")
}

---@enum gpm.std.futures.action
futures.ACTION = futures.ACTION or {
    CANCEL = Symbol("futures.ACTION_CANCEL"),
    RESUME = Symbol("futures.ACTION_RESUME"),
}

local RESULT_YIELD = futures.RESULT.YIELD
local RESULT_ERROR = futures.RESULT.ERROR
local RESULT_END = futures.RESULT.END
local ACTION_CANCEL = futures.ACTION.CANCEL
local ACTION_RESUME = futures.ACTION.RESUME


---@private
---@type { [thread]: function }
futures.listeners = futures.listeners or setmetatable({}, { __mode = "kv" })

---@private 
---@type { [thread]: thread }
futures.coroutine_listeners = futures.coroutine_listeners or setmetatable({}, { __mode = "kv" })

---@alias gpm.std.futures.AsyncIterator<K, V> table<K, V> | nil
---@alias gpm.std.futures.Awaitable { await: async fun(...): ... }

futures.running = coroutine.running


local function displayError(message)
    return error(message, -2)
end


---@async
---@param ok boolean
local function asyncThreadResult(ok, value, ...)
    local co = futures.running()
    local callback = futures.listeners[co]

    if is.fn(callback) then
        callback(ok, value, ...)
    elseif not ok then
        -- TODO: use errors instead of this string
        if is.string(value) and string.find(value, "Operation was cancelled") then
            return
        end

        error(value, -2)
    end
end

---@async
local function asyncThread(fn, ...)
    return asyncThreadResult(pcall(fn, ...))
end

--- Executes a function in a new coroutine
---@param target async fun(...):...
---@param callback fun(ok: boolean, ...)?
---@param ... any Arguments to pass into the target function
---@return thread
function futures.run(target, callback, ...)
    local co = coroutine.create(asyncThread)
    futures.listeners[co] = callback
    local ok, err = coroutine.resume(co, target, ...)
    if not ok then
        error(err)
    end

    return co
end


---@async
local function handlePending(value, ...)
    if value == ACTION_CANCEL then
        return error("Operation was cancelled")
    end

    return value, ...
end

---@async
---@return ...
function futures.pending()
    return handlePending(coroutine.yield())
end

---@param co thread
function futures.wakeup(co, ...)
    coroutine.resume(co, ...)
end


---@param co thread
function futures.cancel(co)
    local status = coroutine.status(co)
    if status == "suspended" then
       coroutine.resume(co, ACTION_CANCEL)
    end
end


---@async
---@param seconds number
function futures.sleep(seconds)
    local co = futures.running()

    timer_Simple(seconds, function()
        futures.wakeup(co)
    end)

    return futures.pending()
end


--- Transfers data between coroutines in symmetrical way
---@async
---@param co thread
---@param ... any
---@return boolean success
---@return any ...
function futures.transfer(co, ...)
    local status = coroutine.status(co)
    if status == "suspended" then
        return coroutine.resume(co, ...)
    end

    if status == "normal" then
        return true, coroutine.yield(...)
    end

    if status == "running" then
        return false, "cannot transfer to a running coroutine"
    end

    return false, "thread is dead"
end


---@async
local function handleYield(ok, value, ...)
    -- ignore errors, they must be handled by whoever calls us
    if not ok or value == RESULT_ERROR then
        return
    end

    if value == ACTION_CANCEL then
        return error("Operation was cancelled")
    end

    if value == ACTION_RESUME then
        return ...
    end

    if value ~= nil then
        error("invalid yield action: " .. tostring(value), -2) -- ErrorNoHaltWithStack
    end

    -- caller probably went sleeping
    return handleYield(true, coroutine.yield())
end

---@async
function futures.yield(...)
    local listener = futures.coroutine_listeners[futures.running()]
    if not listener then
        -- whaat? we don't have a listener?!
        error("Operation was cancelled")
    end

    return handleYield(futures.transfer(listener, RESULT_YIELD, ...))
end


---@async
local function asyncIteratableThread(fn, ...)
    coroutine.yield() -- wait until anext wakes us up
    local ok, err = pcall(fn, ...)

    local listener = futures.coroutine_listeners[futures.running()]
    if listener then
        if ok then
            futures.transfer(listener, RESULT_END)
        else
            futures.transfer(listener, RESULT_ERROR, err)
        end
    elseif not ok then
        error(err)
    end
end


---@async
---@param co thread
---@param ok boolean
local function handleAnext(co, ok, value, ...)
    if not ok then
        return error(ok)
    end

    if value == RESULT_YIELD then
        return ...
    end

    if value == RESULT_END then
        return -- return nothing so for loop with be stopped
    end

    if value == RESULT_ERROR then
        return error(...)
    end

    if value ~= nil then
        error("invalid anext result: " .. tostring(value), -2) -- ErrorNoHaltWithStack
    end

    -- iterator went sleeping, wait until it wakes us up
    return handleAnext(co, true, coroutine.yield())
end

---@async
---@param iterator thread
function futures.anext(iterator, ...)
    return handleAnext(iterator, futures.transfer(iterator, ACTION_RESUME, ...))
end

---@async
---@generic K, V
---@param iterator async fun(...): gpm.std.futures.AsyncIterator<K, V>
---@return async fun(...): K, V
---@return thread
function futures.apairs(iterator, ...)
    local co = coroutine.create(asyncIteratableThread)
    futures.coroutine_listeners[co] = futures.running()
    coroutine.resume(co, iterator, ...)

    return futures.anext, co
end


--- Launches given iterator and collects its results into a table
---@async
---@generic V
---@param iterator async fun(...): gpm.std.futures.AsyncIterator<V>
---@return V[]
function futures.collect(iterator, ...)
    local results = {}
    local i = 1
    for value in futures.apairs(iterator, ...) do
        results[i] = value
        i = i + 1
    end
    return results
end

do
    ---@alias Future gpm.std.futures.Future
    ---@class gpm.std.futures.Future : gpm.std.Object
    ---@field __class gpm.std.futures.FutureClass
    ---@field private _state gpm.std.Symbol
    ---@field private _callbacks function[]
    ---@field private _result any
    ---@field private _error any
    local Future = futures.Future and futures.Future.__base or class.base("Future")

    local STATE_PENDING = Future.STATE_PENDING
    local STATE_FINISHED = Future.STATE_FINISHED
    local STATE_CANCELLED = Future.STATE_CANCELLED

    Future.STATE_PENDING = STATE_PENDING or Symbol("Future.STATE_PENDING")
    Future.STATE_FINISHED = STATE_FINISHED or Symbol("Future.STATE_FINISHED")
    Future.STATE_CANCELLED = STATE_CANCELLED or Symbol("Future.STATE_CANCELLED")

    ---@protected
    function Future:__init()
        self._state = STATE_PENDING
        self._callbacks = {}
    end

    ---@protected
    function Future:__tostring()
        if self:done() then
            if self:cancelled() then
                return self.__name .. "( cancelled )"
            end

            if self._error then
                return self.__name .. "( finished error = " .. tostring(self._error) .. " )"
            else
                return self.__name .. "( finished value = " .. tostring(self._result) .. " )"
            end
        else
            return self.__name .. "( pending )"
        end
    end

    --- Checks if Future is done
    ---@return boolean
    function Future:done()
        return self._state ~= STATE_PENDING
    end

    --- Checks if Future was cancelled
    ---@return boolean
    function Future:cancelled()
        return self._state == STATE_CANCELLED
    end

    ---@private
    function Future:runCallbacks()
        local callbacks = self._callbacks
        if not callbacks then
            return
        end

        self._callbacks = {}
        for i = 1, #callbacks do
            xpcall(callbacks[i], displayError, self)
        end
    end

    ---@param fn fun(fut: gpm.std.futures.Future)
    function Future:addCallback(fn)
        if self:done() then
            xpcall(fn, displayError, self)
        else
            self._callbacks[#self._callbacks+1] = fn
        end
    end

    ---@param fn function
    function Future:removeCallback(fn)
        local callbacks = {}
        for i = 1, #self._callbacks do
            local cb = self._callbacks[i]
            if cb ~= fn then
                callbacks[#callbacks+1] = cb
            end
        end
        self._callbacks = callbacks
    end

    ---@param result any
    function Future:setResult(result)
        if self:done() then
            error("future is already finished")
        end

        self._result = result
        self._state = STATE_FINISHED
        self:runCallbacks()
    end

    ---@param err any
    function Future:setError(err)
        if self:done() then
            error("future is already finished")
        end

        self._error = err
        self._state = STATE_FINISHED
        self:runCallbacks()
    end

    ---@return boolean cancelled
    function Future:cancel()
        if self:done() then
            return false
        end

        self._state = STATE_CANCELLED
        self:runCallbacks()
        return true
    end

    ---@return unknown?
    function Future:error()
        if self:cancelled() then
            return "future was cancelled"
        elseif not self:done() then
            return "future is not finished"
        end

        return self._error
    end

    ---@return any
    function Future:result()
        if self:cancelled() then
            return "future was cancelled"
        elseif not self:done() then
            return "future is not finished"
        end

        if self._error then
            error(self._error)
        end

        return self._result
    end

    ---@async
    ---@return any
    function Future:await()
        if not self:done() then
            local co = futures.running()
            self:addCallback(function() futures.wakeup(co) end)
            futures.pending()
        end

        if not self:done() then
            error("future hasn't changed it's state wtf???")
        end

        return self:result()
    end

    ---@class gpm.std.futures.FutureClass : gpm.std.futures.Future
    ---@field __base Future
    ---@overload fun(): gpm.std.futures.Future
    futures.Future = class.create(Future)
end

do
    ---@class gpm.std.futures.Task : gpm.std.futures.Future
    ---@field __class gpm.std.futures.TaskClass
    ---@field __parent gpm.std.futures.Future
    ---@field private setResult fun(self, result)
    ---@field private setError fun(self, error)
    local Task = futures.Task and futures.Task.__base or class.base("Task", futures.Future)

    ---@protected
    ---@param fn async fun(...): any
    function Task:__init(fn, ...)
        self.__parent.__init(self)
        futures.run(fn, function(ok, value)
            if not ok then
                self:setError(value)
            else
                self:setResult(value)
            end
        end, ...)
    end

    ---@class gpm.std.futures.TaskClass : gpm.std.futures.Task
    ---@field __base gpm.std.futures.Task
    ---@overload fun(fn: async fun(...): any, ...: any): gpm.std.futures.Task
    futures.Task = class.create(Task)
end

do
    ---@alias Channel gpm.std.futures.Channel
    ---@class gpm.std.futures.Channel : gpm.std.Object
    ---@field __class gpm.std.futures.ChannelClass
    ---@field private _maxsize number
    ---@field private _queue gpm.std.Queue
    ---@field private _getters gpm.std.Queue
    ---@field private _setters gpm.std.Queue
    ---@field private _closed boolean
    local Channel = futures.Channel and futures.Channel.__base or class.base("Channel")

    ---@protected
    ---@param maxsize number?
    function Channel:__init(maxsize)
        if maxsize and maxsize < 0 then
            error("maxsize must be greater or equal to 0")
        end

        self._maxsize = maxsize or 0
        self._queue = Queue()
        self._getters = Queue()
        self._setters = Queue()
        self._closed = false
    end

    ---@return number length
    function Channel:len()
        return self._queue:len()
    end

    ---@return boolean isEmpty
    function Channel:empty()
        return self._queue:empty()
    end

    ---@return boolean isFull
    function Channel:full()
        if self._maxsize == 0 then
            return false
        end

        return self:len() >= self._maxsize
    end

    function Channel:close()
        self._closed = true

        -- wake up all getters and setters
        while not self._getters:empty() do
            futures.wakeup(self._getters:pop())
        end

        while not self._setters:empty() do
            futures.wakeup(self._setters:pop())
        end
    end

    ---@return boolean isClosed
    function Channel:closed()
        return self._closed
    end

    ---@param value any
    ---@return boolean success
    function Channel:putNow(value)
        if self:full() or self:closed() or value == nil then
            return false
        end

        self._queue:append(value)
        local getter = self._getters:pop()
        if getter then
            futures.wakeup(getter)
        end

        return true
    end

    ---@async
    ---@param value any
    ---@param wait boolean?
    ---@return boolean success
    function Channel:put(value, wait)
        while wait ~= false and (self:full() and not self:closed()) do
            self._setters:append(futures.running())
            futures.pending()
        end

        return self:putNow(value)
    end

    function Channel:getNow()
        if self:empty() or self:closed() then
            return nil
        end

        local value = self._queue:pop()
        local setter = self._setters:pop()
        if setter then
            futures.wakeup(setter)
        end

        return value
    end

    ---@async
    ---@param wait boolean?
    function Channel:get(wait)
        while wait ~= false and self:empty() and not self:closed() do
            self._getters:append(futures.running())
            futures.pending()
        end

        return self:getNow()
    end

    ---@class gpm.std.futures.ChannelClass : gpm.std.futures.Channel
    ---@field __base gpm.std.futures.Channel
    ---@overload fun(maxsize: number?): gpm.std.futures.Channel
    futures.Channel = class.create(Channel)
end

return futures
