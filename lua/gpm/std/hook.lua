local _G = _G
local gpm = _G.gpm
local std = gpm.std

local table = std.table
local table_removeByRange = table.removeByRange

--[[

    Event structure
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
local Hook = std.class.base( "Hook" )

---@class gpm.std.HookClass: gpm.std.Hook
---@field __base gpm.std.Hook
---@overload fun( name: string?, returns_vararg: boolean? ): Hook
local HookClass = std.class.create( Hook )

do

    local string_format = std.string.format

    function Hook:__tostring()
        return string_format( "Hook: %p [%s]", self, self[ -2 ] )
    end

end

do

    local engine_hooks = {}
    setmetatable( engine_hooks, { __mode = "v" } )

    local glua_hook = _G.hook
    if glua_hook ~= nil then
        local hook_Call = glua_hook.Call
        if hook_Call ~= nil then
            glua_hook.Call = gpm.detour.attach( hook_Call, function( fn, event_name, gamemode_table, ... )
                local hook = engine_hooks[ event_name ]
                if hook ~= nil then
                    ---@cast hook Hook
                    local a, b, c, d, e, f = hook:call( ... )
                    if a ~= nil then
                        return a, b, c, d, e, f
                    end
                end

                return fn( event_name, gamemode_table, ... )
            end )
        end
    end

    ---@param name string?: The name of the hook.
    ---@param returns_vararg boolean?: Whether the hook returns vararg.
    ---@protected
    function Hook:__init( name, returns_vararg )
        self[ -3 ] = returns_vararg == true
        self[ -2 ] = name
        self[ 0 ] = 0

        if name ~= nil then
            engine_hooks[ name ] = self
        end
    end

end

--- Detaches a callback function from the hook.
---@param identifier any: The unique name of the callback or object with `__isvalid` function in metatable.
---@return boolean: Returns `true` if the callback was detached, otherwise `false`.
function Hook:detach( identifier )
    local callback_count = self[ 0 ]
    for i = callback_count, 1, -3 do
        if self[ i ] == identifier then
            table_removeByRange( self, i, i + 2 )
            self[ 0 ] = callback_count - 3
            return true
        end
    end

    return false
end

do

    local string_meta = std.debug.findmetatable( "string" )
    local table_insert = table.insert
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
            fn = function( ... )
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

        local callback_count = self[ 0 ]

        for i = 1, callback_count, 3 do
            if self[ i ] == identifier then
                if self[ i + 2 ] == hook_type then
                    self[ i + 1 ] = fn
                    return
                end

                table_removeByRange( self, i, i + 2 )
                callback_count = callback_count - 3
                self[ 0 ] = callback_count
                break
            end
        end

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
        table_insert( self, index + 2, hook_type )
        self[ 0 ] = callback_count + 3
    end

end

do

    local function call_without_mixer_and_vararg( self, ... )
        local value
        for index = 3, self[ 0 ], 3 do
            local hook_type = self[ index ]
            if hook_type == -2 or hook_type == 2 then
                self[ index - 1 ]( ... )
            else
                value = self[ index - 1 ]( ... )
            end
        end

        return value
    end

    local function call_without_mixer( self, ... )
        local a, b, c, d, e, f
        for index = 3, self[ 0 ], 3 do
            local hook_type = self[ index ]
            if hook_type == -2 or hook_type == 2 then
                self[ index - 1 ]( ... )
            else
                a, b, c, d, e, f = self[ index - 1 ]( ... )
            end
        end

        return a, b, c, d, e, f
    end

    local function call_with_mixer( self, mixer_fn, ... )
        local old, new
        for index = 3, self[ 0 ], 3 do
            local hook_type = self[ index ]
            if hook_type == -2 or hook_type == 2 then
                self[ index - 1 ]( ... )
            else
                old, new = new, mixer_fn( old, self[ index - 1 ]( ... ) )
            end
        end

        return new
    end

    local function call_with_mixer_and_vararg( self, mixer_fn, ... )
        local a, b, c, d, e, f, g, h, i, j, k, l
        for index = 3, self[ 0 ], 3 do
            local hook_type = self[ index ]
            if hook_type == -2 or hook_type == 2 then
                self[ index - 1 ]( ... )
            else
                a, b, c, d, e, f, g, h, i, j, k, l = g, h, i, j, k, l, mixer_fn( { a, b, c, d, e, f }, { self[ index - 1 ]( ... ) } )
            end
        end

        return g, h, i, j, k, l
    end

    --- Calls the hook.
    ---@param ... any: The arguments to pass to the hook.
    ---@return any ...: The return values from the hook.
    function Hook:call( ... )
        local mixer_fn = self[ -1 ]
        if mixer_fn == nil then
            if self[ -3 ] then
                return call_without_mixer( self, ... )
            else
                return call_without_mixer_and_vararg( self, ... )
            end
        elseif self[ -3 ] then
            return call_with_mixer( self, mixer_fn, ... )
        else
            return call_with_mixer_and_vararg( self, mixer_fn, ... )
        end
    end

end

--- A return mixer that is called after any call to the hook and allows the return values to be modified.
---@param mixer_fn function?: The function to perform mixing, `nil` if no mixing is required.
function Hook:mixer( mixer_fn )
    self[ -1 ] = mixer_fn
end

return HookClass
