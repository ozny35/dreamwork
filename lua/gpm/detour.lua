-- https://github.com/unknown-gd/safety-lite/blob/main/src/detour.lua
local functions = {}

---@class gpm.detour
local detour = {}

--- Returns a function that calls the `new_fn` instead of the `old_fn`.
---@param old_fn function The original function.
---@param new_fn fun(hook: function, ...: any): ... Function to replace.
---@return function hooked Hooked function that calls `new_fn` instead of `old_fn`.
function detour.attach( old_fn, new_fn )
    old_fn = functions[ old_fn ] or old_fn

    local fn = function( ... ) return new_fn( old_fn, ... ) end
    functions[ fn ] = old_fn
    return fn
end

--- Returns the original function that the function given hooked.
---@param fn function Hooked function.
---@return function original Original function to overwrite with.
---@return boolean @True if the hook was detached.
function detour.detach( fn )
    local old_fn = functions[ fn ]
    if old_fn == nil then
        return fn, false
    else
        functions[ fn ] = nil
        return old_fn, true
    end
end

--- Returns the unhooked function if value is hooked, else returns ``fn``.
---@param fn function Function to check. Can actually be any type though.
---@return function original Unhooked value or function.
---@return boolean success Was the value hooked?
function detour.shadow( fn )
    local old_fn = functions[ fn ]
    if old_fn == nil then
        return fn, false
    else
        return old_fn, true
    end
end

return detour
