--- Python-like futures, made by Retro

local std = gpm.std
local is = std.is
local error = std.error
local Symbol = std.Symbol
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

---@alias AsyncIterator<K, V> table<K, V> | nil

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
---@param iterator async fun(...): AsyncIterator<K, V>
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
---@param iterator async fun(...): AsyncIterator<V>
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

return futures
