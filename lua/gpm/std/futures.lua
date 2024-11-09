--- Python-like futures, made by Retro

---@class gpm.std
local std = gpm.std
---@type coroutinelib
local coroutine = std.coroutine

---@class gpm.std.futures
local futures = std.futures or {}
std.futures = futures


futures.RESULT_ERROR = futures.RESULT_ERROR or newproxy(); local RESULT_ERROR = futures.RESULT_ERROR
futures.RESULT_END = futures.RESULT_END or newproxy(); local RESULT_END = futures.RESULT_END


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


local function asyncThreadResult()

end


---@param fn function
---@param cb function
local function asyncThread(fn, cb, ...)

end

--- Executes a function in a new coroutine
---@param target function
---@param callback function
---@param ... any Arguments to pass into the target function
---@return thread
function futures.run(target, callback, ...)
    local co = coroutine.create(asyncThread)
    local ok, err = coroutine.resume(co, target, callback, ...)
    if not ok then
        error(err)
    end

    return co
end



print('hi')


