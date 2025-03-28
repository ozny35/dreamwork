local _G = _G
local gpm = _G.gpm
local std = gpm.std

local table = std.table
local getmetatable = std.getmetatable

--[[

    Event structure
    [-5] - queue list ( to add or remove callbacks ) ( table[] )
    [-4] - mixer function ( function )
    [-3] - vararg support ( boolean )
    [-2] - engine hook name ( string )
    [-1] - hook is running ( boolean )
    [0] - last callback index

    [1] - identifier ( string )
    [2] - function ( function )
    [3] - hook_type ( number )

    [4] - identifier ( string )
    [5] - function ( function )
    [6] - hook_type ( number )

    [7] - identifier ( string )
    [8] - function ( function )
    [9] - hook_type ( number )

    ...

]]

---@alias gpm.std.Hook.Type
---| number # The type of the hook.
---| `-2` # PRE_HOOK - This hook is guaranteed to be called under all circumstances, and cannot be interrupted by a return statement. You can rely on its consistent execution.
---| `-1` # PRE_HOOK_RETURN - Consider a scenario where you have an admin mod that checks for "!menu". In this case, your hook might not be called before it.
---| `0`  # NORMAL_HOOK - This hook is called after the normal hook, but before the post hook.
---| `1`  # POST_HOOK_RETURN - This allows for the modification of results returned from preceding hooks!
---| `2`  # POST_HOOK - This hook is guaranteed to be called under all circumstances, and cannot be interrupted by a return statement. You can rely on its consistent execution.

--- [SHARED AND MENU]
---
--- Hook object.
---@alias Hook gpm.std.Hook
---@class gpm.std.Hook: gpm.std.Object
---@field __class gpm.std.HookClass
local Hook = std.class.base( "Hook" )

--- [SHARED AND MENU]
---
--- Hook class.
---@class gpm.std.HookClass: gpm.std.Hook
---@field __base gpm.std.Hook
---@overload fun( name: string?, returns_vararg: boolean? ): Hook
local HookClass = std.class.create( Hook )

function Hook:__tostring()
    return std.string.format( "Hook: %p [%s][%s]", self, self[ -2 ], self[ -1 ] and "running" or "stopped" )
end

---@param name string?: The name of the hook.
---@param returns_vararg boolean?: Whether the hook returns vararg.
---@protected
function Hook:__init( name, returns_vararg )
    self[ 0 ], self[ -1 ], self[ -2 ], self[ -3 ] = 0, false, name or "unnamed", returns_vararg == true
end

do

    local debug_fempty = std.debug.fempty
    local table_eject = table.eject

    --- [SHARED AND MENU]
    ---
    --- Detaches a callback function from the hook.
    ---@param identifier string | Hook | any: The unique name of the callback, Hook or object with `__isvalid` function in metatable.
    ---@return boolean: Returns `true` if the callback was detached, otherwise `false`.
    function Hook:detach( identifier )
        if identifier == nil then return false end

        for i = self[ 0 ] - 2, 1, -3 do
            if self[ i ] == identifier then
                if self[ -1 ] then
                    self[ i + 1 ] = debug_fempty

                    local queue = self[ -5 ]
                    if queue == nil then
                        self[ -5 ] = { { false, identifier } }
                    else
                        queue[ #queue + 1 ] = { false, identifier }
                    end
                else
                    table_eject( self, i, i + 2 )
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
    local table_inject = table.inject
    local math_clamp = std.math.clamp

    --- [SHARED AND MENU]
    ---
    --- Attaches a callback function to the hook.
    ---@param identifier string | Hook | any: The unique name of the callback, Hook or object with `__isvalid` function in metatable.
    ---@param fn function | gpm.std.Hook.Type?: The callback function or the type of the hook if `identifier` is a Hook.
    ---@param hook_type gpm.std.Hook.Type?: The type of the hook, default is `0`.
    function Hook:attach( identifier, fn, hook_type )
        if identifier == nil then
            std.error( "callback identifier cannot be nil", 2 )
            return
        end

        local metatable = getmetatable( identifier )
        if metatable == nil then
            std.error( "callback identifier has no metatable", 2 )
            return
        end

        if metatable ~= string_meta then
            if metatable == Hook then
                fn, hook_type = identifier, fn
                ---@cast fn function
                ---@cast hook_type gpm.std.Hook.Type?
            else
                ---@cast identifier any
                ---@cast fn function

                local isvalid = metatable.__isvalid
                if isvalid == nil then
                    std.error( "callback identifier has no `__isvalid` function", 2 )
                    return
                end

                if not isvalid( identifier ) then
                    self:detach( identifier )
                    return
                end

                local real_fn = fn
                function fn( ... )
                    if isvalid( identifier ) then
                        return real_fn( identifier, ... )
                    end

                    self:detach( identifier )
                end
            end
        end

        hook_type = hook_type == nil and 0 or math_clamp( hook_type, -2, 2 )

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

        if self[ -1 ] then
            local queue = self[ -5 ]
            if queue == nil then
                self[ -5 ] = { { true, identifier, fn, hook_type } }
            else
                queue[ #queue + 1 ] = { true, identifier, fn, hook_type }
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

        table_inject( self, { identifier, fn, hook_type }, index + 1, 1, 3 )
        self[ 0 ] = self[ 0 ] + 3
    end

end

--- [SHARED AND MENU]
---
--- Checks if the hook is running.
---@return boolean: Returns `true` if the hook is running, otherwise `false`.
function Hook:isRunning()
    return self[ -1 ]
end

do

    --- [SHARED AND MENU]
    ---
    --- Stops the hook.
    ---@return boolean: Returns `true` if the hook was stopped, `false` if it was already stopped.
    local function hook_stop( self )
        if not self[ -1 ] then return false end
        self[ -1 ] = false

        local queue = self[ -5 ]
        if queue ~= nil then
            self[ -5 ] = nil

            for i = 1, #queue, 1 do
                local args = queue[ i ]
                if args[ 1 ] then
                    self:attach( args[ 2 ], args[ 3 ], args[ 4 ] )
                else
                    self:detach( args[ 2 ] )
                end
            end
        end

        return true
    end

    --- [SHARED AND MENU]
    ---
    --- Clears the hook from all callbacks.
    function Hook:clear()
        hook_stop( self )

        for i = 1, self[ 0 ], 1 do
            self[ i ] = nil
        end

        self[ 0 ] = 0
    end

    Hook.stop = hook_stop

    --- hook call without mixer and vararg
    local function call_without_mixer_and_vararg( self, ... )
        local result
        for index = 3, self[ 0 ], 3 do
            if not self[ -1 ] then break end

            local hook_type = self[ index ]
            if hook_type == -2 then -- pre hook
                self[ index - 1 ]( ... )
            elseif hook_type == 1 then -- post hook return
                local value = self[ index - 1 ]( result, ... )
                if value ~= nil then result = value end
            elseif hook_type ~= 2 then -- pre hook return and normal hook
                local value = self[ index - 1 ]( ... )
                if value ~= nil then result = value end
            end
        end

        hook_stop( self )

        for index = 3, self[ 0 ], 3 do
            if self[ index ] == 2 then -- post hook
                self[ index - 1 ]( result, ... )
            end
        end

        return result
    end

    --- hook call without mixer but with vararg
    local function call_without_mixer( self, ... )
        local r1, r2, r3, r4, r5, r6
        for index = 3, self[ 0 ], 3 do
            if not self[ -1 ] then break end

            local hook_type = self[ index ]
            if hook_type == -2 then -- pre hook
                self[ index - 1 ]( ... )
            elseif hook_type == 1 then -- post hook return
                local v1, v2, v3, v4, v5, v6 = self[ index - 1 ]( { r1, r2, r3, r4, r5, r6 }, ... )
                if v1 ~= nil then r1, r2, r3, r4, r5, r6 = v1, v2, v3, v4, v5, v6 end
            elseif hook_type ~= 2 then -- pre hook return and normal hook
                local v1, v2, v3, v4, v5, v6 = self[ index - 1 ]( ... )
                if v1 ~= nil then r1, r2, r3, r4, r5, r6 = v1, v2, v3, v4, v5, v6 end
            end
        end

        hook_stop( self )

        for index = 3, self[ 0 ], 3 do
            if self[ index ] == 2 then -- post hook
                self[ index - 1 ]( { r1, r2, r3, r4, r5, r6 }, ... )
            end
        end

        return r1, r2, r3, r4, r5, r6
    end

    --- hook call with mixer and without vararg
    local function call_with_mixer( self, mixer_fn, ... )
        local result
        for index = 3, self[ 0 ], 3 do
            if not self[ -1 ] then break end

            local hook_type = self[ index ]
            if hook_type == -2 then -- pre hook
                self[ index - 1 ]( ... )
            elseif hook_type == 1 then -- post hook return
                local value = self[ index - 1 ]( result, ... )
                if value ~= nil then result = value end
            elseif hook_type ~= 2 then -- pre hook return and normal hook
                local value = self[ index - 1 ]( ... )
                if value ~= nil then
                    local mixed = mixer_fn( result, value )
                    if mixed == nil then
                        result = value
                    else
                        result = mixed
                    end
                end
            end
        end

        hook_stop( self )

        for index = 3, self[ 0 ], 3 do
            if self[ index ] == 2 then -- post hook
                self[ index - 1 ]( result, ... )
            end
        end

        return result
    end

    --- hook call with mixer and vararg
    local function call_with_mixer_and_vararg( self, mixer_fn, ... )
        local r1, r2, r3, r4, r5, r6
        for index = 3, self[ 0 ], 3 do
            if not self[ -1 ] then break end

            local hook_type = self[ index ]
            if hook_type == -2 then -- pre hook
                self[ index - 1 ]( ... )
            elseif hook_type == 1 then -- post hook return
                local v1, v2, v3, v4, v5, v6 = self[ index - 1 ]( { r1, r2, r3, r4, r5, r6 }, ... )
                if v1 ~= nil then r1, r2, r3, r4, r5, r6 = v1, v2, v3, v4, v5, v6 end
            elseif hook_type ~= 2 then -- pre hook return and normal hook
                local v1, v2, v3, v4, v5, v6 = self[ index - 1 ]( ... )
                if v1 ~= nil then
                    local m1, m2, m3, m4, m5, m6 = mixer_fn( { r1, r2, r3, r4, r5, r6 }, { v1, v2, v3, v4, v5, v6 } )
                    if m1 == nil then
                        r1, r2, r3, r4, r5, r6 = v1, v2, v3, v4, v5, v6
                    else
                        r1, r2, r3, r4, r5, r6 = m1, m2, m3, m4, m5, m6
                    end
                end
            end
        end

        hook_stop( self )

        for index = 3, self[ 0 ], 3 do
            if self[ index ] == 2 then -- post hook
                self[ index - 1 ]( { r1, r2, r3, r4, r5, r6 }, ... )
            end
        end

        return r1, r2, r3, r4, r5, r6
    end

    --- [SHARED AND MENU]
    ---
    --- Calls the hook.
    ---@param ... any: The arguments to pass to the hook.
    ---@return any ...: The return values from the hook.
    function Hook:call( ... )
        if self[ -1 ] then return end
        self[ -1 ] = true

        local mixer_fn = self[ -4 ]
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

    Hook.__call = Hook.call

end

--- [SHARED AND MENU]
---
--- A return mixer that is called after any call to the hook and allows the return values to be modified.
---@param mixer_fn function?: The function to perform mixing, `nil` if no mixing is required.
function Hook:mixer( mixer_fn )
    self[ -4 ] = mixer_fn
end

return HookClass
