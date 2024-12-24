---@class _G
local _G = _G

do

    local name = _G.GetConVar( _G.SERVER and "hostname" or "name" ):GetString()
    if name == "unnamed" then name = "stranger" end

    local version = "2.0.0"

    local splashes = {
        "eW91dHViZS5jb20vd2F0Y2g/dj1kUXc0dzlXZ1hjUQ==",
        "I'm not here to tell you how great I am!",
        "We will have a great Future together.",
        "I'm here to show you how great I am!",
        "Millions of pieces without a tether",
        "Why are we always looking for more?",
        "Never forget to finish your tasks!",
        "T2gsIHlvdSdyZSBhIHNtYXJ0IG9uZS4=",
        "Take it in and breathe the light",
        "Don't worry, " .. name .. " :>",
        "Big Brother is watching you",
        "As we build it once again",
        "I'll make you a promise.",
        "Flying over rooftops...",
        "Hello, " .. name .. "!",
        "We need more packages!",
        "Play SOMA sometime;",
        "Where's fireworks!?",
        "Looking For More ♪",
        "I'm watching you.",
        "Faster than ever.",
        "Love Wins Again ♪",
        "Blazing fast ☄",
        "Here For You ♪",
        "Good Enough ♪",
        "v" .. version,
        "Hello World!",
        "Star Glide ♪",
        "Once Again ♪",
        "Data Loss ♪",
        "Sandblast ♪",
        "Now on LLS!",
        "That's me!",
        "I see you.",
        "Light Up ♪"
    }

    local count = #splashes + 1
    splashes[ count ] = "Wow, here more " .. ( count - 1 ) .. " splashes!"

    local splash = splashes[ math.random( 1, count ) ]
    for i = 1, ( 25 - #splash ) * 0.5 do
        if i % 2 == 1 then
            splash = splash .. " "
        end

        splash = " " .. splash
    end

    print( string.format( "\n                                     ___          __            \n                                   /'___`\\      /'__`\\          \n     __    _____     ___ ___      /\\_\\ /\\ \\    /\\ \\/\\ \\         \n   /'_ `\\ /\\ '__`\\ /' __` __`\\    \\/_/// /__   \\ \\ \\ \\ \\        \n  /\\ \\L\\ \\\\ \\ \\L\\ \\/\\ \\/\\ \\/\\ \\      // /_\\ \\ __\\ \\ \\_\\ \\   \n  \\ \\____ \\\\ \\ ,__/\\ \\_\\ \\_\\ \\_\\    /\\______//\\_\\\\ \\____/   \n   \\/___L\\ \\\\ \\ \\/  \\/_/\\/_/\\/_/    \\/_____/ \\/_/ \\/___/    \n     /\\____/ \\ \\_\\                                          \n     \\_/__/   \\/_/                %s                        \n\n  GitHub: https://github.com/Pika-Software\n  Discord: https://discord.gg/Gzak99XGvv\n  Website: https://p1ka.eu\n  Developers: Pika Software\n  License: MIT\n", splash ) )

    if gpm == nil then
        ---@class gpm
        ---@field VERSION string Package manager version in semver format.
        ---@field PREFIX string Package manager unique prefix.
        ---@field StartTime number SysTime point when package manager was started.
        gpm = { ["VERSION"] = version, ["PREFIX"] = "gpm@" .. version, ["StartTime"] = 0 }
    end

end


-- TODO: remove me later
do

    local collectgarbage = collectgarbage
    local format = string.format
    local SysTime = SysTime

    local iter = 100000
    local warmup = math.min( iter / 100, 100 )

    function gpm.bench(name, fn)
        for i = 1, warmup do
            fn()
        end

        collectgarbage( "stop" )

        local st = SysTime()
        for _ = 1, iter do
            fn()
        end

        st = SysTime() - st
        collectgarbage( "restart" )
        print( format( "%d iterations of %s, took %f sec.", iter, name, st ) )
        return st
    end

end

---@class gpm
local gpm = gpm
local include = _G.include

gpm.StartTime = _G.SysTime()

if gpm.detour == nil then
    ---@class gpm.detour
    gpm.detour = include( "detour.lua" )
end

include( "std.lua" )

-- local file = std.file

-- -- Plugins
-- do

--     local files = _G.file.Find( "gpm/plugins/*.lua", "LUA" )
--     for i = 1, #files do
--         include( "gpm/plugins/" .. files[ i ] )
--     end

-- end

gpm.Logger:info( "Start-up time: %.4f sec.", SysTime() - gpm.StartTime )

return gpm
