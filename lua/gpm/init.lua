local version = "2.0.0"
---@class _G
local _G = _G

do

    local name = _G.GetConVar( _G.SERVER and "hostname" or "name" ):GetString()

    local splashes = {
        "eW91dHViZS5jb20vd2F0Y2g/dj1kUXc0dzlXZ1hjUQ==",
        "I'm not here to tell you how great I am!",
        "We will have a great Future together.",
        "I'm here to show you how great I am!",
        "Millions of pieces without a tether",
        "Why are we always looking for more?",
        "Don't worry, " .. name .. " :>",
        "Never forget to finish your tasks!",
        "T2gsIHlvdSdyZSBhIHNtYXJ0IG9uZS4=",
        "Take it in and breathe the light",
        "Big Brother is watching you",
        "As we build it once again",
        "I'll make you a promise.",
        "Flying over rooftops...",
        "Hello, " .. name .. "!",
        "We need more packages!",
        "Play SOMA sometime;",
        "Where's fireworks!?",
        "Looking For More ♪",
        "Now on Yuescript!",
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
        "That's me!",
        "I see you.",
        "Light Up ♪"
    }

    local count = #splashes + 1
    splashes[ count ] = "Wow, here more " .. ( count - 1 ) .. " splashes!"

    local splash = splashes[ _G.math.random( 1, count ) ]
    for i = 1, ( 25 - #splash ) * 0.5 do
        if i % 2 == 1 then
            splash = splash .. " "
        end

        splash = " " .. splash
    end

    _G.print( _G.string.format( "\n                                     ___          __            \n                                   /'___`\\      /'__`\\          \n     __    _____     ___ ___      /\\_\\ /\\ \\    /\\ \\/\\ \\         \n   /'_ `\\ /\\ '__`\\ /' __` __`\\    \\/_/// /__   \\ \\ \\ \\ \\        \n  /\\ \\L\\ \\\\ \\ \\L\\ \\/\\ \\/\\ \\/\\ \\      // /_\\ \\ __\\ \\ \\_\\ \\   \n  \\ \\____ \\\\ \\ ,__/\\ \\_\\ \\_\\ \\_\\    /\\______//\\_\\\\ \\____/   \n   \\/___L\\ \\\\ \\ \\/  \\/_/\\/_/\\/_/    \\/_____/ \\/_/ \\/___/    \n     /\\____/ \\ \\_\\                                          \n     \\_/__/   \\/_/                %s                        \n\n  GitHub: https://github.com/Pika-Software\n  Discord: https://discord.gg/Gzak99XGvv\n  Website: https://p1ka.eu\n  Developers: Pika Software\n  License: MIT\n", splash ) )

end

---@class gpm
---@field VERSION string Package manager version in semver format.
---@field PREFIX string Package manager unique prefix.
---@field StartTime number SysTime point when package manager was started.
local gpm = _G.gpm
if gpm == nil then
    gpm = { ["VERSION"] = version, ["PREFIX"] = "gpm@" .. version, ["StartTime"] = 0 }; _G.gpm = gpm
end

gpm.StartTime = _G.SysTime()

local dofile
do

    local string = _G.string

    local debug_getinfo = _G.debug.getinfo
    local CompileFile = _G.CompileFile
    local string_match = string.match
    local string_byte = string.byte
    local string_len = string.len
    local string_sub = string.sub
    local pcall = _G.pcall
    local error = _G.error

    ---@alias gpm.dofile fun(filePath: string, ...: any): any
    ---@param filePath string
    ---@vararg any
    ---@return any
    function dofile( filePath, ... )
        if string_byte( filePath, 1 ) == 0x2F then
            filePath = string_sub( filePath, 2, string_len( filePath ) )
        else
            filePath = ( string_match( debug_getinfo( 2 ).source, "^@addons/[^/]+/lua/(.+/)[^/]+$" ) or "" ) .. filePath
        end

        local success, result = pcall( CompileFile, filePath )
        if success then
            success, result = pcall( result, ... )
            if success then
                return result
            else
                return error( result, 2 )
            end
        end

        return nil
    end

    gpm.dofile = dofile

end

local detour, std
do

    local pairs = _G.pairs

    detour = gpm.detour
    if detour == nil then
        detour = dofile( "detour.lua", pairs )
        gpm.detour = detour
    end

    std = dofile( "std.lua", _G, gpm, dofile, pairs, detour )

end

-- TODO: net meta methods and __net_write __net_read


-- local file = environment.file

-- -- Plugins
-- do

--     local files = file.Find( "gpm/plugins/*.lua", file.LuaPath )
--     for i = 1, #files do
--         dofile( "gpm/plugins/" .. files[ i ] )
--     end

-- end

-- TODO: https://github.com/toxidroma/class-war

gpm.Logger:Info( "Start-up time: %.4f sec.", _G.SysTime() - gpm.StartTime )

return gpm
