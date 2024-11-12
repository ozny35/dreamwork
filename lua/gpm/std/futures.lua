--- Python-like futures, made by Retro

local std = gpm.std
local is = std.is
local error = std.error

---@type coroutinelib
local coroutine = std.coroutine
local timer_Simple = timer.Simple

---@class gpm.std.futures
local futures = std.futures or {}

---@enum gpm.std.futures.result
futures.RESULT = futures.RESULT or {
    CANCEL = newproxy(true),
    YIELD = newproxy(true),
    ERROR = newproxy(true),
    END = newproxy(true)
}

for name, value in pairs(futures.RESULT) do
    local name = "RESULT_" .. name .. string.format("%p", value)
    local meta = getmetatable(value)
    meta.__tostring = function() return name end
end

local RESULT_CANCEL = futures.RESULT.CANCEL
local RESULT_YIELD = futures.RESULT.YIELD
local RESULT_ERROR = futures.RESULT.ERROR
local RESULT_END = futures.RESULT.END

---@private
---@type { [thread]: function | thread }
futures.listeners = futures.listeners or setmetatable({}, { __mode = "kv" })

---@alias AsyncIterator<K, V> table<K, V> | nil

futures.running = coroutine.running


---@param value gpm.std.futures.result
---@return boolean success
---@return any ...
local function handleTransfer(co, ok, value, ...)
    if ok then
        if value == RESULT_ERROR then
            return false, ...
        end

        if value == RESULT_CANCEL then
            return false, "Operation was cancelled"
        end
    end

    return ok, value, ...
end

---@async
---@param co thread
---@param ... any
---@return boolean success
---@return any ...
function futures.transfer(co, ...)
    local status = coroutine.status(co)
    if status == "suspended" then
        return handleTransfer(co, coroutine.resume(co, ...))
    end

    if status == "normal" then
        return handleTransfer(co, true,coroutine.yield(...))
    end

    if status == "running" then
        return false, "cannot transfer to a running coroutine"
    end

    return false, "thread is dead"
end



---@async
---@param ok boolean
local function asyncThreadResult(ok, value, ...)
    local co = coroutine.running()
    local callback = futures.listeners[co]

    if callback then
        if is.thread(callback) then
            ---@cast callback thread
            futures.transfer(callback, ok and RESULT_END or RESULT_ERROR, value, ...)
        else
            callback(ok, value, ...)
        end
    elseif not ok then
        error(value, -2)
    end
end

---@async
local function asyncThread(fn, ...)
    return asyncThreadResult(pcall(fn, ...))
end

---@async
local function asyncIteratableThread(fn)
    return asyncThreadResult(pcall(fn, coroutine.yield()))
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
    if value == RESULT_CANCEL then
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
    if coroutine.status(co) == "suspended" then
       coroutine.resume(co, RESULT_CANCEL)
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


---@async
---@param co thread
---@param ok boolean
local function handleAnext(co, ok, value, ...)
    -- print("handleAnext")
    -- print("\tco =", co)
    -- print("\tok =", ok)
    -- print("\tvalue =", value, "IS_YIELD=" .. tostring(value == RESULT_YIELD), "IS_END=" .. tostring(value == RESULT_END))
    -- print("\t... =", ...)
    if not ok then
        return error(ok)
    end

    if value == RESULT_YIELD then
        return ...
    end

    if value == RESULT_END then
        return nil
    end

    if value == RESULT_ERROR then
        return error(...)
    end

    -- thread went sleeping, wait until it wakes us up
    return handleAnext(co, true, coroutine.yield())
end

---@async
---@param iterator thread
local function anext(iterator, ...)
    return handleAnext(iterator, futures.transfer(iterator))
end

---@async
---@generic K, V
---@param iterator async fun(...): AsyncIterator<K, V>
---@return async fun(...): K, V
---@return thread
---@return ...
function futures.apairs(iterator, ...)
    local co = coroutine.create(asyncIteratableThread)
    coroutine.resume(co, iterator)
    futures.listeners[co] = futures.running()

    return anext, co, ...
end


local function handleYield(ok, value, ...)
    if not ok then
        error(value)
    end

    return value, ...
end

---@async
function futures.yield(...)
    local listener = futures.listeners[futures.running()]
    ---@cast listener thread
    return handleYield(futures.transfer(listener, RESULT_YIELD, ...))
end


---@async
---@return AsyncIterator<integer>
local function fuck()
    for i = 1, 5 do
        futures.yield(i)
        futures.sleep(1)
    end
end

---@async
local function main()
    print("begin")
    for k, v in futures.apairs(fuck) do
        print(k)
    end
    print("end")
end

-- futures.run(main)


return futures
