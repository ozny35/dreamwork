local _G = _G
local gpm = _G.gpm
local std, Logger = gpm.std, gpm.Logger
local string, table = std.string, std.table

local assert = std.assert

local glua_file = _G.file
local file_Exists, file_IsDir, file_Find = glua_file.Exists, glua_file.IsDir, glua_file.Find

local string_byte, string_sub, string_len, string_byteSplit = string.byte, string.sub, string.len, string.byteSplit
local table_inject, table_concat = table.inject, table.concat

local Future = std.Future

local CLIENT, SERVER, MENU = std.CLIENT, std.SERVER, std.MENU

local lua_game_paths = {
    LuaMenu = true,
    lcl = true,
    lsv = true,
    LUA = true
}

---@alias File gpm.std.File
---@class gpm.std.File: gpm.std.Object
---@field __class gpm.std.FileClass
---@field path gpm.std.File.path
local File = std.class.base( "File" )

---@class gpm.std.FileClass: gpm.std.File
---@field __base gpm.std.File
---@overload fun( file_path: string ): File
local FileClass = std.class.create( File )

---@alias gpm.std.File.mode
---| integer # The mode to open the file with.
---| `0` # Read
---| `1` # Read-binary
---| `2` # Write-binary
---| `3` # Append-binary
---| `4` # Write
---| `5` # Append

--[[

    Virtual file system scheme:

    / [BASE_PATH]:
        /bin [GAMEBIN]
        /base [MOD]

        /game [GAME]
            /download [DOWNLOAD]
            /data [DATA]
            /lua [LUA]

        /mnt
            /addons [WORKSHOP]
            /local [THIRDPARTY]
            /level [BSP]
            /games

]]

-- print()
-- PrintTable( select( 2, file.Find( "*", "THIRDPARTY" ) ), nil )



---@class gpm.std.File.path
local path = _G.include( "file.path.lua" )
FileClass.path = path

local path_resolve, path_getDirectory = path.resolve, path.getDirectory

local normalizeGamePath, absoluteGamePath
local perform_game_path
do

    local tostring = std.tostring

    function File:__isvalid()
        return tostring( self.handler ) ~= "File [NULL]"
    end

    local engine = gpm.engine

    local LUA_PATH
    if SERVER then
        LUA_PATH = "lsv"
    elseif CLIENT then
        LUA_PATH = "lcl"
    elseif MENU then
        LUA_PATH = "LuaMenu"
    else
        LUA_PATH = "LUA"
    end

    local path2path = {
        ["local"] = "THIRDPARTY",
        exe = "EXECUTABLE_PATH",
        download = "DOWNLOAD",
        base = "BASE_PATH",
        gmod = "garrysmod",
        mnt = "WORKSHOP",
        lmn = "LuaMenu",
        bin = "GAMEBIN",
        lua = LUA_PATH,
        game = "GAME",
        data = "DATA",
        maps = "BSP",
        mod = "MOD",
        lsv = "lsv",
        lcl = "lcl"
    }

    local mounted_addons = engine.mounted_addons
    local mounted_games = engine.mounted_games

    function perform_game_path( game_path, write_mode )
        if not game_path then
            game_path = "game"
        end

        if write_mode and game_path ~= "data" and not MENU then
            return false, "game path '" .. game_path .. "' is not writable."
        end

        local formatted = path2path[ game_path ]
        if formatted == nil then
            if mounted_addons[ game_path ] or mounted_games[ game_path ] then
                return game_path
            else
                return false, "game path '" .. game_path .. "' does not exist."
            end
        else
            return formatted
        end
    end

    local path_getCurrentDirectory = path.getCurrentDirectory
    -- local isurl = environment.isurl

    local game_dirs = {
        lua = true,
        data = true,
        download = true
    }

    ---
    ---@param abs_path string The absolute file path.
    ---@param game_path? string
    ---@return string: The normalized file path.
    ---@return string
    function normalizeGamePath( abs_path, game_path )
        -- if not game_path and isurl( abs_path ) then
        --     if abs_path.scheme ~= "file" then
        --         std.error(FileSystemError("Cannot resolve URL '" .. tostring(abs_path) .. "' because it is not a file URL."))
        --     end

        --     abs_path = abs_path.pathname
        -- end

        local b1, b2 = string_byte( abs_path, 1, 2 )
        if b1 == 0x2F --[[ / ]] then
            abs_path = string_sub( abs_path, 2, string_len( abs_path ) )
            if game_path then
                return abs_path, game_path
            end
        elseif b1 == 0x2E --[[ . ]] then
            if b2 == 0x2F --[[ / ]] or ( b2 == 0x2E --[[ . ]] and string_byte( abs_path, 3 ) == 0x2F --[[ / ]] ) then
                local currentDir = path_getCurrentDirectory()
                currentDir = string_sub( currentDir, 5, string_len( currentDir ) )
                if currentDir == "" then
                    std.error( "Cannot resolve relative path '" .. tostring( abs_path ) .. "' because main file is unknown.", 2 )
                else
                    abs_path = string_sub( path_resolve( currentDir .. abs_path ), 2, string_len( abs_path ) )
                    game_path = LUA_PATH
                end
            end
        end

        if not game_path then
            for index = 1, string_len( abs_path ), 1 do
                if string_byte( abs_path, index ) == 0x2F --[[ / ]] then
                    local rootDir = string_sub( abs_path, 1, index - 1 )

                    if game_dirs[ rootDir ] then
                        game_path = rootDir
                    end

                    if game_path then
                        abs_path = string_sub( abs_path, index + 1 )
                    end

                    break
                end
            end
        end

        return abs_path, game_path or "game"
    end

    local path2dir = {
        download = "/download",
        lmn = "/lua",
        data = "/data",
        lua = "/lua",
        lsv = "/lua",
        lcl = "/lua"
    }

    ---
    ---@param file_path string
    ---@param game_path? string
    ---@return string The absolute file path.
    function absoluteGamePath( file_path, game_path )
        if game_path then
            return ( path2dir[ game_path ] or "" ) .. "/" .. file_path
        else
            return file_path
        end
    end

    local DEDICATED = std.DEDICATED

    --- TODO
    ---@param file_path string The file or folder path.
    ---@param game_path? string: The path to look for the files and directories in.
    ---@return string: The addon name.
    function FileClass.whereis( file_path, game_path, skipNormalize )
        if not skipNormalize then
            file_path, game_path = normalizeGamePath( file_path, game_path )
        end

        local searchable = string_sub( absoluteGamePath( file_path, assert( perform_game_path( game_path ) ) ), 2 )
        local mounted = engine.mounted

        for i = 1, engine.mounted_count, 1 do
            if file_Exists( searchable, mounted[ i ] ) then
                -- TODO: add vfs path part here
                return mounted[ i ]
            end
        end

        if SERVER or MENU or not DEDICATED then
            local _, folders = file_Find( searchable, "GAME" )
            for i = 1, #folders, 1 do
                if file_Exists( "addons/" .. folders[ i ] .. "/" .. searchable, "GAME" ) then
                    return folders[ i ]
                end
            end
        end

        return "unknown"
    end

end

-- print( assert( perform_game_path( "data", true ) ) )

-- local function assertWriteAllowed( file_path, game_path )
--     if write_allowed_game_paths[ game_path ] or MENU then
--        return nil
--     end
--     std.error(FileSystemError(
--     "File '" .. tostring(file_path) .. "' is not allowed to be written to '" .. tostring(game_path) .. "'.", 3))
-- 	return nil
-- end

do

    local FILE = std.debug.findmetatable( "File" )
    ---@cast FILE File

    local file_Open = glua_file.Open
    local FILE_Close = FILE.Close

    local id2mode = {
        [ 0 ] = "r",
        [ 1 ] = "rb",
        [ 2 ] = "wb",
        [ 3 ] = "ab",
        [ 4 ] = "w",
        [ 5 ] = "a"
    }

    setmetatable( id2mode, {
        __index = function( _, key )
            std.error( "unknown file mode '" .. tostring( key ) .. "'", 3 )
        end
    } )

    ---
    ---@param file_path string
    ---@param mode? gpm.std.File.mode
    ---@param game_path? string
    ---@param skipNormalize? boolean
    function File:__init( file_path, mode, game_path, skipNormalize )
        if mode == nil then mode = 0 end

        if not skipNormalize then
            file_path, game_path = normalizeGamePath( file_path, game_path )
        end

        game_path = assert( perform_game_path( game_path, mode > 1 ) )

        local handler = file_Open( file_path, id2mode[ mode ], game_path )
        if handler == nil then
            std.error( "Failed to open file '" .. absoluteGamePath( file_path, game_path ) .. "'.", 4 )
        end

        self.handler = handler
        self.file_path = absoluteGamePath( file_path, game_path )
    end

    function File:close()
        FILE_Close( self.handler )
    end

    do

        local FILE_Read = FILE.Read

        ---
        ---@param size? integer
        ---@return string
        function File:read( size )
            return FILE_Read( self.handler, size )
        end

        ---
        ---@param file_path string
        ---@param game_path? string
        ---@param skipNormalize? boolean
        ---@return string
        function FileClass.read( file_path, game_path, skipNormalize )
            if not skipNormalize then
                file_path, game_path = normalizeGamePath( file_path, game_path )
            end

            game_path = assert( perform_game_path( game_path ) )

            local handler = file_Open( file_path, "rb", game_path )
            if handler == nil then
                std.error( "Failed to open file '" .. absoluteGamePath( file_path, game_path ) .. "' for reading.", 2 )
            end

            ---@diagnostic disable-next-line: cast-type-mismatch
            ---@cast handler File

            local str = FILE_Read( handler ) or ""
            FILE_Close( handler )

            return str
        end

    end

    do

        local FILE_Write = FILE.Write

        ---
        ---@param data string
        function File:write( data )
            FILE_Write( self.handler, data )
        end

        ---
        ---@param file_path string
        ---@param data string
        ---@param game_path? string
        ---@param skipNormalize? boolean
        function FileClass.write( file_path, data, game_path, skipNormalize )
            if not skipNormalize then
                file_path, game_path = normalizeGamePath( file_path, game_path )
            end

            game_path = assert( perform_game_path( game_path ) )

            local handler = file_Open( file_path, "wb", game_path )
            if handler == nil then
                std.error( "Failed to open file '" .. absoluteGamePath( file_path, game_path ) .. "' for writing.", 2 )
            end

            ---@diagnostic disable-next-line: cast-type-mismatch
            ---@cast handler File

            FILE_Write( handler, data )
            FILE_Close( handler )
        end

        function FileClass.append( file_path, data, game_path, skipNormalize )
            if not skipNormalize then
                file_path, game_path = normalizeGamePath( file_path, game_path )
            end

            game_path = assert( perform_game_path( game_path ) )

            local handler = file_Open( file_path, "ab", game_path )
            if handler == nil then
                std.error( "Failed to open file '" .. absoluteGamePath( file_path, game_path ) .. "' for appending.", 2 )
            end

            ---@diagnostic disable-next-line: cast-type-mismatch
            ---@cast handler File

            FILE_Write( handler, data )
            FILE_Close( handler )
        end

    end

end

do

    local FSASYNC = {
        [ -8 ] = "filename not part of the specified file system, try a different one.",
        [ -7 ] = "failure for a reason that might be temporary, you might retry, but not immediately.",
        [ -6 ] = "read parameters invalid for unbuffered IO.",
        [ -5 ] = "hard subsystem failure.",
        [ -4 ] = "read error on file.",
        [ -3 ] = "out of memory for file read.",
        [ -2 ] = "caller's provided id is not recognized.",
        [ -1 ] = "filename could not be opened (bad path, not exist, etc).",
        [  0 ] = "operation is successful.",
        [  1 ] = "file is properly queued, waiting for service.",
        [  2 ] = "file is being accessed.",
        [  3 ] = "file was aborted by caller.",
        [  4 ] = "file is not yet queued."
    }

    do

        local file_AsyncRead = glua_file.AsyncRead

        ---@async
        function FileClass.readAsync( file_path, game_path, skipNormalize )
            if not skipNormalize then
                file_path, game_path = normalizeGamePath( file_path, game_path )
            end

            local f = Future()

            file_AsyncRead( file_path, assert( perform_game_path( game_path ) ), function( _, __, status, content )
                if status == 0 then
                    f:setResult( FileClass( content ) )
                else
                    f:setError( FSASYNC[ status ] or "unknown error." )
                end
            end, false )

            return f:await()
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

    function isFileMounted( file_path, game_path, skipNormalize )
        if not skipNormalize then
            file_path, game_path = normalizeGamePath( file_path, game_path )
        end

        if game_path == nil then
            game_path = "GAME"
        elseif game_path == "lmn" then
            game_path = "LuaMenu"
        end

        if allowed_game_paths[ game_path ] then
            if lua_game_paths[ game_path ] then
                file_path = "lua/" .. file_path
            end

            return files[ file_path ]
        else
            return false
        end
    end

    FileClass.isFileMounted = isFileMounted

    local folders = {}

    function isDirMounted( file_path, game_path, skipNormalize )
        if not skipNormalize then
            file_path, game_path = normalizeGamePath( file_path, game_path )
        end

        if allowed_game_paths[ game_path ] then
            if lua_game_paths[ game_path ] then
                file_path = "lua/" .. file_path
            end

            return folders[ file_path ]
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
                    local file_path = mounted_files[ index ]

                    -- mounted files
                    files[ file_path ] = true

                    -- mounted dirs
                    local segments, segmentCount = string_byteSplit( path_getDirectory( file_path, false ), 0x2F --[[ / ]] )
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

function FileClass.exists( file_path, game_path, skipNormalize )
    if not skipNormalize then
        file_path, game_path = normalizeGamePath( file_path, game_path )
    end

    return ( isFileMounted( file_path, game_path, true ) or isDirMounted( file_path, game_path, true ) ) or file_Exists( file_path, game_path ) or ( CLIENT and lua_game_paths[ game_path ] and file_Exists( "lua/" .. file_path, "WORKSHOP" ) )
end

local function isDir( file_path, game_path, skipNormalize )
    if not skipNormalize then
        file_path, game_path = normalizeGamePath( file_path, game_path )
    end

    return isDirMounted( file_path, game_path, true ) or file_IsDir( file_path, game_path ) or ( CLIENT and lua_game_paths[ game_path ] and file_IsDir( "lua/" .. file_path, "WORKSHOP" ) )
end

FileClass.isDir = isDir

local function isFile( file_path, game_path, skipNormalize )
    if not skipNormalize then
        file_path, game_path = normalizeGamePath( file_path, game_path )
    end

    if isFileMounted( file_path, game_path, true ) then
        return true
    elseif isDirMounted( file_path, game_path, true ) then
        return false
    elseif file_Exists( file_path, game_path ) then
        return not file_IsDir( file_path, game_path )
    elseif CLIENT and lua_game_paths[ game_path ] and file_Exists( "lua/" .. file_path, "WORKSHOP" ) then
        return not file_IsDir( "lua/" .. file_path, "WORKSHOP" )
    else
        return false
    end
end

FileClass.isFile = isFile

---
---@param file_path string:
---@param game_path? string
---@param sorting string
---@param skipNormalize boolean
---@return table files
---@return table dirs
function FileClass.find( file_path, game_path, sorting, skipNormalize )
    if not skipNormalize then
        file_path, game_path = normalizeGamePath( file_path, game_path )
    end

    ---@cast game_path string

    local files, dirs = file_Find( file_path, game_path, sorting )
    if CLIENT and lua_game_paths[ game_path ] then
        local workshop_files, workshop_dirs = file_Find( "lua/" .. file_path, "WORKSHOP", sorting )
        table_inject( files, workshop_files )
        table_inject( dirs, workshop_dirs )
    end

    return files, dirs
end

do

    local file_Time = glua_file.Time

    ---
    ---@param file_path string The file or folder path.
    ---@param game_path? gpm.std.File.Path
    ---@param skipNormalize boolean
    ---@return number: Seconds passed since Unix epoch, or 0 if the file is not found.
    function FileClass.time( file_path, game_path, skipNormalize )
        if not skipNormalize then
            file_path, game_path = normalizeGamePath( file_path, game_path )
        end

        ---@cast game_path string

        if file_Exists( file_path, game_path ) then
            return file_Time( file_path, game_path )
        elseif CLIENT and lua_game_paths[ game_path ] then
            return file_Time( "lua/" .. file_path, "WORKSHOP" )
        else
            return 0
        end
    end

end

do

    local path_replaceDirectory = path.replaceDirectory
    local Rename = file.Rename

    function file.Move(pathFrom, pathTo, gamePathFrom, gamePathTo, skipNormalize)
        if not skipNormalize then
            pathFrom, gamePathFrom = normalizeGamePath(pathFrom, gamePathFrom)
        end

        assertWriteAllowed(pathFrom, gamePathFrom)

        if not skipNormalize then
            pathTo, gamePathTo = normalizeGamePath(pathTo, gamePathTo)
        end
        assertWriteAllowed(pathTo, gamePathTo)

        return Rename(pathFrom, path_replaceDirectory(pathFrom, pathTo), gamePathFrom, gamePathTo)
    end

    local path_replaceFile = path.replaceFile

    function file.Rename(file_path, newName, game_path, skipNormalize)
        if not skipNormalize then
            file_path, game_path = normalizeGamePath(file_path, game_path)
        end

        assertWriteAllowed(file_path, game_path)

        return Rename(file_path, path_replaceFile(file_path, newName), game_path)
    end

end

-- TODO: https://wiki.facepunch.com/gmod/resource
-- TODO: https://wiki.facepunch.com/gmod/Global.AddCSLuaFile

return FileClass
