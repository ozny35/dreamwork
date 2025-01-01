local _G = _G
local std = _G.gpm.std
local rawset, getfenv, setmetatable, table_isEmpty, is_string = std.rawset, std.getfenv, std.setmetatable, std.table.isEmpty, std.is.string

local glua_hook = _G.hook
local hook_Add, hook_GetTable, hook_Remove = glua_hook.Add, glua_hook.GetTable, glua_hook.Remove

local hookMeta = {
    __index = function( tbl, key )
        local new = {}
        rawset( tbl, key, new )
        return new
    end
}

-- https://github.com/Srlion/Hook-Library?tab=readme-ov-file#priorities
-- https://github.com/TeamUlysses/ulib/blob/master/lua/ulib/shared/hook.lua#L19
local hook = {
    --- This hook is guaranteed to be called under all circumstances, and cannot be interrupted by a return statement. You can rely on its consistent execution.
    ---@diagnostic disable-next-line: undefined-field
    PRE = _G.PRE_HOOK or -2,

    --- Consider a scenario where you have an admin mod that checks for "!menu". In this case, your hook might not be called before it.
    ---@diagnostic disable-next-line: undefined-field
    PRE_RETURN = _G.PRE_HOOK_RETURN or -1,

    --- This hook is called after the normal hook, but before the post hook.
    ---@diagnostic disable-next-line: undefined-field
    NORMAL = _G.NORMAL_HOOK or 0,

    -- This allows for the modification of results returned from preceding hooks!
    ---@diagnostic disable-next-line: undefined-field
    POST_RETURN = _G.POST_HOOK_RETURN or 1,

    --- This hook is guaranteed to be called under all circumstances, and cannot be interrupted by a return statement. You can rely on its consistent execution.
    ---@diagnostic disable-next-line: undefined-field
    POST = _G.POST_HOOK or 2,

    call = glua_hook.Call,
    run = glua_hook.Run
}

---Add a hook to be called upon the given event occurring.
---@param eventName string
---@param identifier string | Entity
---@param fn function
---@param priority table | number
function hook.add( eventName, identifier, fn, priority )
    if not is_string( eventName ) then
        ---@diagnostic disable-next-line: redundant-parameter
        hook_Add( eventName, identifier, fn, priority )
        return
    end

    local fenv = getfenv( 2 )
    if fenv == nil then
        ---@diagnostic disable-next-line: redundant-parameter
        hook_Add( eventName, identifier, fn, priority )
        return
    end

    local pkg = fenv.__package
    if pkg == nil then
        ---@diagnostic disable-next-line: redundant-parameter
        hook_Add( eventName, identifier, fn, priority )
        return
    end

    -- TODO: move this to the package class
    local hooks = pkg.__hooks
    if hooks == nil then
        hooks = setmetatable( {}, hookMeta )
        pkg.__hooks = hooks
    end

    hooks[ eventName ][ identifier ] = fn
    ---@diagnostic disable-next-line: redundant-parameter
    hook_Add( eventName, pkg.prefix .. identifier, fn, priority )
end

---Removes the hook with the supplied identifier from the given event.
---@param eventName string
---@param identifier string | Entity
function hook.remove( eventName, identifier )
    local fenv = getfenv( 2 )
    if fenv == nil then
        hook_Remove( eventName, identifier )
        return
    end

    local pkg = fenv.__package
    if pkg == nil then
        hook_Remove( eventName, identifier )
        return
    end

    -- TODO: move this to the package class
    local hooks = pkg.__hooks
    if hooks == nil then
        hooks = setmetatable( {}, hookMeta )
        pkg.__hooks = hooks
    end

    local event = hooks[ eventName ]
    event[ identifier ] = nil

    if table_isEmpty( event ) then
        hooks[ eventName ] = nil
    end

    hook_Remove( eventName, pkg.prefix .. identifier )
end

---Returns a list of all the hooks registered with hook.add
---@return table
function hook.getTable()
    local fenv = getfenv( 2 )
    if fenv == nil then
        return hook_GetTable()
    else
        local pkg = fenv.__package
        if pkg == nil then
            return hook_GetTable()
        else
            -- TODO: move this to the package class
            local hooks = pkg.__hooks
            if hooks == nil then
                hooks = setmetatable( {}, hookMeta )
                pkg.__hook = hooks
            end

            return hooks
        end
    end
end

return hook
