--- Python-like futures, made by Retro

local std = gpm.std
local is = std.is
local error = std.error

---@type coroutinelib
local coroutine = std.coroutine

---@class gpm.std.futures
local futures = std.futures or {}

---@enum gpm.std.futures.result
futures.RESULT = futures.RESULT or {
    ERROR = newproxy(false),
    END = newproxy(false)
}

local RESULT_ERROR = futures.RESULT.ERROR
local RESULT_END = futures.RESULT.END

---@type { [thread]: function }
futures.listeners = futures.listeners or setmetatable({}, { __mode = "kv" })

-- futures.RESULT_ERROR = futures.RESULT_ERROR or newproxy(false); local RESULT_ERROR = futures.RESULT_ERROR
-- futures.RESULT_END = futures.RESULT_END or newproxy(false); local RESULT_END = futures.RESULT_END


---@param value gpm.std.futures.result
---@return boolean success
---@return any ...
local function handleTransfer(co, ok, value, ...)
    if ok then
        if value == RESULT_ERROR then
            return false, ...
        end

        if value == RESULT_END then
            return true, ...
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
        return handleTransfer(co, true,coroutine.yield(co, ...))
    end

    if status == "running" then
        return false, "cannot transfer to a running coroutine"
    end

    return false, "thread is dead"
end


---@param ok boolean
local function asyncThreadResult(ok, value, ...)
    local co = coroutine.running()
    local callback = futures.listeners[co]

    if callback then
        callback(ok, value, ...)
    else
        error(..., -2)
    end
end

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
local function main()
    print("hello world")
end

futures.run(main, function(ok, ...)
    print("Futures run", ok, ...)
end)


return futures
