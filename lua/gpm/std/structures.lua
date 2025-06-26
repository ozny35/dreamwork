---@class gpm
local gpm = _G.gpm

---@class gpm.std
local std = gpm.std

do

    --- [SHARED AND MENU]
    ---
    --- A stack is a last-in-first-out (LIFO) data structure object.
    ---
    ---@class gpm.std.Stack : gpm.std.Object
    ---@field __class gpm.std.StackClass
    local Stack = std.class.base( "Stack" )

    ---@protected
    function Stack:__init()
        self[ 0 ] = 0
    end

    --- [SHARED AND MENU]
    ---
    --- Checks if the stack is empty.
    ---
    ---@return boolean
    function Stack:isEmpty()
        return self[ 0 ] == 0
    end

    --- [SHARED AND MENU]
    ---
    --- Pushes a value onto the stack.
    ---
    ---@param value any The value to push onto the stack.
    ---@return integer position The position of the value in the stack.
    function Stack:push( value )
        local position = self[ 0 ] + 1
        self[ 0 ], self[ position ] = position, value
        return position
    end

    --- [SHARED AND MENU]
    ---
    --- Pops the value from the top of the stack.
    ---
    ---@return any value The value that was removed from the stack.
    function Stack:pop()
        local position = self[ 0 ]
        if position == 0 then
            return nil
        end

        self[ 0 ] = position - 1

        local value = self[ position ]
        self[ position ] = nil
        return value
    end

    --- [SHARED AND MENU]
    ---
    --- Returns the value at the top of the stack.
    ---
    ---@return any value The value at the top of the stack.
    function Stack:peek()
        return self[ self[ 0 ] ]
    end

    --- [SHARED AND MENU]
    ---
    --- Empties the stack.
    ---
    function Stack:empty()
        for i = 1, self[ 0 ], 1 do
            self[ i ] = nil
        end

        self[ 0 ] = 0
    end

    --- [SHARED AND MENU]
    ---
    --- Returns an iterator for the stack.
    ---
    ---@return function iterator The iterator function.
    ---@return Stack stack The stack being iterated over.
    function Stack:iterator()
        return self.pop, self
    end

    --- [SHARED AND MENU]
    ---
    --- A stack class.
    ---
    ---@class gpm.std.StackClass : gpm.std.Stack
    ---@field __base gpm.std.Stack
    ---@overload fun(): gpm.std.Stack
    local StackClass = std.class.create( Stack )
    std.Stack = StackClass

    ---@diagnostic disable-next-line: duplicate-doc-alias
    ---@alias Stack gpm.std.Stack

end

do

    --- [SHARED AND MENU]
    ---
    --- A queue is a first-in-first-out (FIFO) data structure object.
    ---
    ---@class gpm.std.Queue : gpm.std.Object
    ---@field __class gpm.std.QueueClass
    local Queue = std.class.base( "Queue" )

    ---@protected
    function Queue:__init()
        self.front = 0
        self.back = 0
    end

    --- [SHARED AND MENU]
    ---
    --- Returns the length of the queue.
    ---
    ---@return integer length The length of the queue.
    function Queue:getLength()
        return self.front - self.back
    end

    --- [SHARED AND MENU]
    ---
    --- Checks if the queue is empty.
    ---
    ---@return boolean isEmpty Returns true if the queue is empty.
    function Queue:isEmpty()
        return self.front == self.back
    end

    --- [SHARED AND MENU]
    ---
    --- Empties the queue.
    ---
    function Queue:empty()
        for i = self.back + 1, self.front, 1 do
            self[ i ] = nil
        end

        self.front = 0
        self.back = 0
    end

    --- [SHARED AND MENU]
    ---
    --- Returns the value at the front of the queue or the back if `fromBack` is `true`.
    ---
    ---@param fromBack? boolean If `true`, returns the value at the back of the queue.
    ---@return any value The value at the front of the queue.
    function Queue:peek( fromBack )
        return self[ fromBack and ( self.back + 1 ) or self.front ]
    end

    --- [SHARED AND MENU]
    ---
    --- Appends a value to the end of the queue or the front if `toFront` is `true`.
    ---
    ---@param value any The value to append.
    ---@param toFront? boolean If `true`, appends the value to the front of the queue.
    function Queue:push( value, toFront )
        if toFront then
            local back = self.back
            self[ back ] = value
            self.back = back - 1
        else
            local front = self.front + 1
            self[ front ] = value
            self.front = front
        end
    end

    --- [SHARED AND MENU]
    ---
    --- Removes and returns the value at the back of the queue or the front if `fromBack` is `true`.
    ---
    ---@param fromBack? boolean If `true`, removes and returns the value at the front of the queue.
    ---@return any value The value at the back of the queue or the front if `fromBack` is `true`.
    function Queue:pop( fromBack )
        local back, front = self.back, self.front
        if back == front then return nil end

        local value

        if fromBack then

            value = self[ front ]
            self[ front ] = nil -- unreference the value

            front = front - 1
            self.front = front

        else

            back = back + 1
            self.back = back

            value = self[ back ]
            self[ back ] = nil -- unreference the value

        end

        -- reset pointers if the queue is empty
        if back == front then
            self.front = 0
            self.back = 0
        end

        return value
    end

    --- [SHARED AND MENU]
    ---
    --- Returns an iterator for the queue.
    ---
    ---@param fromBack? boolean If `true`, returns an iterator for the back of the queue.
    ---@return function iterator The iterator function.
    ---@return gpm.std.Queue queue The queue being iterated over.
    ---@return boolean fromBack `true` if the iterator is for the back of the queue.
    function Queue:iterator( fromBack )
        return self.pop, self, fromBack == true
    end

    --- [SHARED AND MENU]
    ---
    --- A queue class.
    ---
    ---@class gpm.std.QueueClass : gpm.std.Queue
    ---@field __base gpm.std.Queue
    ---@overload fun(): gpm.std.Queue
    local QueueClass = std.class.create( Queue )
    std.Queue = QueueClass

    ---@alias Queue gpm.std.Queue

end

-- symbol class
do

    local debug = std.debug

    local debug_getmetatable = debug.getmetatable
    local string_format = std.string.format
    local debug_newproxy = debug.newproxy

    --- [SHARED AND MENU]
    ---
    --- A symbol.
    ---
    ---@class gpm.std.Symbol : userdata

    ---@alias Symbol gpm.std.Symbol

    local base = gpm.__symbol or debug_newproxy( true )
    gpm.__symbol = base

    local metatable = debug_getmetatable( base )
    if metatable == nil then
        error( "userdata metatable is missing, lol wtf" )
    end

    metatable.__type = "Symbol"

    ---@type table<gpm.std.Symbol, string>
    local names = metatable.__names
    if names == nil then
        names = {}
        metatable.__names = names
        debug.gc.setTableRules( names, true, false )
    end

    ---@private
    function metatable:__tostring()
        return names[ self ]
    end

    --- [SHARED AND MENU]
    ---
    --- Creates a new symbol.
    ---
    ---@param name string The name of the symbol.
    ---@return gpm.std.Symbol obj The new symbol.
    function std.Symbol( name )
        local obj = debug_newproxy( base )
        names[ obj ] = string_format( "%s Symbol: %p", name, obj )
        return obj
    end

    --- [SHARED AND MENU]
    ---
    --- Checks if a value is a symbol.
    ---
    ---@param value any The value to check.
    function std.issymbol( value )
        return debug_getmetatable( value ) == metatable
    end

end

-- TODO: https://github.com/Nak2/NikNaks/blob/main/lua/niknaks/modules/sh_linq_module.lua
