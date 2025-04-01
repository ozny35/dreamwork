local _G = _G

-- TODO: https://wiki.facepunch.com/gmod/resource
-- TODO: https://wiki.facepunch.com/gmod/Global.AddCSLuaFile

local glua_file = _G.file

---@class gpm.std
local std = _G.gpm.std

local CLIENT, SERVER, MENU = std.CLIENT, std.SERVER, std.MENU
local raw_ipairs = std.raw.ipairs
local string = std.string

--- [SHARED AND MENU]
---
--- The game's file library.
---@class gpm.std.file
local file = std.file or {}
std.file = file

local path = include( "file.path.lua" )
file.path = path

local debug = std.debug

local function resolve_path( resolving_path  )
    if not resolving_path or resolving_path == "" or resolving_path == "." then
        return path.getCurrentDirectory( debug.getfmain(), false )
    elseif resolving_path == "./" then
        return path.getCurrentDirectory( debug.getfmain(), true )
    elseif string.byte( resolving_path, 1 ) == 0x2F --[[ / ]] then
        return path.normalize( resolving_path )
    else
        return path.normalize( path.getCurrentDirectory( debug.getfmain(), true ) .. resolving_path )
    end
end

local engine = gpm.engine

local path_unpack
do

    local mounted_addons = engine.mounted_addons
    local mounted_games = engine.mounted_games

    local fstab = {
        { "/lua", ( SERVER and "lsv" or ( CLIENT and "lcl" or ( MENU and "LuaMenu" or "LUA" ) ) ) },
        { "/materials", "GAME", "materials" },
        { "/particles", "GAME", "particles" },
        { "/gamemodes", "GAME", "gamemodes" },
        { "/scripts", "GAME", "scripts" },
        { "/shaders", "GAME", "shaders" },
        { "/models", "GAME", "models" },
        { "/scenes", "GAME", "scenes" },
        { "/sound", "GAME", "sound" },
        { "/download", "DOWNLOAD" },
        { "/maps", "GAME", "maps" },
        { "/fonts", "GAME", "resource/fonts" },
        { "/localization", "GAME", "resource/localization" },
        { "/data", "DATA", nil, true },
        {
            "/addons",
            function( file_path )
                local addon_name, local_path = string.match( file_path, "([^/]+)/?(.*)" )

                if addon_name == nil then
                    std.error( "Wrong path '/addons/" .. file_path .. "'.", 3 )
                end

                if mounted_addons[ addon_name ] then
                    return local_path or "", addon_name
                end

                std.error( "Addon '" .. addon_name .. "' is not mounted, path '/addons/" .. file_path .. "' is not available.", 3 )
            end
        },
        { "/garrysmod", "MOD", nil, not MENU },
        -- { "/mounted", "WORKSHOP" },
        -- { "/game", "GAME" },
        {
            "/bspzip",
            function( file_path )
                return file_path, "BSP"
            end
        },
        {
            "",
            function( file_path )
                local game_folder, local_path = string.match( file_path, "([^/]+)/?(.*)" )

                if game_folder == nil then
                    return "", "BASE_PATH"
                elseif mounted_games[ game_folder ] then
                    return local_path, game_folder
                else
                    return local_path, "BASE_PATH"
                end
            end
        }
    }

    for i = 1, #fstab do
        local data = fstab[ i ]
        data[ 5 ] = string.len( data[ 1 ] )
    end

    local fstab_length = #fstab

    function path_unpack( resolved_path, write_mode, error_level )
        for i = 1, fstab_length, 1 do
            local data = fstab[ i ]

            local mounted_path = data[ 1 ]
            if mounted_path == resolved_path or string.sub( resolved_path, 1, data[ 5 ] + 1 ) == ( mounted_path .. "/" ) then
                if write_mode and not data[ 4 ] then
                    std.error( "Attempt to write into read-only directory '" .. path.getDirectory( resolved_path, true ) .. "'.", ( error_level or 1 ) + 1 )
                end

                local local_path, path_name

                local game_path = data[ 2 ]
                if isstring( game_path ) then
                    ---@cast game_path string
                    local_path, path_name = string.sub( resolved_path, data[ 5 ] + 2 ), game_path
                elseif isfunction( game_path ) then
                    ---@diagnostic disable-next-line: cast-type-mismatch
                    ---@cast game_path function
                    local_path, path_name = game_path( string.sub( resolved_path, data[ 5 ] + 2 ) )
                else
                    std.error( "Game path corrupted, critical failure.", 1 )
                end

                local mount_path = data[ 3 ]
                if mount_path ~= nil then
                    local_path = mount_path .. "/" .. local_path
                end

                return local_path, path_name
            end
        end

        std.error( "Path '" .. resolved_path .. "' is not mounted.", ( error_level or 1 ) + 1 )
    end

end

local file_Exists, file_IsDir = glua_file.Exists, glua_file.IsDir

--- [SHARED AND MENU]
---
--- Checks if a file or directory exists by given path.
---@param file_path string The path to the file.
---@return boolean exists Returns `true` if the file or directory exists, otherwise `false`.
function file.exists( file_path )
    return file_Exists( path_unpack( resolve_path( file_path ), false, 2 ) )
end

--- [SHARED AND MENU]
---
--- Checks if a directory exists and is not a file by given path.
---@param directory_path string The path to the directory.
---@return boolean exists Returns `true` if the directory exists and is not a file, otherwise `false`.
function file.isExistingDirectory( directory_path )
    return file_IsDir( path_unpack( resolve_path( directory_path ), false, 2 ) )
end

--- [SHARED AND MENU]
---
--- Checks if a file exists and is not a directory by given path.
---@param file_path string The path to the file.
---@return boolean exists Returns `true` if the file exists and is not a directory, otherwise `false`.
function file.isExistingFile( file_path )
    local local_path, game_path = path_unpack( resolve_path( file_path ), false, 2 )
    return file_Exists( local_path, game_path ) and not file_IsDir( local_path, game_path )
end

local file_Time = glua_file.Time

--- [SHARED AND MENU]
---
--- Returns the last modified time of a file or directory by given path.
---@param file_path string The path to the file or directory.
---@return integer unix_time The last modified time of the file or directory.
function file.getLastWriteTime( file_path )
    return file_Time( path_unpack( resolve_path( file_path ), false, 2 ) )
end

local file_Find, file_Size = glua_file.Find, glua_file.Size

--- [SHARED AND MENU]
---
--- Returns a list of files and directories by given path.
---@param file_path string The path to the file or directory.
---@return table files The list of files.
---@return table directories The list of directories.
function file.find( file_path )
    return file_Find( path_unpack( resolve_path( file_path ), false, 2 ) )
end

do

    local function search( local_path, game_path, searchable, plain, lst, offset )
        local files, directories = file_Find( local_path .. "*", game_path )
        local file_count = offset

        if searchable == nil then
            for _, file_name in raw_ipairs( files ) do
                file_count = file_count + 1
                lst[ file_count ] = local_path .. file_name
            end
        elseif plain then
            for _, file_name in raw_ipairs( files ) do
                if file_name == searchable then
                    file_count = file_count + 1
                    lst[ file_count ] = local_path .. file_name
                end
            end
        else
            for _, file_name in raw_ipairs( files ) do
                if string.match( file_name, searchable ) ~= nil then
                    file_count = file_count + 1
                    lst[ file_count ] = local_path .. file_name
                end
            end
        end

        for _, directory_name in raw_ipairs( directories ) do
            file_count = file_count + search( local_path .. directory_name .. "/", game_path, searchable, plain, lst, file_count )
        end

        return file_count - offset
    end

    --- [SHARED AND MENU]
    ---
    --- Returns a list of files and directories by given path.
    ---@param directory_path string The path to the directory to search in.
    ---@param searchable? string The string to search for, or `nil` to return ALL files in the directory.
    ---@param plain? boolean If `true`, then the search will be based on the exact file name.
    ---@return table files The list of files.
    ---@return integer count The number of files in the list.
    function file.search( directory_path, searchable, plain )
        local lst, local_path, game_path = {}, path_unpack( resolve_path( directory_path ), false, 2 )
        return lst, search( ( local_path == "" or string.byte( local_path, -1 ) == 0x2F --[[ / ]] ) and local_path or ( local_path .. "/" ), game_path, searchable, plain, lst, 0 )
    end

end

do

    local function folder_Size( local_path, game_path )
        local size = 0

        local files, directories = file_Find( local_path .. "*", game_path )

        for _, file_name in raw_ipairs( files ) do
            size = size + file_Size( local_path .. file_name, game_path )
        end

        for _, directory_name in raw_ipairs( directories ) do
            size = size + folder_Size( local_path .. directory_name .. "/", game_path )
        end

        return size
    end

    --- [SHARED AND MENU]
    ---
    --- Returns the size of a file or directory by given path.
    ---@param file_path string The path to the file or directory.
    ---@return integer size The size of the file or directory in bytes.
    function file.getSize( file_path )
        local local_path, game_path = path_unpack( resolve_path( file_path ), false, 2 )
        if file_IsDir( local_path, game_path ) then
            return folder_Size( ( local_path == "" or string.byte( local_path, -1 ) == 0x2F --[[ / ]] ) and local_path or ( local_path .. "/" ), game_path )
        else
            return file_Size( local_path, game_path )
        end
    end

end

local file_Delete, file_CreateDir = glua_file.Delete, glua_file.CreateDir

local create_Directory
do

    local function directory_Delete( local_path, game_path )
        local files, directories = file_Find( local_path .. "*", game_path )

        for _, file_name in raw_ipairs( files ) do
            file_Delete( local_path .. file_name, game_path )
        end

        for _, directory_name in raw_ipairs( directories ) do
            directory_Delete( local_path .. directory_name .. "/", game_path )
        end

        file_Delete( local_path, game_path )
    end

    --- [SHARED AND MENU]
    ---
    --- Deletes a file or directory by given path.
    ---@param file_path string The path to the file or directory to delete.
    ---@param forced? boolean If `true`, then the file or directory will be deleted even if it is not empty. (useless for files)
    function file.delete( file_path, forced )
        local local_path, game_path = path_unpack( resolve_path( file_path ), true, 2 )
        if forced and file_IsDir( local_path, game_path ) then
            directory_Delete( ( local_path == "" or string.byte( local_path, -1 ) == 0x2F --[[ / ]] ) and local_path or ( local_path .. "/" ), game_path )
        else
            file_Delete( local_path, game_path )
        end
    end

    function create_Directory( forced, local_path, game_path )
        if not file_IsDir( local_path, game_path ) then
            local parts, count = string.byteSplit( local_path, 0x2F --[[ / ]] )
            for index = 1, count, 1 do
                local directory_path = table.concat( parts, "/", 1, index )
                if not file_IsDir( directory_path, game_path ) then
                    if forced and file_Exists( directory_path, game_path ) then
                        file_Delete( directory_path, game_path )
                    end

                    ---@diagnostic disable-next-line: redundant-parameter
                    file_CreateDir( directory_path, game_path )
                end
            end
        end
    end

    --- [SHARED AND MENU]
    ---
    --- Creates a directory by given path.
    ---@param file_path string The path to the directory to create. (creates all non-existing directories in the path)
    ---@param forced? boolean If `true`, all files in the path will be deleted if they exist.
    function file.createDirectory( file_path, forced )
        return create_Directory( forced, path_unpack( resolve_path( file_path ), true, 2 ) )
    end

end

local FILE = std.debug.findmetatable( "File" )
---@cast FILE File

local FILE_Read, FILE_Write = FILE.Read, FILE.Write
local FILE_Close = FILE.Close

local file_Open = glua_file.Open

--- [SHARED AND MENU]
---
--- Reads data from a file by given path.
---@param file_path string The path to the file to read.
---@param length? integer The number of bytes to read, or `nil` to read the entire file.
---@return string data The data read from the file.
function file.read( file_path, length )
    local resolved_path = resolve_path( file_path )
    local local_path, game_path = path_unpack( resolved_path, false, 2 )

    local handler = file_Open( local_path, "rb", game_path )
    if handler == nil then
        std.error( "File '" .. resolved_path .. "' cannot be read.", 2 )
    end

    ---@diagnostic disable-next-line: cast-type-mismatch
    ---@cast handler File

    local data = FILE_Read( handler, length )
    FILE_Close( handler )

    return data
end

--- [SHARED AND MENU]
---
--- Writes data to a file by given path.
---@param file_path string The path to the file to write.
---@param data string The data to write to the file.
---@param ignore_directory? boolean If `true`, the directory will not be created if it does not exist.
function file.write( file_path, data, ignore_directory )
    local resolved_path = resolve_path( file_path )
    local local_path, game_path = path_unpack( resolved_path, true, 2 )

    if not ignore_directory then
        create_Directory( true, path.stripFile( local_path, false ), game_path )
    end

    local handler = file_Open( local_path, "wb", game_path )
    if handler == nil then
        std.error( "File '" .. resolved_path .. "' cannot be written.", 2 )
    end

    ---@diagnostic disable-next-line: cast-type-mismatch
    ---@cast handler File

    FILE_Write( handler, data )
    FILE_Close( handler )
end

--- [SHARED AND MENU]
---
--- Appends data to a file by given path.
---@param file_path string The path to the file to append.
---@param data string The data to append to the file.
---@param ignore_directory? boolean If `true`, the directory will not be created if it does not exist.
function file.append( file_path, data, ignore_directory )
    local resolved_path = resolve_path( file_path )
    local local_path, game_path = path_unpack( resolved_path, true, 2 )

    if not ignore_directory then
        create_Directory( true, path.stripFile( local_path, false ), game_path )
    end

    local handler = file_Open( local_path, "ab", game_path )
    if handler == nil then
        std.error( "File '" .. resolved_path .. "' cannot be written.", 2 )
    end

    ---@diagnostic disable-next-line: cast-type-mismatch
    ---@cast handler File

    FILE_Write( handler, data )
    FILE_Close( handler )
end


local class = std.class

do

    --- [SHARED AND MENU]
    ---
    --- TODO
    ---@alias FileReader gpm.std.file.Reader
    ---@class gpm.std.file.Reader: gpm.std.Object
    ---@field __class gpm.std.file.ReaderClass
    local Reader = class.base( "FileReader" )

    --[[

        [ 0 ] - handler
        [ 1 ] - file path

    ]]

    ---@protected
    function Reader:__init( resolving_path )
        local resolved_path = resolve_path( resolving_path )
        self[ 1 ] = resolved_path

        local local_path, game_path = path_unpack( resolved_path, false, 3 )

        local handler = file_Open( local_path, "rb", game_path )
        if handler == nil then
            std.error( "Failed to open file '" .. resolved_path .. "'.", 4 )
        end

        self[ 0 ] = handler
    end

    ---@return boolean
    ---@protected
    function Reader:__isvalid()
        return self[ 0 ] ~= nil
    end

    --- [SHARED AND MENU]
    ---
    --- Returns the path to the file.
    function Reader:path()
        return self[ 1 ]
    end

    --- [SHARED AND MENU]
    ---
    --- Closes the file.
    function Reader:close()
        local handler = self[ 0 ]
        if handler ~= nil then
            self[ 0 ] = nil
            FILE_Close( handler )
        end
    end

    --- [SHARED AND MENU]
    ---
    --- TODO
    ---@param length? integer
    ---@return string? content
    function Reader:read( length )
        local handler = self[ 0 ]
        if handler == nil then
            return nil
        end

        return FILE_Read( handler, length )
    end

    --- [SHARED AND MENU]
    ---
    --- TODO
    ---@class gpm.std.file.ReaderClass: gpm.std.file.Reader
    ---@field __base gpm.std.file.Reader
    ---@overload fun( file_path: string ): gpm.std.file.Reader
    local ReaderClass = class.create( Reader )
    file.Reader = Reader

end

do

    --- [SHARED AND MENU]
    ---
    --- TODO
    ---@alias FileWriter gpm.std.file.Writer
    ---@class gpm.std.file.Writer: gpm.std.Object
    ---@field __class gpm.std.file.WriterClass
    local Writer = class.base( "FileWriter" )

    ---@protected
    function Writer:__init()
        self[ 0 ] = {}
    end

    function Writer:__isvalid()
        return
    end

    --[[

        [ 0 ] - queue


    --]]

    --- [SHARED AND MENU]
    ---
    --- TODO
    ---@class gpm.std.file.WriterClass: gpm.std.file.Writer
    ---@field __base gpm.std.file.Writer
    ---@overload fun( file_path: string ): gpm.std.file.Writer
    local WriterClass = class.create( Writer )
    file.Writer = Writer

end
