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
local timer_simple = std.timer.simple

---@class gpm.std.futures
local futures = std.futures or {}

-- TODO: use errors instead of string
-- TODO: make cancel error

---@package
---@enum gpm.std.futures.result
futures.RESULT = futures.RESULT or {
    YIELD = Symbol( "futures.RESULT_YIELD" ),
    ERROR = Symbol( "futures.RESULT_ERROR" ),
    END =  Symbol( "futures.RESULT_END" )
}

---@package
---@enum gpm.std.futures.action
futures.ACTION = futures.ACTION or {
    CANCEL = Symbol( "futures.ACTION_CANCEL" ),
    RESUME = Symbol( "futures.ACTION_RESUME" ),
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

--- Abstract type that is used to type hint async functions
---@see gpm.std.futures.apairs for example
---@alias gpm.std.futures.AsyncIterator<K, V> table<K, V> | nil
---@alias AsyncIterator<K, V> gpm.std.futures.AsyncIterator<K, V>

---@alias gpm.std.futures.Awaitable { await: async fun(...): ... }
---@alias Awaitable gpm.std.futures.Awaitable

futures.running = coroutine.running


local function displayError( message )
    return error( message, -2 )
end


---@async
---@param ok boolean
local function asyncThreadResult( ok, value, ... )
    local fn = futures.listeners[ futures.running() ]
    if is.fn( fn ) then
        fn( ok, value, ... )
    elseif not ok then
        -- TODO: use errors instead of this string
        if is.string( value ) and string.find( value, "Operation was cancelled" ) then
            return
        end

        error( value, -2 )
    end
end

---@async
local function asyncThread( fn, ... )
    return asyncThreadResult( pcall( fn, ... ) )
end

--- Executes a function in a new coroutine
--- you can use this function to call async functions even in sync code
--- callback will be called when function returned or errored
--- it will be called with these arguments:
--- * ok: boolean - whether the function returned without errors
--- * ... - return values of the function (or error message)
---
--- ## Example
--- ```lua
--- ---@async
--- local function asyncFunction( a, b )
---     futures.sleep( 1 )
---     return
--- end
---
--- futures.run( asyncFunction, function( ok, result )
---     if ok then
---         print( "result:", result ) -- result: 4
---     else
---         print( "error:", result )
---     end
--- end, 2, 2 ) -- 2 and 2 are arguments for asyncFunction
--- ```
---@see gpm.std.futures.cancel you can cancel returned coroutine from this function
---@param target async fun(...):...
---@param callback fun(ok: boolean, ...)?
---@param ... any Arguments to pass into the target function
---@return thread
function futures.run( target, callback, ... )
    local co = coroutine.create( asyncThread )
    futures.listeners[ co ] = callback

    local ok, err = coroutine.resume( co, target, ... )
    if ok then
        return co
    else
        error( err )
    end
end


---@async
local function handlePending( value, ... )
    if value == ACTION_CANCEL then
        return error( "Operation was cancelled" ) -- TODO: use error
    else
        return value, ...
    end
end

--- Puts current coroutine to sleep until futures.wakeup is called
--- can be used to wait for some event.
---
--- ## Example
--- ```lua
--- ---@async
--- local function request( url )
---     local co = futures.running()
---
---     http.Fetch( url, function( body, size, headers, code )
---         futures.wakeup( co, body )
---     end)
---
---     return futures.pending() -- this will return all arguments passed to futures.wakeup
--- end
---
--- local function main()
---     local body = request( "https://example.com" )
---     print( body ) -- <!DOCTYPE html>...
--- end
---
--- futures.run( main )
--- ```
---@see gpm.std.futures.wakeup
---@async
---@return ...
function futures.pending()
    return handlePending( coroutine.yield() )
end

--- Used to wake up pending coroutine.
---
---@see gpm.std.futures.pending for example
---@param co thread
function futures.wakeup( co, ... )
    coroutine.resume( co, ... )
end


--- Cancels execution of passed coroutine.
---
--- `CancelError` will be thrown in coroutine.
---
--- NB! pcall inside coroutine can catch this error
--- so coroutine may not be cancelled because of pcall.
---
--- ## Example
--- ```lua
--- ---@async
--- local function work()
---     while true do
---        print( "working" )
---        futures.sleep( 1 )
---     end
--- end
---
--- local co = futures.run( work, function(ok, value )
---     -- because we cancelled coroutine
---     -- ok will be false
---     -- value will be CancelError
--- end)
---
--- futures.cancel( co ) -- this will stop coroutine from executing
--- ```
---@param co thread
function futures.cancel( co )
    local status = coroutine.status( co )
    if status == "suspended" then
        coroutine.resume( co, ACTION_CANCEL )
    elseif status == "normal" and futures.running() then
        -- let's hope that passed coroutine resumed us
        ---@diagnostic disable-next-line: await-in-sync
        coroutine.yield( ACTION_CANCEL )
    elseif status == "running" then
        error( "Operation was cancelled" ) -- TODO: use error
    end
end


--- Puts current coroutine to sleep for given amount of seconds
--- uses internally `timer.simple`.
---
---@see gpm.std.futures.pending
---@see gpm.std.futures.wakeup
---@async
---@param seconds number
function futures.sleep( seconds )
    local co = futures.running()

    timer_simple( seconds, function()
        futures.wakeup( co )
    end )

    return futures.pending()
end


--- Transfers data between coroutines in symmetrical way
--- used in asynchronous iterators
--- you probably should not use it.
---
---@see gpm.std.futures.apairs for example
---@async
---@param co thread
---@param ... any
---@return boolean success
---@return any ...
function futures.transfer( co, ... )
    local status = coroutine.status( co )
    if status == "suspended" then
        return coroutine.resume( co, ... )
    elseif status == "normal" then
        return true, coroutine.yield(...)
    elseif status == "running" then
        return false, "cannot transfer to a running coroutine"
    else
        return false, "thread is dead"
    end
end


---@async
local function handleYield( ok, value, ... )
    -- ignore errors, they must be handled by whoever calls us
    if not ok or value == RESULT_ERROR then
        return
    end

    if value == ACTION_CANCEL then
        return error( "Operation was cancelled" ) -- TODO: use error
    elseif value == ACTION_RESUME then
        return ...
    elseif value ~= nil then
        error( "invalid yield action: " .. tostring( value ), -2 )
    else
        -- caller probably went sleeping
        return handleYield( true, coroutine.yield() )
    end
end

--- Yields given arguments to the apairs listener.
---
---@see gpm.std.futures.apairs for example
---@async
function futures.yield( ... )
    local listener = futures.coroutine_listeners[ futures.running() ]
    if listener then
        return handleYield( futures.transfer( listener, RESULT_YIELD, ... ) )
    else
        -- whaat? we don't have a listener?!
        error( "Operation was cancelled" ) -- TODO: use error
    end
end


---@async
local function asyncIteratableThread( fn, ... )
    coroutine.yield() -- wait until anext wakes us up
    local ok, err = pcall( fn, ... )

    local listener = futures.coroutine_listeners[ futures.running() ]
    if listener then
        if ok then
            futures.transfer( listener, RESULT_END )
        else
            futures.transfer( listener, RESULT_ERROR, err )
        end
    elseif not ok then
        error( err )
    end
end

---@async
---@param co thread
---@param ok boolean
local function handleAnext( co, ok, value, ... )
    if not ok then
        return error( ok )
    end

    if value == RESULT_YIELD then
        return ...
    elseif value == RESULT_END then
        return -- return nothing so for loop with be stopped
    elseif value == RESULT_ERROR then
        return error( ... )
    elseif value ~= nil then
        error( "invalid anext result: " .. tostring( value ), -2 )
    end

    -- iterator went sleeping, wait until it wakes us up
    return handleAnext( co, true, coroutine.yield() )
end

--- Retrieves next value from async iterator coroutine
--- this function returned by apairs
--- you probably should not use it.
---
---@see gpm.std.futures.apairs for example
---@async
---@param iterator thread
function futures.anext( iterator, ... )
    return handleAnext( iterator, futures.transfer( iterator, ACTION_RESUME, ... ) )
end

--- Iterates over async iterator, calling it with given arguments.
---
--- ## Example
--- ```lua
--- ---@async
--- ---@return AsyncIterator<number>
--- local function count( from, to )
---     for i = from, to do
---         futures.yield( i )
---     end
--- end
---
--- local function main()
---     for i in futures.apairs( count, 1, 5 ) do
---         print( i ) -- 1, 2, 3, 4, 5
---     end
--- end
---
--- futures.run( main )
--- ```
---@see gpm.std.futures.yield
---@see gpm.std.futures.AsyncIterator
---@async
---@generic K, V
---@param iterator async fun(...): gpm.std.futures.AsyncIterator<K, V>
---@return async fun(...): K, V
---@return thread
function futures.apairs( iterator, ... )
    local co = coroutine.create( asyncIteratableThread)
    futures.coroutine_listeners[ co ] = futures.running()
    coroutine.resume( co, iterator, ... )
    return futures.anext, co
end


--- Collects all values from async iterator into a list.
---@async
---@generic V
---@param iterator async fun(...): gpm.std.futures.AsyncIterator<V>
---@return V[] results
---@return number length
function futures.collect( iterator, ... )
    local results, length = {}, 0
    for value in futures.apairs( iterator, ... ) do
        length = length + 1
        results[ length ] = value
    end

    return results, length
end

--- Collects all values from async iterator into a table.
---@async
---@generic K, V
---@param iterator async fun(...): gpm.std.futures.AsyncIterator<K, V>
---@return table<K, V> result
function futures.collectTable( iterator, ... )
    local result = {}
    for k, v in futures.apairs( iterator, ... ) do
        result[ k ] = v
    end

    return result
end

do

    ---@alias Future gpm.std.futures.Future

    --- Futures are objects that hold the result that can be assigned asynchronously
    --- they can be awaited to get the result
    --- or add callback with :addCallback(...) method.
    ---
    --- ```lua
    --- local fut = futures.Future()
    ---
    --- fut:addCallback( function( fut )
    ---     print( fut:result() ) -- "hello world"
    --- end )
    ---
    --- fut:setResult( "hello world" )
    ---
    --- -- or you can await it
    ---
    --- ---@async
    --- local function main()
    ---     print( fut:await() ) -- "hello world"
    --- end
    ---
    --- futures.run( main )
    ---
    --- -- also you can set error or cancel it
    --- fut:setError( "something went wrong" )
    --- fut:cancel()
    --- ```
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

    Future.STATE_PENDING = STATE_PENDING or Symbol( "Future.STATE_PENDING" )
    Future.STATE_FINISHED = STATE_FINISHED or Symbol( "Future.STATE_FINISHED" )
    Future.STATE_CANCELLED = STATE_CANCELLED or Symbol( "Future.STATE_CANCELLED" )

    ---@protected
    function Future:__init()
        self._state = STATE_PENDING
        self._callbacks = {}
    end

    ---@protected
    function Future:__tostring()
        if self:isFinished() then
            if self:isCancelled() then
                return self.__name .. "( cancelled )"
            elseif self._error then
                return self.__name .. "( finished error = " .. tostring( self._error ) .. " )"
            else
                return self.__name .. "( finished value = " .. tostring( self._result ) .. " )"
            end
        else
            return self.__name .. "( pending )"
        end
    end

    --- Returns `true` if Future is pending.
    ---@return boolean
    function Future:isPending()
        return self._state == STATE_PENDING
    end

    --- Returns `true` if Future is finished (or cancelled).
    ---@return boolean
    function Future:isFinished()
        return self._state ~= STATE_PENDING
    end

    --- Returns true if Future was cancelled.
    ---@return boolean
    function Future:isCancelled()
        return self._state == STATE_CANCELLED
    end

    ---@private
    function Future:runCallbacks()
        local callbacks = self._callbacks

        -- TODO: is this can be nil or false? or why this is here.
        if not callbacks then
            return
        end

        self._callbacks = {}
        for i = 1, #callbacks, 1 do
            xpcall( callbacks[ i ], displayError, self )
        end
    end

    --- Adds callback that will be called when future is done
    --- if future is already done, callback will be called immediately.
    ---
    ---@see gpm.std.futures.Future.removeCallback for removing callback
    ---@param fn fun(fut: gpm.std.futures.Future)
    function Future:addCallback( fn )
        if self:isFinished() then
            xpcall( fn, displayError, self )
        else
            self._callbacks[ #self._callbacks + 1 ] = fn
        end
    end

    --- Removes callback that was previously added with `:addCallback`.
    ---
    ---@see gpm.std.futures.Future.addCallback for adding callback
    ---@param fn function
    function Future:removeCallback( fn )
        local callbacks = {}
        for i = 1, #self._callbacks do
            local cb = self._callbacks[ i ]
            if cb ~= fn then
                callbacks[ #callbacks + 1 ] = cb
            end
        end

        self._callbacks = callbacks
    end

    --- Sets result of the Future, marks it as finished, and runs all callbacks
    --- if future is already finished, error will be thrown.
    ---
    ---@see gpm.std.futures.Future.result to retrieve result
    ---@see gpm.std.futures.Future.await to asynchronously retrieve result
    ---@param result any
    function Future:setResult( result )
        if self:isFinished() then
            error( "future is already finished", 2 )
        end

        self._result = result
        self._state = STATE_FINISHED
        self:runCallbacks()
    end

    --- Sets error of the Future, marks it as finished, and runs all callbacks
    --- if future is already finished, error will be thrown.
    ---@param err any
    function Future:setError( err )
        if self:isFinished() then
            error( "future is already finished", 2 )
        end

        self._error = err
        self._state = STATE_FINISHED
        self:runCallbacks()
    end

    --- Tries to cancel future, if it's already done, returns `false`
    --- otherwise marks it as cancelled, runs all callbacks and returns `true`.
    ---@return boolean cancelled
    function Future:cancel()
        if self:isFinished() then
            return false
        end

        self._state = STATE_CANCELLED
        self:runCallbacks()
        return true
    end

    --- Returns error if future is finished and has error
    --- otherwise returns nil
    --- if future is not finished or cancelled, returns error.
    ---
    ---@see gpm.std.futures.Future.setError
    ---@return unknown?
    function Future:error()
        if self:isCancelled() then
            return "future was cancelled"
        elseif not self:isFinished() then
            return "future is not finished"
        end

        return self._error
    end

    --- Returns result if future is finished
    --- otherwise throws an error.
    ---@see gpm.std.futures.Future.setResult
    ---@return any
    function Future:result()
        if self:isCancelled() then
            return error( "future was cancelled" )
        elseif not self:isFinished() then
            return error( "future is not finished" )
        end

        if self._error then
            error( self._error )
        else
            return self._result
        end
    end

    --- Await until future will be finished
    --- if it contains an error, then it will be thrown.
    ---@async
    ---@return any
    function Future:await()
        if not self:isFinished() then
            local co = futures.running()
            self:addCallback( function() futures.wakeup( co ) end )
            futures.pending()
        end

        if self:isFinished() then
            return self:result()
        else
            error( "future hasn't changed it's state wtf???" )
        end
    end

    ---@class gpm.std.futures.FutureClass : gpm.std.futures.Future
    ---@field __base Future
    ---@overload fun(): gpm.std.futures.Future
    futures.Future = class.create( Future )

end

do

    ---@diagnostic disable-next-line: duplicate-doc-alias
    ---@alias Task gpm.std.futures.Task
    --- Task is a Future wrapper around futures.run(...) to retrieve result of async function
    --- when task is created, it will immediately run given function.
    ---
    --- ## Example
    --- ```lua
    --- local function request( url )
    ---     -- asynchronous work....
    ---     return body
    --- end
    ---
    --- local task = futures.Task( request, "https://example.com" )
    --- task:addCallback( function( task )
    ---     local body = task:result()
    ---     print( body ) -- <!DOCTYPE html>...
    --- end )
    --- ```
    ---@class gpm.std.futures.Task : gpm.std.futures.Future
    ---@field __class gpm.std.futures.TaskClass
    ---@field __parent gpm.std.futures.Future
    ---@field private setResult fun(self, result)
    ---@field private setError fun(self, error)
    local Task = futures.Task and futures.Task.__base or class.base( "Task", futures.Future )

    ---@protected
    ---@param fn async fun(...): any
    function Task:__init( fn, ... )
        self.__parent.__init( self )

        futures.run( fn, function( ok, value )
            if ok then
                self:setResult( value )
            else
                self:setError( value )
                -- TODO: check if error is cancel
            end
        end, ... )
    end

    ---@class gpm.std.futures.TaskClass : gpm.std.futures.Task
    ---@field __base gpm.std.futures.Task
    ---@overload fun(fn: async fun(...): any, ...: any): gpm.std.futures.Task
    futures.Task = class.create( Task )

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
    local Channel = futures.Channel and futures.Channel.__base or class.base( "Channel" )

    ---@protected
    ---@param maxSize number?
    function Channel:__init( maxSize )
        if maxSize and maxSize < 0 then
            error( "maxSize must be greater or equal to 0" )
        end

        self._maxsize = maxSize or 0
        self._queue = Queue()
        self._getters = Queue()
        self._setters = Queue()
        self._closed = false
    end

    ---@return number length
    function Channel:len()
        return self._queue:GetLength()
    end

    ---@return boolean isEmpty
    function Channel:empty()
        return self._queue:IsEmpty()
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
        while not self._getters:IsEmpty() do
            futures.wakeup( self._getters:Pop() )
        end

        while not self._setters:IsEmpty() do
            futures.wakeup( self._setters:Pop() )
        end
    end

    ---@return boolean isClosed
    function Channel:closed()
        return self._closed
    end

    ---@param value any
    ---@return boolean success
    function Channel:putNow( value )
        if self:full() or self:closed() or value == nil then
            return false
        end

        self._queue:Append( value )

        local getter = self._getters:Pop()
        if getter then
            futures.wakeup( getter )
        end

        return true
    end

    ---@async
    ---@param value any
    ---@param wait boolean?
    ---@return boolean success
    function Channel:put( value, wait )
        while wait ~= false and ( self:full() and not self:closed() ) do
            self._setters:Append( futures.running() )
            futures.pending()
        end

        return self:putNow(value)
    end

    function Channel:getNow()
        if self:empty() or self:closed() then
            return nil
        end

        local value = self._queue:Pop()

        local setter = self._setters:Pop()
        if setter then
            futures.wakeup( setter )
        end

        return value
    end

    ---@async
    ---@param wait boolean?
    function Channel:get( wait )
        while wait ~= false and self:empty() and not self:closed() do
            self._getters:Append( futures.running() )
            futures.pending()
        end

        return self:getNow()
    end

    ---@class gpm.std.futures.ChannelClass : gpm.std.futures.Channel
    ---@field __base gpm.std.futures.Channel
    ---@overload fun(maxsize: number?): gpm.std.futures.Channel
    futures.Channel = class.create( Channel )

end

--- TODO: add helper function, i.e. futures.all, futures.any

return futures
