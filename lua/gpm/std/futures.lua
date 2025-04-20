--- Python-like futures, made by Retro
local std = gpm.std

local Symbol, Queue = std.Symbol, std.Queue
local pcall, xpcall = std.pcall, std.xpcall
local isfunction = std.isfunction
local tostring = std.tostring
local class = std.class

---@type coroutinelib
local coroutine = std.coroutine
local string = std.string

local string_format = string.format

--- [SHARED AND MENU]
---
--- The futures library.
---@class gpm.std.futures
local futures = std.futures or {}

-- TODO: use errors instead of string
-- TODO: make cancel error

--[[

    Results:
        [ 0 ] = RESULT_YIELD
        [ 1 ] = RESULT_ERROR
        [ 2 ] = RESULT_END

--]]

---@private
---@type { [thread]: function }
futures.listeners = futures.listeners or setmetatable( {}, { __mode = "kv" } )

---@private
---@type { [thread]: thread }
futures.coroutine_listeners = futures.coroutine_listeners or setmetatable( {}, { __mode = "kv" } )

--- Abstract type that is used to type hint async functions
---@see gpm.std.futures.apairs for example
---@alias gpm.std.futures.AsyncIterator<K, V> table<K, V> | nil
---@alias AsyncIterator<K, V> gpm.std.futures.AsyncIterator<K, V>

---@alias gpm.std.futures.Awaitable { await: async fun(...): ... }
---@alias Awaitable gpm.std.futures.Awaitable

futures.running = coroutine.running


local function displayError( message )
    return std.error( message, -2 )
end

local asyncThreadResult
do

    local isstring = std.isstring

    ---@async
    ---@param ok boolean
    function asyncThreadResult( ok, value, ... )
        local fn = futures.listeners[ futures.running() ]
        if isfunction( fn ) then
            fn( ok, value, ... )
        elseif not ok then
            -- TODO: use errors instead of this string
            if isstring( value ) and string.find( value, "Operation was cancelled" ) then
                return
            end

            std.error( value, -2 )
        end
    end

end

---@async
local function asyncThread( fn, ... )
    return asyncThreadResult( pcall( fn, ... ) )
end

--- [SHARED AND MENU]
---
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
---     sleep( 1 )
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
        std.error( err )
        ---@diagnostic disable-next-line: missing-return
    end
end


---@async
local function handlePending( value, ... )
    if value == false then
        return std.error( "Operation was cancelled" ) -- TODO: use error
    else
        return value, ...
    end
end

--- [SHARED AND MENU]
---
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

--- [SHARED AND MENU]
---
--- Used to wake up pending coroutine.
---
---@see gpm.std.futures.pending for example
---@param co thread
function futures.wakeup( co, ... )
    coroutine.resume( co, ... )
end


--- [SHARED AND MENU]
---
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
---        sleep( 1 )
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
        coroutine.resume( co, false )
    elseif status == "normal" and futures.running() then
        -- let's hope that passed coroutine resumed us
        ---@diagnostic disable-next-line: await-in-sync
        coroutine.yield( false )
    elseif status == "running" then
        std.error( "Operation was cancelled" ) -- TODO: use error
    end
end


--- [SHARED AND MENU]
---
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
    if not ok or value == 1 then
        return
    end

    if value == false then
        return std.error( "Operation was cancelled" ) -- TODO: use error
    elseif value == true then
        return ...
    elseif value ~= nil then
        std.error( "invalid yield action: " .. tostring( value ), -2 )
    else
        -- caller probably went sleeping
        return handleYield( true, coroutine.yield() )
    end
end

--- [SHARED AND MENU]
---
--- Yields given arguments to the apairs listener.
---
---@see gpm.std.futures.apairs for example
---@async
function futures.yield( ... )
    local listener = futures.coroutine_listeners[ futures.running() ]
    if listener then
        return handleYield( futures.transfer( listener, 0, ... ) )
    else
        -- whaat? we don't have a listener?!
        std.error( "Operation was cancelled" ) -- TODO: use error
        ---@diagnostic disable-next-line: missing-return
    end
end


---@async
local function asyncIteratableThread( fn, ... )
    coroutine.yield() -- wait until anext wakes us up
    local ok, err = pcall( fn, ... )

    local listener = futures.coroutine_listeners[ futures.running() ]
    if listener then
        if ok then
            futures.transfer( listener, 2 )
        else
            futures.transfer( listener, 1, err )
        end
    elseif not ok then
        std.error( err )
    end
end

---@async
---@param co thread
---@param ok boolean
local function handleAnext( co, ok, value, ... )
    if not ok then
        return std.error( ok )
    end

    if value == 0 then
        return ...
    elseif value == 2 then
        return -- return nothing so for loop with be stopped
    elseif value == 1 then
        return std.error( ... )
    elseif value ~= nil then
        std.error( "invalid anext result: " .. tostring( value ), -2 )
    end

    -- iterator went sleeping, wait until it wakes us up
    return handleAnext( co, true, coroutine.yield() )
end

--- [SHARED AND MENU]
---
--- Retrieves next value from async iterator coroutine
--- this function returned by apairs
--- you probably should not use it.
---
---@see gpm.std.futures.apairs for example
---@async
---@param iterator thread
function futures.anext( iterator, ... )
    return handleAnext( iterator, futures.transfer( iterator, true, ... ) )
end

--- [SHARED AND MENU]
---
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


--- [SHARED AND MENU]
---
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

--- [SHARED AND MENU]
---
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

    local table = std.table

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
    local Future = futures.Future and futures.Future.__base or class.base("Future")

    --[[

        States:
            0 = PENDING
            1 = FINISHED
            2 = CANCELLED

    --]]

    --[[

        Future:
            [ 0 ] = state
            [ 1 ] = callbacks
            [ 2 ] = result
            [ 3 ] = error

    ]]

    ---@protected
    function Future:__init()
        self[ 0 ] = 0
        self[ 1 ] = {}
    end

    ---@protected
    function Future:__tostring()
        if self:isFinished() then
            if self:isCancelled() then
                return string_format( "Future: %p ( cancelled )", self )
            elseif self[ 3 ] then
                return string_format( "Future: %p ( finished error = %s )", self, tostring( self[ 3 ] ) )
            else
                return string_format( "Future: %p ( finished value = %s )", self, tostring( self[ 2 ] ) )
            end
        else
            return string_format( "Future: %p ( pending )", self )
        end
    end

    --- [SHARED AND MENU]
    ---
    --- Returns `true` if Future is pending.
    ---@return boolean
    function Future:isPending()
        return self[ 0 ] == 0
    end

    --- [SHARED AND MENU]
    ---
    --- Returns `true` if Future is finished (or cancelled).
    ---@return boolean
    function Future:isFinished()
        return self[ 0 ] ~= 0
    end

    --- [SHARED AND MENU]
    ---
    --- Returns true if Future was cancelled.
    ---@return boolean
    function Future:isCancelled()
        return self[ 0 ] == 2
    end

    --- [SHARED AND MENU]
    ---
    --- Runs all callbacks
    ---@private
    function Future:runCallbacks()
        local callbacks = self[ 1 ]
        self[ 1 ] = {}

        for i = 1, #callbacks, 1 do
            xpcall( callbacks[ i ], displayError, self )
        end
    end

    do

        local table_insert = table.insert

        --- [SHARED AND MENU]
        ---
        --- Adds callback that will be called when future is done
        --- if future is already done, callback will be called immediately.
        ---
        ---@see gpm.std.futures.Future.removeCallback for removing callback
        ---@param fn fun(fut: gpm.std.futures.Future)
        function Future:addCallback( fn )
            if self:isFinished() then
                xpcall( fn, displayError, self )
            else
                table_insert( self[ 1 ], fn )
            end
        end

    end

    do

        local table_remove = table.remove

        --- [SHARED AND MENU]
        ---
        --- Removes callback that was previously added with `:addCallback`.
        ---
        ---@see gpm.std.futures.Future.addCallback for adding callback
        ---@param value function
        function Future:removeCallback( value )
            local callbacks = self[ 1 ]
            for i = #callbacks, 1, -1 do
                if callbacks[ i ] == value then
                    table_remove( callbacks, i )
                end
            end
        end

    end

    --- [SHARED AND MENU]
    ---
    --- Sets result of the Future, marks it as finished, and runs all callbacks
    --- if future is already finished, error will be thrown.
    ---
    ---@see gpm.std.futures.Future.result to retrieve result
    ---@see gpm.std.futures.Future.await to asynchronously retrieve result
    ---@param result any
    function Future:setResult( result )
        if self:isFinished() then
            std.error( "future is already finished", 2 )
        else
            self[ 0 ], self[ 2 ] = 1, result
            self:runCallbacks()
        end
    end

    --- [SHARED AND MENU]
    ---
    --- Sets error of the Future, marks it as finished, and runs all callbacks
    --- if future is already finished, error will be thrown.
    ---@param err any
    function Future:setError( err )
        if self:isFinished() then
            std.error( "future is already finished", 2 )
        else
            self[ 0 ], self[ 3 ] = 1, err
            self:runCallbacks()
        end
    end

    --- [SHARED AND MENU]
    ---
    --- Tries to cancel future, if it's already done, returns `false`
    --- otherwise marks it as cancelled, runs all callbacks and returns `true`.
    ---@return boolean cancelled
    function Future:cancel()
        if self:isFinished() then
            return false
        else
            self[ 0 ] = 2
            self:runCallbacks()
            return true
        end
    end

    --- [SHARED AND MENU]
    ---
    --- Returns error if future is finished and has error
    --- otherwise returns nil
    --- if future is not finished or cancelled, returns error.
    ---
    ---@see gpm.std.futures.Future.setError
    ---@return unknown?
    function Future:error()
        if self:isCancelled() then
            return "future was cancelled"
        elseif self:isFinished() then
            return self[ 3 ]
        else
            return "future is not finished"
        end
    end

    --- [SHARED AND MENU]
    ---
    --- Returns result if future is finished
    --- otherwise throws an error.
    ---@see gpm.std.futures.Future.setResult
    ---@return any
    function Future:result()
        if self:isCancelled() then
            return std.error( "future was cancelled" )
        elseif self:isFinished() then
            if self[ 3 ] then
                std.error( self[ 3 ] )
            else
                return self[ 2 ]
            end
        else
            return std.error( "future is not finished" )
        end
    end

    --- [SHARED AND MENU]
    ---
    --- Await until future will be finished
    --- if it contains an error, then it will be thrown.
    ---@async
    ---@return any
    function Future:await()
        local is_finished = self:isFinished()
        if not is_finished then
            local co = futures.running()
            self:addCallback( function() futures.wakeup( co ) end )
            futures.pending()
        end

        if is_finished then
            return self:result()
        else
            std.error( "future hasn't changed it's state wtf???" )
        end
    end

    ---@class gpm.std.futures.FutureClass : gpm.std.futures.Future
    ---@field __base Future
    ---@overload fun(): gpm.std.futures.Future
    futures.Future = class.create( Future )

end

do

    --- [SHARED AND MENU]
    ---
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
    ---@overload fun( fn: ( async fun(...): any ), ...: any ): gpm.std.futures.Task
    futures.Task = class.create( Task )

end

do

    ---@alias Channel gpm.std.futures.Channel
    ---@class gpm.std.futures.Channel : gpm.std.Object
    ---@field __class gpm.std.futures.ChannelClass
    local Channel = futures.Channel and futures.Channel.__base or class.base( "Channel" )

    --[[

        [ 0 ] = max size
        [ 1 ] = queue
        [ 2 ] = getters
        [ 3 ] = setters
        [ 4 ] = closed

    ]]

    ---@protected
    ---@param maxSize number?
    function Channel:__init( maxSize )
        if maxSize and maxSize < 0 then
            std.error( "maxSize must be greater or equal to 0" )
        end

        self[ 0 ] = maxSize or 0
        self[ 1 ] = Queue()
        self[ 2 ] = Queue()
        self[ 3 ] = Queue()
        self[ 4 ] = false
    end

    --- [SHARED AND MENU]
    ---
    --- Returns the number of elements in the channel.
    ---@return number length
    function Channel:getLength()
        return self[ 1 ]:getLength()
    end

    --- [SHARED AND MENU]
    ---
    --- Returns `true` if the channel is empty, `false` otherwise.
    ---@return boolean isEmpty
    function Channel:isEmpty()
        return self[ 1 ]:isEmpty()
    end

    --- [SHARED AND MENU]
    ---
    --- Returns `true` if the channel is full, `false` otherwise.
    ---@return boolean isFull
    function Channel:isFull()
        if self[ 0 ] == 0 then
            return false
        end

        return self:getLength() >= self[ 0 ]
    end

    --- [SHARED AND MENU]
    ---
    --- Closes the channel.
    function Channel:close()
        self[ 4 ] = true

        -- wake up all getters and setters
        while not self[ 2 ]:isEmpty() do
            futures.wakeup( self[ 2 ]:pop() )
        end

        while not self[ 3 ]:isEmpty() do
            futures.wakeup( self[ 3 ]:pop() )
        end
    end

    --- [SHARED AND MENU]
    ---
    --- Returns `true` if the channel is closed, `false` otherwise.
    ---@return boolean isClosed
    function Channel:isClosed()
        return self[ 4 ]
    end

    --- [SHARED AND MENU]
    ---
    --- Puts a value into the channel, without waiting.
    ---@param value any
    ---@return boolean success
    function Channel:putNow( value )
        if self:isFull() or self[ 4 ] or value == nil then
            return false
        end

        self[ 1 ]:push( value )

        local getter = self[ 2 ]:pop()
        if getter then
            futures.wakeup( getter )
        end

        return true
    end

    --- [SHARED AND MENU]
    ---
    --- Puts a value into the channel.
    ---@async
    ---@param value any
    ---@param wait boolean?
    ---@return boolean success
    function Channel:put( value, wait )
        while wait ~= false and ( self:isFull() and not self[ 4 ] ) do
            self[ 3 ]:push( futures.running() )
            futures.pending()
        end

        return self:putNow( value )
    end

    --- [SHARED AND MENU]
    ---
    --- Gets a value from the channel, without waiting.
    function Channel:getNow()
        if self:isEmpty() or self[ 4 ] then
            return nil
        end

        local value = self[ 1 ]:pop()

        local setter = self[ 3 ]:pop()
        if setter then
            futures.wakeup( setter )
        end

        return value
    end

    --- [SHARED AND MENU]
    ---
    --- Gets a value from the channel.
    ---@async
    ---@param wait boolean?
    function Channel:get( wait )
        while wait ~= false and self:isEmpty() and not self[ 4 ] do
            self[ 2 ]:push( futures.running() )
            futures.pending()
        end

        return self:getNow()
    end

    ---@class gpm.std.futures.ChannelClass : gpm.std.futures.Channel
    ---@field __base gpm.std.futures.Channel
    ---@overload fun( maxsize: number? ): gpm.std.futures.Channel
    futures.Channel = class.create( Channel )

end

--- [SHARED AND MENU]
---
--- Awaits concurrently all given `awaitables` and returns results in table
---@async
---@param awaitables Awaitable[]
---@return any[]
local function awaitList( awaitables )
    local results = {}
    for i = 1, #awaitables do
        results[ i ] = awaitables[ i ]:await()
    end

    return results
end

--- [SHARED AND MENU]
---
--- Cancels all given awaitables.
---@param awaitables (Awaitable | { cancel: function })[]
local function cancelList( awaitables )
    for i = 1, #awaitables do
        local awaitable = awaitables[ i ]
        if isfunction( awaitable.cancel ) then
            awaitable:cancel()
        end
    end
end

--- [SHARED AND MENU]
---
--- Awaits concurrently all given `awaitables` and returns results in table
---
--- if any of awaitables throws an error, it will be thrown.
---
--- if any of awaitables if function, it will be asynchronously executed with given vararg
---
--- On error also cancels all other awaitables.
---@async
---@param awaitables Awaitable[]
---@return any[]
function futures.all( awaitables )
    local ok, result = pcall( awaitList, awaitables )
    if ok then
        return result
    else
        cancelList( awaitables )
        std.error( result )
        ---@diagnostic disable-next-line: missing-return
    end
end

--- [SHARED AND MENU]
---
--- Returns first result of futures, or error
---
--- Other awaitables will be cancelled after first result or error
---@async
---@param futureList Future[]
---@return any
function futures.any( futureList )
    local co = futures.running()
    local finished = false

    local function callback( fut )
        if not finished then
            finished = true
            futures.wakeup( co, fut )
        end
    end

    for i = 1, #futureList do
        futureList[ i ]:addCallback( callback )
    end

    ---@type Future
    local fut = futures.pending()
    cancelList( futureList )
    return fut:result()
end

return futures
