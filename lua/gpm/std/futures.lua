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
        return error( "Operation was cancelled" )
    else
        return value, ...
    end
end

---@async
---@return ...
function futures.pending()
    return handlePending( coroutine.yield() )
end

---@param co thread
function futures.wakeup( co, ... )
    coroutine.resume( co, ... )
end


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


---@async
---@param seconds number
function futures.sleep( seconds )
    local co = futures.running()

    timer_Simple( seconds, function()
        futures.wakeup( co )
    end )

    return futures.pending()
end


--- Transfers data between coroutines in symmetrical way
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
        return error( "Operation was cancelled" )
    elseif value == ACTION_RESUME then
        return ...
    elseif value ~= nil then
        error( "invalid yield action: " .. tostring( value ), -2 )
    else
        -- caller probably went sleeping
        return handleYield( true, coroutine.yield() )
    end
end

---@async
function futures.yield( ... )
    local listener = futures.coroutine_listeners[ futures.running() ]
    if listener then
        return handleYield( futures.transfer( listener, RESULT_YIELD, ... ) )
    else
        -- whaat? we don't have a listener?!
        error( "Operation was cancelled" )
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

---@async
---@param iterator thread
function futures.anext( iterator, ... )
    return handleAnext( iterator, futures.transfer( iterator, ACTION_RESUME, ... ) )
end

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


--- Launches given iterator and collects its results into a table
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

--- Collects all values from async iterator into a table
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
        if self:done() then
            if self:cancelled() then
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

        -- TODO: is this can be nil or false? or why this is here
        if not callbacks then
            return
        end

        self._callbacks = {}
        for i = 1, #callbacks, 1 do
            xpcall( callbacks[ i ], displayError, self )
        end
    end

    ---@param fn fun(fut: gpm.std.futures.Future)
    function Future:addCallback( fn )
        if self:done() then
            xpcall( fn, displayError, self )
        else
            self._callbacks[ #self._callbacks + 1 ] = fn
        end
    end

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

    ---@param result any
    function Future:setResult( result )
        if self:done() then
            error( "future is already finished", 2 )
        end

        self._result = result
        self._state = STATE_FINISHED
        self:runCallbacks()
    end

    ---@param err any
    function Future:setError( err )
        if self:done() then
            error( "future is already finished", 2 )
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
            error( self._error )
        else
            return self._result
        end
    end

    ---@async
    ---@return any
    function Future:await()
        if not self:done() then
            local co = futures.running()
            self:addCallback( function() futures.wakeup( co ) end )
            futures.pending()
        end

        if self:done() then
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

--- TODO: add description for all classes in this file

return futures
