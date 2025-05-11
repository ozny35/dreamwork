local _G = _G

-- TODO: https://wiki.facepunch.com/gmod/resource
-- TODO: https://wiki.facepunch.com/gmod/Global.AddCSLuaFile

local glua_file = _G.file

---@class gpm.std
local std = _G.gpm.std

local CLIENT, SERVER, MENU = std.CLIENT, std.SERVER, std.MENU

--- [SHARED AND MENU]
---
--- The game's file library.
---
---@class gpm.std.file
local file = std.file or {}
std.file = file

local path = file.path

local debug = std.debug
local string = std.string

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
                    error( "Wrong path '/addons/" .. file_path .. "'.", 3 )
                end

                if mounted_addons[ addon_name ] then
                    return local_path or "", addon_name
                end

                error( "Addon '" .. addon_name .. "' is not mounted, path '/addons/" .. file_path .. "' is not available.", 3 )
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
                    error( "Attempt to write into read-only directory '" .. path.getDirectory( resolved_path, true ) .. "'.", ( error_level or 1 ) + 1 )
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
                    error( "Game path corrupted, critical failure.", 1 )
                end

                local mount_path = data[ 3 ]
                if mount_path == nil then
                    return string.lower( local_path ), path_name
                else
                    return mount_path .. "/" .. string.lower( local_path ), path_name
                end
            end
        end

        error( "Path '" .. resolved_path .. "' is not mounted.", ( error_level or 1 ) + 1 )
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

local function do_tralling_slash( str )
    return ( str == "" or string.byte( str, -1 ) == 0x2F --[[ / ]] ) and str or ( str .. "/" )
end

do

    local function search( local_path, game_path, searchable, plain, lst, offset )
        local files, directories = file_Find( local_path .. "*", game_path )
        local file_count = offset

        if searchable == nil then
            for i = 1, #files, 1 do
                file_count = file_count + 1
                lst[ file_count ] = local_path .. files[ i ]
            end
        elseif plain then
            for i = 1, #files, 1 do
                local file_name = files[ i ]
                if file_name == searchable then
                    file_count = file_count + 1
                    lst[ file_count ] = local_path .. file_name
                end
            end
        else
            for i = 1, #files, 1 do
                local file_name = files[ i ]
                if string.match( file_name, searchable ) ~= nil then
                    file_count = file_count + 1
                    lst[ file_count ] = local_path .. file_name
                end
            end
        end

        for i = 1, #directories, 1 do
            file_count = file_count + search( local_path .. directories[ i ] .. "/", game_path, searchable, plain, lst, file_count )
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
        return lst, search( do_tralling_slash( local_path ), game_path, searchable, plain, lst, 0 )
    end

end

---@param local_path string
---@param game_path string
---@return integer
local function directory_Size( local_path, game_path )
    local files, directories = file_Find( local_path .. "*", game_path )
    local size = 0

    for i = 1, #files, 1 do
        size = size + file_Size( local_path .. files[ i ], game_path )
    end

    for i = 1, #directories, 1 do
        size = size + directory_Size( local_path .. directories[ i ] .. "/", game_path )
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
        return directory_Size( do_tralling_slash( local_path ), game_path )
    else
        return file_Size( local_path, game_path )
    end
end

local file_Delete, file_CreateDir = glua_file.Delete, glua_file.CreateDir

---@param local_path string
---@param game_path string
local function directory_Delete( local_path, game_path )
    local files, directories = file_Find( local_path .. "*", game_path )

    for i = 1, #files, 1 do
        file_Delete( local_path .. files[ i ], game_path )
    end

    for i = 1, #directories, 1 do
        directory_Delete( local_path .. directories[ i ] .. "/", game_path )
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
        directory_Delete( do_tralling_slash( local_path ), game_path )
    else
        file_Delete( local_path, game_path )
    end
end

---@param forced? boolean
---@param local_path string
---@param game_path string
local function directory_Create( forced, local_path, game_path )
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
    return directory_Create( forced, path_unpack( resolve_path( file_path ), true, 2 ) )
end

local FILE = std.debug.findmetatable( "File" )
---@cast FILE File

local FILE_Read, FILE_Write = FILE.Read, FILE.Write
local FILE_Close = FILE.Close

local file_Open = glua_file.Open

---@param source_local_path string
---@param source_game_path string
---@param target_local_path string
---@param target_game_path string
---@param error_level? integer
local function file_Copy( source_local_path, source_game_path, target_local_path, target_game_path, error_level )
    if error_level == nil then error_level = 1 end
    error_level = error_level + 1

    local source_handler = file_Open( source_local_path, "rb", source_game_path )
    if source_handler == nil then
        error( "File '" .. source_local_path .. "' cannot be readed.", error_level )
    end

    ---@diagnostic disable-next-line: cast-type-mismatch
    ---@cast source_handler File

    local content = FILE_Read( source_handler )
    FILE_Close( source_handler )

    local target_handler = file_Open( target_local_path, "wb", target_game_path )
    if target_handler == nil then
        error( "File '" .. target_local_path .. "' cannot be written.", error_level )
    end

    ---@diagnostic disable-next-line: cast-type-mismatch
    ---@cast target_handler File

    FILE_Write( target_handler, content )
    FILE_Close( target_handler )
end

---@param source_local_path string
---@param source_game_path string
---@param target_local_path string
---@param target_game_path string
---@param error_level? integer
local function directory_Copy( source_local_path, source_game_path, target_local_path, target_game_path, error_level )
    if error_level == nil then error_level = 1 end
    error_level = error_level + 1

    ---@diagnostic disable-next-line: redundant-parameter
    file_CreateDir( target_local_path, target_game_path )

    local files, directories = file_Find( source_local_path .. "*", source_game_path )

    for i = 1, #files, 1 do
        local file_name = files[ i ]
        file_Copy( source_local_path .. file_name, source_game_path, target_local_path .. file_name, target_game_path, error_level )
    end

    for i = 1, #directories, 1 do
        local directory_name = directories[ i ]
        directory_Copy( source_local_path .. directory_name .. "/", source_game_path, target_local_path .. directory_name .. "/", target_game_path, error_level )
    end
end

--- [SHARED AND MENU]
---
--- Copies file or directory by given paths.
---@param source_path string
---@param target_path? string
---@param forced? boolean
---@return string
function file.copy( source_path, target_path, forced )
    local resolved_source_path = resolve_path( source_path )
    local source_local_path, source_game_path = path_unpack( resolved_source_path, target_path == nil, 2 )

    local resolved_target_path, target_local_path, target_game_path

    if target_path == nil then
        if file_IsDir( source_local_path, source_game_path ) then
            target_local_path, target_game_path = source_local_path .. "-copy", source_game_path
            resolved_target_path = resolved_source_path .. "-copy"
        else

            local directory, file_name_with_ext = path.stripFile( source_local_path, true )
            local file_name, extension = path.stripExtension( file_name_with_ext, true )
            local new_file_name = file_name .. "-copy" .. extension

            resolved_target_path = path.stripFile( resolved_source_path, true ) .. new_file_name
            target_local_path, target_game_path = directory .. new_file_name, source_game_path
        end
    else
        resolved_target_path = resolve_path( target_path )
        target_local_path, target_game_path = path_unpack( resolved_target_path, true, 2 )
        if target_game_path == source_game_path and target_local_path == source_local_path then
            error( "Source and target paths cannot be the same.", 2 )
        end
    end

    if forced and file_Exists( target_local_path, target_game_path ) and not file_IsDir( target_local_path, target_game_path ) then
        file_Delete( target_local_path, target_game_path )
    end

    if file_IsDir( source_local_path, source_game_path ) then
        directory_Copy( do_tralling_slash( source_local_path ), source_game_path, do_tralling_slash( target_local_path ), target_game_path, 2 )
    else
        file_Copy( source_local_path, source_game_path, target_local_path, target_game_path, 2 )
    end

    return resolved_target_path
end

--- [SHARED AND MENU]
---
--- Moves file or directory by given paths.
---@param source_path string The path to the file or directory to move.
---@param target_path string The path to the target file or directory.
---@param forced? boolean If `true`, the target file or directory will be deleted if it already exists.
---@return string new_path The path to the new file or directory.
function file.move( source_path, target_path, forced )
    local resolved_target_path = resolve_path( target_path )

    local target_local_path, target_game_path = path_unpack( resolved_target_path, true, 2 )
    local source_local_path, source_game_path = path_unpack( resolve_path( source_path ), false, 2 )

    if target_game_path == source_game_path and file_IsDir( source_local_path, source_game_path ) and string.startsWith( target_local_path, source_local_path ) then
        error( "Cannot move a file or directory to itself.", 2 )
    end

    if file_Exists( target_local_path, target_game_path ) then
        if forced then
            if file_IsDir( target_local_path, target_game_path ) then
                directory_Delete( do_tralling_slash( target_local_path ), target_game_path )
            else
                file_Delete( target_local_path, target_game_path )
            end
        elseif file_IsDir( target_local_path, target_game_path ) then
            error( "Directory '" .. target_local_path .. "' already exists.", 2 )
        else
            error( "File '" .. target_local_path .. "' already exists.", 2 )
        end
    end

    if file_IsDir( source_local_path, source_game_path ) then
        source_local_path = do_tralling_slash( source_local_path )
        directory_Copy( source_local_path, source_game_path, do_tralling_slash( target_local_path ), target_game_path, 2 )
        directory_Delete( source_local_path, source_game_path )
    else
        file_Copy( source_local_path, source_game_path, target_local_path, target_game_path, 2 )
        file_Delete( source_local_path, source_game_path )
    end

    return resolved_target_path
end

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
        error( "File '" .. resolved_path .. "' cannot be read.", 2 )
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
---@param forced? boolean If `true`, the directory will not be created if it does not exist.
function file.write( file_path, data, forced )
    local resolved_path = resolve_path( file_path )
    local local_path, game_path = path_unpack( resolved_path, true, 2 )

    if forced then
        if file_IsDir( local_path, game_path ) then
            directory_Delete( do_tralling_slash( local_path ), game_path )
        else
            directory_Create( true, path.stripFile( local_path, false ), game_path )
        end
    end

    local handler = file_Open( local_path, "wb", game_path )
    if handler == nil then
        error( "File '" .. resolved_path .. "' cannot be written.", 2 )
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
---@param forced? boolean If `true`, the directory will not be created if it does not exist.
function file.append( file_path, data, forced )
    local resolved_path = resolve_path( file_path )
    local local_path, game_path = path_unpack( resolved_path, true, 2 )

    if forced then
        if file_IsDir( local_path, game_path ) then
            directory_Delete( do_tralling_slash( local_path ), game_path )
        else
            directory_Create( true, path.stripFile( local_path, false ), game_path )
        end
    end

    local handler = file_Open( local_path, "ab", game_path )
    if handler == nil then
        error( "File '" .. resolved_path .. "' cannot be written.", 2 )
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
    ---@class gpm.std.file.Reader : gpm.std.Object
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
            error( "Failed to open file '" .. resolved_path .. "'.", 4 )
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
    ---@class gpm.std.file.ReaderClass : gpm.std.file.Reader
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
    ---@class gpm.std.file.Writer : gpm.std.Object
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
    ---@class gpm.std.file.WriterClass : gpm.std.file.Writer
    ---@field __base gpm.std.file.Writer
    ---@overload fun( file_path: string ): gpm.std.file.Writer
    local WriterClass = class.create( Writer )
    file.Writer = Writer

end
