---@class dreamwork
local dreamwork = _G.dreamwork

---@class dreamwork.std
local std = dreamwork.std

local class = std.class
local table_remove = std.table.remove
local string_format = std.string.format

do

    --- [SHARED AND MENU]
    ---
    --- A stack is a last-in-first-out (LIFO) data structure object.
    ---
    ---@class dreamwork.std.Stack : dreamwork.std.Object
    ---@field __class dreamwork.std.StackClass
    local Stack = class.base( "Stack" )

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
    ---@class dreamwork.std.StackClass : dreamwork.std.Stack
    ---@field __base dreamwork.std.Stack
    ---@overload fun(): dreamwork.std.Stack
    local StackClass = class.create( Stack )
    std.Stack = StackClass

    ---@diagnostic disable-next-line: duplicate-doc-alias
    ---@alias Stack dreamwork.std.Stack

end

do

    --- [SHARED AND MENU]
    ---
    --- A queue is a first-in-first-out (FIFO) data structure object.
    ---
    ---@class dreamwork.std.Queue : dreamwork.std.Object
    ---@field __class dreamwork.std.QueueClass
    local Queue = class.base( "Queue" )

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
    ---@return dreamwork.std.Queue queue The queue being iterated over.
    ---@return boolean fromBack `true` if the iterator is for the back of the queue.
    function Queue:iterator( fromBack )
        return self.pop, self, fromBack == true
    end

    --- [SHARED AND MENU]
    ---
    --- A queue class.
    ---
    ---@class dreamwork.std.QueueClass : dreamwork.std.Queue
    ---@field __base dreamwork.std.Queue
    ---@overload fun(): dreamwork.std.Queue
    local QueueClass = class.create( Queue )
    std.Queue = QueueClass

    ---@alias Queue dreamwork.std.Queue

end

do

    --- [SHARED AND MENU]
    ---
    --- A node.
    ---
    ---@class dreamwork.std.Node : dreamwork.std.Object
    ---@field __class dreamwork.std.NodeClass
    ---@field value any The value of the node.
    ---@field parent dreamwork.std.Node The parent node of the node.
    ---@field depth number The depth of the node in the tree.
    ---@field width number The width of the node in the tree.
    local Node = class.base( "Node" )

    ---@protected
    ---@return string
    function Node:__tostring()
        return string_format( "Node: %p [%s][%d]", self, self.value, self.depth )
    end

    ---@protected
    function Node:__init( value, parent )
        self.depth, self.width = 0, 0
        self.value = value

        if parent ~= nil then
            self:link( parent )
        end
    end

    --- [SHARED AND MENU]
    ---
    --- Unlinks the node from its parent.
    ---
    function Node:unlink()
        local parent = self.parent
        self.parent = nil

        if parent ~= nil then

            local width = parent.width

            for index = width, 1, -1 do
                if parent[ index ] == self then
                    table_remove( parent, index )
                    width = width - 1
                end
            end

            parent.width = width

        end

        self.depth = 0

        for index = 1, self.width, 1 do
            self[ index ]:link( self )
        end
    end

    --- [SHARED AND MENU]
    ---
    --- Links the node to a parent node.
    ---
    ---@param parent dreamwork.std.Node The parent node to link to.
    function Node:link( parent )
        local width = parent.width
        for index = 1, width, 1 do
            local child = parent[ index ]
            if child == self then
                self.depth = parent.depth + 1
                return
            end
        end

        local sub_parent = parent
        while sub_parent ~= nil do
            if sub_parent == self then
                error( "child node cannot be parent", 2 )
            end

            sub_parent = sub_parent.parent
        end

        self.depth = parent.depth + 1
        self.parent = parent

        width = width + 1
        parent[ width ] = self
        parent.width = width
    end

    --- [SHARED AND MENU]
    ---
    --- Traverses the node tree.
    ---
    ---@param callback fun( node: dreamwork.std.Node ) The callback function.
    function Node:traverse( callback )
        callback( self )

        for index = 1, self.width, 1 do
            self[ index ]:traverse( callback )
        end
    end

    --- [SHARED AND MENU]
    ---
    --- Returns the size of the node tree.
    ---
    ---@return integer size The size of the node tree.
    function Node:size()
        local size = 1

        for index = 1, self.width, 1 do
            size = size + self[ index ]:size()
        end

        return size
    end

    --- [SHARED AND MENU]
    ---
    --- A node class.
    ---
    ---@class dreamwork.std.NodeClass : dreamwork.std.Node
    ---@field __base dreamwork.std.Node
    ---@overload fun( value: any, parent: dreamwork.std.Node? ): dreamwork.std.Node
    local NodeClass = class.create( Node )
    std.Node = NodeClass

end

do

    local debug = std.debug
    local debug_newproxy = debug.newproxy
    local debug_getmetatable = debug.getmetatable

    --- [SHARED AND MENU]
    ---
    --- A symbol.
    ---
    ---@class dreamwork.std.Symbol : userdata

    ---@alias Symbol dreamwork.std.Symbol

    local base = dreamwork.__symbol or debug_newproxy( true )
    dreamwork.__symbol = base

    local metatable = debug_getmetatable( base )
    if metatable == nil then
        error( "userdata metatable is missing, lol wtf" )
    end

    metatable.__type = "Symbol"

    ---@type table<dreamwork.std.Symbol, string>
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
    ---@return dreamwork.std.Symbol obj The new symbol.
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
