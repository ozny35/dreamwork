local coroutine, CurTime = ...
local coroutine_yield = coroutine.yield

local library = {
    ["create"] = coroutine.create,
    ["isyieldable"] = coroutine.isyieldable,
    ["resume"] = coroutine.resume,
    ["running"] = coroutine.running,
    ["status"] = coroutine.status,
    ["wrap"] = coroutine.wrap,
    ["yield"] = coroutine_yield
}

if CurTime ~= nil then
    function library.wait( seconds )
        local endTime = CurTime() + seconds
        while true do
            if endTime < CurTime() then return end
            coroutine_yield()
        end
    end
end

return library
