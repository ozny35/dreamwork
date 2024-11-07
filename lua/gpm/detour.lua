local pairs = ...

-- https://github.com/unknown-gd/safety-lite/blob/main/src/detour.lua
local functions = {}

return {
    ["attach"] = function( old_fn, new_fn )
        for key, fn in pairs( functions ) do
            if fn == old_fn then
                functions[ key ] = nil
                break
            end
        end

        local fn = function( ... ) return new_fn( old_fn, ... ) end
        functions[ fn ] = old_fn
        return fn
    end,
    ["detach"] = function( fn )
        local old_fn = functions[ fn ]
        if old_fn == nil then
            return fn, false
        else
            functions[ fn ] = nil
            return old_fn, true
        end
    end,
    ["shadow"] = function( fn )
        local old_fn = functions[ fn ]
        if old_fn == nil then
            return fn, false
        else
            return old_fn, true
        end
    end
}
