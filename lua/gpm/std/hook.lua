local _G = _G
local gpm = _G.gpm
local std = gpm.std

local table = std.table
local table_insert = table.insert

--[[

    Event structure
    [-6] - attached list
    [-5] - detached list
    [-4] - is in call
    [-3] - returns vararg
    [-2] - engine hook name
    [-1] - mixer function
    [0] - last callback index

    [1] - identifier
    [2] - function
    [3] - hook_type

    [4] - identifier
    [5] - function
    [6] - hook_type

    [7] - identifier
    [8] - function
    [9] - hook_type

    ...

]]

---@alias gpm.std.HOOK_TYPE
---| number # The type of the hook.
---| `-2` # PRE_HOOK - This hook is guaranteed to be called under all circumstances, and cannot be interrupted by a return statement. You can rely on its consistent execution.
---| `-1` # PRE_HOOK_RETURN - Consider a scenario where you have an admin mod that checks for "!menu". In this case, your hook might not be called before it.
---| `0` # NORMAL_HOOK - This hook is called after the normal hook, but before the post hook.
---| `1` # POST_HOOK_RETURN - This allows for the modification of results returned from preceding hooks!
---| `2` # POST_HOOK - This hook is guaranteed to be called under all circumstances, and cannot be interrupted by a return statement. You can rely on its consistent execution.

---@alias Hook gpm.std.Hook
---@class gpm.std.Hook: gpm.std.Object
---@field __class gpm.std.HookClass
local Hook = std.Hook ~= nil and std.Hook.__base or std.class.base( "Hook" )

---@class gpm.std.HookClass: gpm.std.Hook
---@field __base gpm.std.Hook
---@overload fun( engine_name: string?, returns_vararg: boolean? ): Hook
local HookClass = std.Hook or std.class.create( Hook )

do

    local string_format = std.string.format

    function Hook:__tostring()
        return string_format( "Hook: %p [%s]", self, self[ -2 ] )
    end

end

do

    local engine_hooks = {}
    setmetatable( engine_hooks, { __mode = "v" } )

    ---@param engine_name string?: The name of the hook in the engine.
    ---@param returns_vararg boolean?: Whether the hook returns vararg.
    ---@protected
    function Hook:__init( engine_name, returns_vararg )
        self[ 0 ], self[ -3 ], self[ -4 ] = 0, returns_vararg == true, false

        if engine_name == nil then
            engine_name = "unnamed"
        else
            engine_hooks[ engine_name ] = self
        end

        self[ -2 ] = engine_name
    end

    local hook = _G.hook
    if hook == nil then
        ---@diagnostic disable-next-line: inject-field
        hook = {}; _G.hook = hook
    end

    local hook_Call = hook.Call
    if hook_Call == nil then
        function hook.Call( event_name, _, ... )
            local obj = engine_hooks[ event_name ]
            if obj == nil then return nil end

            ---@cast obj Hook
            local a, b, c, d, e, f = obj:call( ... )
            if a == nil then return nil end

            return a, b, c, d, e, f
        end
    else
        hook.Call = gpm.detour.attach( hook_Call, function( fn, event_name, gamemode_table, ... )
            local obj = engine_hooks[ event_name ]
            if obj ~= nil then
                ---@cast obj Hook
                local a, b, c, d, e, f = obj:call( ... )
                if a ~= nil then return a, b, c, d, e, f end
            end

            return fn( event_name, gamemode_table, ... )
        end )
    end

end

do

    local table_removeByRange = table.removeByRange
    local debug_fempty = std.debug.fempty

    --- Detaches a callback function from the hook.
    ---@param identifier any: The unique name of the callback or object with `__isvalid` function in metatable.
    ---@return boolean: Returns `true` if the callback was detached, otherwise `false`.
    function Hook:detach( identifier )
        for i = self[ 0 ] - 2, 1, -3 do
            if self[ i ] == identifier then
                if self[ -4 ] then
                    self[ i + 1 ] = debug_fempty

                    local detach = self[ -5 ]
                    if detach == nil then
                        self[ -5 ] = { identifier }
                    else
                        table_insert( detach, identifier )
                    end
                else
                    table_removeByRange( self, i, i + 2 )
                    self[ 0 ] = self[ 0 ] - 3
                end

                return true
            end
        end

        return false
    end

end

do

    local string_meta = std.debug.findmetatable( "string" )
    local math_clamp = std.math.clamp

    --- Attaches a callback function to the hook.
    ---@param identifier any: The unique name of the callback or object with `__isvalid` function in metatable.
    ---@param fn function: The callback function.
    ---@param hook_type gpm.std.HOOK_TYPE?: The type of the hook, default is `0`.
    function Hook:attach( identifier, fn, hook_type )
        local metatable = getmetatable( identifier )
        if metatable == nil then
            error( "Invalid callback identifier, it should be a string or a valid object.", 2 )
        end

        if metatable ~= string_meta then
            local isvalid = metatable.__isvalid
            if isvalid == nil then
                error( "Invalid callback identifier, there should be a `__isvalid` function in its metatable.", 2 )
            end

            if not isvalid( identifier ) then
                self:detach( identifier )
                return
            end

            local callback_fn = fn
            function fn( ... )
                if isvalid( identifier ) then
                    return callback_fn( identifier, ... )
                end

                self:detach( identifier )
            end
        end

        if hook_type == nil then
            hook_type = 0
        else
            hook_type = math_clamp( hook_type, -2, 2 )
        end

        for i = self[ 0 ] - 2, 1, -3 do
            if self[ i ] == identifier then
                if self[ i + 2 ] == hook_type then
                    self[ i + 1 ] = fn
                    return
                end

                self:detach( identifier )
                break
            end
        end

        if self[ -4 ] then
            local attach = self[ -6 ]
            if attach == nil then
                self[ -6 ] = { { identifier, fn, hook_type } }
            else
                table_insert( attach, { identifier, fn, hook_type } )
            end

            return
        end

        local callback_count = self[ 0 ]

        local index = callback_count
        for i = 3, callback_count, 3 do
            if self[ i ] > hook_type then
                index = ( i - 3 )
                break
            end
        end

        index = index + 1

        table_insert( self, index, identifier )
        table_insert( self, index + 1, fn )
        self[ 0 ] = table_insert( self, index + 2, hook_type )
    end

end

do

    --- Stops the hook.
    ---@return boolean: Returns `true` if the hook was stopped, otherwise `false`.
    local function hook_stop( self )
        if not self[ -4 ] then return false end
        self[ -4 ] = false

        local detach = self[ -5 ]
        if detach ~= nil then
            self[ -5 ] = nil

            for i = 1, #detach, 1 do
                self:detach( detach[ i ] )
            end
        end

        local attach = self[ -6 ]
        if attach ~= nil then
            self[ -6 ] = nil

            for i = 1, #attach, 1 do
                local data = attach[ i ]
                self:attach( data[ 1 ], data[ 2 ], data[ 3 ] )
            end
        end

        return true
    end

    Hook.stop = hook_stop

    local function call_without_mixer_and_vararg( self, ... )
        local value
        for index = 3, self[ 0 ], 3 do
            local hook_type = self[ index ]
            if hook_type == -2 or hook_type == 2 then
                self[ index - 1 ]( ... )
            elseif self[ -4 ] then
                value = self[ index - 1 ]( ... )
            end
        end

        hook_stop( self )
        return value
    end

    local function call_without_mixer( self, ... )
        local a, b, c, d, e, f
        for index = 3, self[ 0 ], 3 do
            local hook_type = self[ index ]
            if hook_type == -2 or hook_type == 2 then
                self[ index - 1 ]( ... )
            elseif self[ -4 ] then
                a, b, c, d, e, f = self[ index - 1 ]( ... )
            end
        end

        hook_stop( self )
        return a, b, c, d, e, f
    end

    local function call_with_mixer( self, mixer_fn, ... )
        local old, new
        for index = 3, self[ 0 ], 3 do
            local hook_type = self[ index ]
            if hook_type == -2 or hook_type == 2 then
                self[ index - 1 ]( ... )
            elseif self[ -4 ] then
                old, new = new, self[ index - 1 ]( ... )
                new = mixer_fn( old, new ) or new
            end
        end

        hook_stop( self )
        return new
    end

    local function call_with_mixer_and_vararg( self, mixer_fn, ... )
        local old1, old2, old3, old4, old5, old6, new1, new2, new3, new4, new5, new6
        for index = 3, self[ 0 ], 3 do
            local hook_type = self[ index ]
            if hook_type == -2 or hook_type == 2 then
                self[ index - 1 ]( ... )
            elseif self[ -4 ] then
                old1, old2, old3, old4, old5, old6, new1, new2, new3, new4, new5, new6 = new1, new2, new3, new4, new5, new6, self[ index - 1 ]( ... )
                local mixed1, mixed2, mixed3, mixed4, mixed5, mixed6 = mixer_fn( { old1, old2, old3, old4, old5, old6 }, { new1, new2, new3, new4, new5, new6 } )
                if mixed1 ~= nil then new1, new2, new3, new4, new5, new6 = mixed1, mixed2, mixed3, mixed4, mixed5, mixed6 end
            end
        end

        hook_stop( self )
        return new1, new2, new3, new4, new5, new6
    end

    --- Calls the hook.
    ---@param ... any: The arguments to pass to the hook.
    ---@return any ...: The return values from the hook.
    function Hook:call( ... )
        self[ -4 ] = true

        local mixer_fn = self[ -1 ]
        if mixer_fn == nil then
            if self[ -3 ] then
                return call_without_mixer( self, ... )
            else
                return call_without_mixer_and_vararg( self, ... )
            end
        elseif self[ -3 ] then
            return call_with_mixer_and_vararg( self, mixer_fn, ... )
        else
            return call_with_mixer( self, mixer_fn, ... )
        end
    end

end

--- A return mixer that is called after any call to the hook and allows the return values to be modified.
---@param mixer_fn function?: The function to perform mixing, `nil` if no mixing is required.
function Hook:mixer( mixer_fn )
    self[ -1 ] = mixer_fn
end

return HookClass
