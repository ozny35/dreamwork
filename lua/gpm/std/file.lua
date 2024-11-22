local _G = _G
local std = _G.gpm.std
local glua_file = _G.file

local file_Exists, file_Find = glua_file.Exists, glua_file.Find
local assert, string, SERVER, MENU = std.assert, std.string, std.SERVER, std.MENU
local string_byte, string_sub, string_len = string.byte, string.sub, string.len

local isDedicatedServer = false
if not MENU then
    isDedicatedServer = std.game.isDedicatedServer()
end

local LUA_PATH
if SERVER then
    LUA_PATH = "lsv"
elseif CLIENT then
    LUA_PATH = "lcl"
elseif MENU_DLL then
    LUA_PATH = "LuaMenu"
else
    LUA_PATH = "LUA"
end

local lua_game_paths = {
    LuaMenu = true,
    lcl = true,
    lsv = true,
    LUA = true
}

---@class gpm.std.file
---@field LUA_PATH string: The current lua game path. ("lsv", "lcl", "LuaMenu", "LUA")
local file = {
    LUA_PATH = LUA_PATH
}

---@class gpm.std.file.path
local path = _G.include( "file.path.lua" )
file.path = path

local path_resolve = path.resolve

local writeAllowedGamePaths = {
    -- allowed by default
    DATA = true
}

local normalizeGamePath, absoluteGamePath
do

    local path_getCurrentDirectory = path.getCurrentDirectory
    -- local isurl = environment.isurl

    local dir2path = {
        lua = LUA_PATH,
        data = "DATA",
        download = "DOWNLOAD"
    }

    ---
    ---@param absolutePath string: The absolute file path.
    ---@param gamePath string?: The game path.
    ---@return string: The normalized file path.
    ---@return string: The game path.
    function normalizeGamePath( absolutePath, gamePath )
        -- if not gamePath and isurl( absolutePath ) then
        --     if absolutePath.scheme ~= "file" then
        --         error(FileSystemError("Cannot resolve URL '" .. tostring(absolutePath) .. "' because it is not a file URL."))
        --     end

        --     absolutePath = absolutePath.pathname
        -- end

        local byte = string_byte( absolutePath )
        if byte == 0x2F --[[ / ]] then
            absolutePath = string_sub( absolutePath, 2, string_len( absolutePath ) )
            if gamePath then
                return absolutePath, gamePath
            end
        elseif byte == 0x2E --[[ . ]] then
            byte = string_byte( absolutePath, 2 )
            if byte == 0x2F --[[ / ]] or ( byte == 0x2E --[[ . ]] and string_byte( absolutePath, 3 ) == 0x2F --[[ / ]] ) then
                local currentDir = path_getCurrentDirectory()
                currentDir = string_sub( currentDir, 5, string_len( currentDir ) )
                if currentDir == "" then
                    error( "Cannot resolve relative path '" .. tostring( absolutePath ) .. "' because main file is unknown.", 2 )
                else
                    absolutePath = string_sub( path_resolve( currentDir .. absolutePath ), 2, string_len( absolutePath ) )
                    gamePath = LUA_PATH
                end
            end
        end

        if not gamePath then
            for index = 1, string_len( absolutePath ), 1 do
                if string_byte(absolutePath, index) == 0x2F --[[ / ]] then
                    local rootDir = string_sub( absolutePath, 1, index - 1 )

                    gamePath = dir2path[ rootDir ]
                    if gamePath then
                        absolutePath = string_sub( absolutePath, index + 1 )
                    end

                    break
                end
            end
        end

        return absolutePath, gamePath or "GAME"
    end

    local path2dir = {
        DOWNLOAD = "/download",
        LuaMenu = "/lua",
        DATA = "/data",
        LUA = "/lua",
        lsv = "/lua",
        lcl = "/lua"
    }

    function absoluteGamePath( filePath, gamePath )
        return gamePath ~= nil and ( ( path2dir[ gamePath ] or "" ) .. "/" .. filePath ) or filePath
    end

end

do

    local engine_GetAddons = _G.engine.GetAddons

    function file.whereIs( filePath )
        filePath = absoluteGamePath( normalizeGamePath( filePath ) )
        -- TODO: Path build

        local addons = engine_GetAddons()
        for i = 1, #addons do
            if file_Exists( filePath, addons[ i ].title ) then
                return addons[ i ].title
            end
        end

        if SERVER or MENU or not isDedicatedServer then
            local _, folders = file_Find( filePath, "GAME" )
            for i = 1, #folders do
                if file_Exists( "addons/" .. folders[ i ] .. "/" .. filePath, "GAME") then
                    return folders[ i ]
                end
            end
        end

        return "unknown"
    end

end

-- TODO: https://wiki.facepunch.com/gmod/resource
-- TODO: https://wiki.facepunch.com/gmod/Global.AddCSLuaFile

return file
