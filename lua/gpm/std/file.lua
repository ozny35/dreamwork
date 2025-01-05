local _G = _G
local gpm = _G.gpm
local std, Logger = gpm.std, gpm.Logger
local string, table, SERVER, MENU = std.string, std.table, std.SERVER, std.MENU

local glua_file = _G.file
local file_Exists, file_IsDir, file_Find = glua_file.Exists, glua_file.IsDir, glua_file.Find

local string_byte, string_sub, string_len, string_byteSplit = string.byte, string.sub, string.len, string.byteSplit
local table_append, table_concat = table.append, table.concat

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

---@alias gpm.std.FILE_GAME_PATH
---| string # The path to look for the files and directories in.
---| `"GAME"` # Structured like base folder (garrysmod/), searches all the mounted content (main folder, addons, mounted games, etc)
---| `"LUA"` # All Lua folders (lua/) including gamemodes and addons
---| `"lcl"` # All Lua files and subfolders (lua/) visible to the client state.
---| `"lsv"` # All Lua files and subfolders (lua/) visible to the server state.
---| `"LuaMenu"` # All Lua files and subfolders (lua/) visible to the menu state.
---| `"DATA"` # Data folder (garrysmod/data)
---| `"DOWNLOAD"` # Downloads folder (garrysmod/download/)
---| `"garrysmod"` # Strictly the game folder (garrysmod/), ignores mounting.
---| `"MOD"` # Strictly the game folder (garrysmod/), ignores mounting.
---| `"BASE_PATH"` # Location of the root folder (where hl2.exe, bin and etc. are)
---| `"EXECUTABLE_PATH"` # Bin folder and root folder
---| `"MOD_WRITE"` # Strictly the game folder (garrysmod/)
---| `"GAME_WRITE"` # Strictly the game folder (garrysmod/)
---| `"DEFAULT_WRITE_PATH"` # Strictly the game folder (garrysmod/)
---| `"THIRDPARTY"` # Contains content from installed addons or gamemodes.
---| `"WORKSHOP"` # Contains only the content from workshop addons. This includes all mounted .gma files.
---| `"BSP"` # Only the files embedded in the currently loaded map (.bsp lump 40)
---| `"GAMEBIN"` # Location of the folder containing important game files. (On Windows: garrysmod/bin on Linux: bin/linux32 or bin/linux64)
---| `<mounted folder>` # Strictly within the folder of a mounted game specified, e.g. "cstrike", see note below.
---| `<mounted Workshop addon title>` # Strictly within the specified Workshop addon. See engine.GetAddons.<br>For GMA files, this will be the title embedded inside the GMA file itself, not the title of the Workshop addon it was downloaded from.

---@alias File gpm.std.File
---@class gpm.std.File: gpm.std.Object
---@field __class gpm.std.FileClass
local File = std.class.base( "File" )

---@protected
function File:__init()
end

---@class gpm.std.FileClass: gpm.std.File
---@field __base gpm.std.File
---@field LUA_PATH string: The current lua game path. ("lsv", "lcl", "LuaMenu", "LUA")
---@overload fun(): File
local FileClass = std.class.create( File )

FileClass.LUA_PATH = LUA_PATH

---@class gpm.std.File.path
local path = _G.include( "file.path.lua" )
FileClass.path = path

local path_resolve, path_getDirectory = path.resolve, path.getDirectory

local write_allowed_game_paths = {
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
    ---@param gamePath gpm.std.FILE_GAME_PATH?: The game path.
    ---@return string: The normalized file path.
    ---@return gpm.std.FILE_GAME_PATH: The game path.
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

    ---
    ---@param filePath string:
    ---@param gamePath gpm.std.FILE_GAME_PATH?:
    ---@return string: The absolute file path.
    function absoluteGamePath( filePath, gamePath )
        if gamePath then
            return ( path2dir[ gamePath ] or "" ) .. "/" .. filePath
        else
            return filePath
        end
    end

end

local isFileMounted, isDirMounted
do

    local allowed_game_paths = {
        LUA = true,
        lsv = true,
        lcl = true,
        GAME = true,
        WORKSHOP = true,
        THIRDPARTY = true
    }

    local files = {}

    function isFileMounted( filePath, gamePath, skipNormalize )
        if not skipNormalize then
            filePath, gamePath = normalizeGamePath( filePath, gamePath )
        end

        if allowed_game_paths[ gamePath ] then
            if lua_game_paths[ gamePath ] then
                filePath = "lua/" .. filePath
            end

            return files[ filePath ]
        else
            return false
        end
    end

    FileClass.isFileMounted = isFileMounted

    local folders = {}

    function isDirMounted( filePath, gamePath, skipNormalize )
        if not skipNormalize then
            filePath, gamePath = normalizeGamePath( filePath, gamePath )
        end

        if allowed_game_paths[ gamePath ] then
            if lua_game_paths[ gamePath ] then
                filePath = "lua/" .. filePath
            end

            return folders[ filePath ]
        else
            return false
        end
    end

    FileClass.isDirMounted = isDirMounted

    do

        local game_MountGMA = _G.game.MountGMA

        ---
        ---@param relativePath string:
        ---@return true | false
        ---@return table: The list of mounted files.
        function FileClass.mountGMA( relativePath )
            local success, mounted_files = game_MountGMA( string_sub( path_resolve( relativePath ), 2 ) )
            if success then
                local fileCount = #mounted_files
                for index = 1, fileCount do
                    local filePath = mounted_files[ index ]

                    -- mounted files
                    files[ filePath ] = true

                    -- mounted dirs
                    local segments, segmentCount = string_byteSplit( path_getDirectory( filePath, false ), 0x2F --[[ / ]] )
                    segmentCount = segmentCount - 1

                    while segmentCount ~= 0 do
                        folders[ table_concat( segments, "/", 1, segmentCount ) ] = true
                        segmentCount = segmentCount - 1
                    end
                end

                Logger:debug( "GMA file '%s' was mounted to GAME with %d files.", relativePath, fileCount )
            end

            return success, mounted_files
        end
    end
end

function FileClass.exists( filePath, gamePath, skipNormalize )
    if not skipNormalize then
        filePath, gamePath = normalizeGamePath( filePath, gamePath )
    end

    return ( isFileMounted( filePath, gamePath, true ) or isDirMounted( filePath, gamePath, true ) ) or file_Exists( filePath, gamePath ) or ( CLIENT and lua_game_paths[ gamePath ] and file_Exists( "lua/" .. filePath, "WORKSHOP" ) )
end

local function isDir( filePath, gamePath, skipNormalize )
    if not skipNormalize then
        filePath, gamePath = normalizeGamePath( filePath, gamePath )
    end

    return isDirMounted( filePath, gamePath, true ) or file_IsDir( filePath, gamePath ) or ( CLIENT and lua_game_paths[ gamePath ] and file_IsDir( "lua/" .. filePath, "WORKSHOP" ) )
end

FileClass.isDir = isDir

local function isFile( filePath, gamePath, skipNormalize )
    if not skipNormalize then
        filePath, gamePath = normalizeGamePath( filePath, gamePath )
    end

    if isFileMounted( filePath, gamePath, true ) then
        return true
    elseif isDirMounted( filePath, gamePath, true ) then
        return false
    elseif file_Exists( filePath, gamePath ) then
        return not file_IsDir( filePath, gamePath )
    elseif CLIENT and lua_game_paths[ gamePath ] and file_Exists( "lua/" .. filePath, "WORKSHOP" ) then
        return not file_IsDir( "lua/" .. filePath, "WORKSHOP" )
    else
        return false
    end
end

FileClass.isFile = isFile

---
---@param filePath string:
---@param gamePath gpm.std.FILE_GAME_PATH?:
---@param sorting string?:
---@param skipNormalize boolean?:
---@return table files:
---@return table dirs:
function FileClass.find( filePath, gamePath, sorting, skipNormalize )
    if not skipNormalize then
        filePath, gamePath = normalizeGamePath( filePath, gamePath )
    end

    ---@cast gamePath string

    local files, dirs = file_Find( filePath, gamePath, sorting )
    if CLIENT and lua_game_paths[ gamePath ] then
        local workshop_files, workshop_dirs = file_Find( "lua/" .. filePath, "WORKSHOP", sorting )
        table_append( files, workshop_files )
        table_append( dirs, workshop_dirs )
    end

    return files, dirs
end

do

    local file_Time = glua_file.Time

    ---
    ---@param filePath string: The file or folder path.
    ---@param gamePath gpm.std.FILE_GAME_PATH?:
    ---@param skipNormalize boolean?:
    ---@return number: Seconds passed since Unix epoch, or 0 if the file is not found.
    function FileClass.time( filePath, gamePath, skipNormalize )
        if not skipNormalize then
            filePath, gamePath = normalizeGamePath( filePath, gamePath )
        end

        ---@cast gamePath string

        if file_Exists( filePath, gamePath ) then
            return file_Time( filePath, gamePath )
        elseif CLIENT and lua_game_paths[ gamePath ] then
            return file_Time( "lua/" .. filePath, "WORKSHOP" )
        else
            return 0
        end
    end

end

do

    local engine_GetAddons = _G.engine.GetAddons

    --- TODO
    ---@param filePath string: The file or folder path.
    ---@param gamePath gpm.std.FILE_GAME_PATH?: The path to look for the files and directories in.
    ---@return string: The addon name.
    function FileClass.whereis( filePath, gamePath, skipNormalize )
        if not skipNormalize then
            filePath, gamePath = absoluteGamePath( normalizeGamePath( filePath, gamePath ) )
        end

        -- TODO: Path build

        local addons = engine_GetAddons()
        for i = 1, #addons do
            if file_Exists( filePath, addons[ i ].title ) then
                return addons[ i ].title
            end
        end

        if SERVER or MENU or not std.DEDICATED_SERVER then
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

return FileClass
