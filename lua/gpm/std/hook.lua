local _G, rawset, getfenv, setmetatable, table_isEmpty = ...

local hook = _G.hook
local hooks_Add, hooks_Call, hooks_GetTable, hooks_Remove, hooks_Run = hook.Add, hook.Call, hook.GetTable, hook.Remove, hook.Run

local hooksMeta = {
    ["__index"] = function( tbl, key )
        local new = {}
        rawset( tbl, key, new )
        return new
    end
}

return {
    -- https://github.com/Srlion/Hook-Library?tab=readme-ov-file#priorities
    -- https://github.com/TeamUlysses/ulib/blob/master/lua/ulib/shared/hook.lua#L19
    ["PRE"] = _G.PRE_HOOK or -2,
    ["PRE_RETURN"] = _G.PRE_HOOK_RETURN or -1,
    ["NORMAL"] = _G.NORMAL_HOOK or 0,
    ["POST_RETURN"] = _G.POST_HOOK_RETURN or 1,
    ["POST"] = _G.POST_HOOK or 2,
    ["add"] = function( eventName, identifier, func, priority )
        local fenv = getfenv( 2 )
        if fenv == nil then
            return hooks_Add( eventName, identifier, func, priority )
        else
            local pkg = fenv.__package
            if pkg == nil then
                return hooks_Add( eventName, identifier, func, priority )
            else
                local hooks = pkg.__hooks
                if hooks == nil then
                    hooks = setmetatable( {}, hooksMeta )
                    pkg.__hooks = hooks
                end

                hooks[ eventName ][ identifier ] = func
                return hooks_Add( eventName, pkg.prefix .. identifier, func, priority )
            end
        end
    end,
    ["call"] = hooks_Call,
    ["remove"] = function( eventName, identifier )
        local fenv = getfenv( 2 )
        if fenv == nil then
            return hooks_Remove( eventName, identifier )
        else
            local pkg = fenv.__package
            if pkg == nil then
                return hooks_Remove( eventName, identifier )
            else
                local hooks = pkg.__hooks
                if hooks == nil then
                    hooks = setmetatable( {}, hooksMeta )
                    pkg.__hooks = hooks
                end

                local event = hooks[ eventName ]
                event[ identifier ] = nil

                if table_isEmpty( event ) then
                    hooks[ eventName ] = nil
                end

                return hooks_Remove( eventName, pkg.prefix .. identifier )
            end
        end
    end,
    ["getTable"] = function()
        local fenv = getfenv( 2 )
        if fenv == nil then
            return hooks_GetTable()
        else
            local pkg = fenv.__package
            if pkg == nil then
                return hooks_GetTable()
            else
                local hooks = pkg.__hooks
                if hooks == nil then
                    hooks = setmetatable( {}, hooksMeta )
                    pkg.__hooks = hooks
                end

                return hooks
            end
        end
    end,
    ["run"] = hooks_Run
}
