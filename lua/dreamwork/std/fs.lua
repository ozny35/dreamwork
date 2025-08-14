local _G = _G

---@class dreamwork.std
local std = _G.dreamwork.std

-- TODO: https://wiki.facepunch.com/gmod/resource
-- TODO: https://wiki.facepunch.com/gmod/Global.AddCSLuaFile

local glua_file = _G.file
local file_Time = glua_file.Time
local file_Find = glua_file.Find
local file_Size = glua_file.Size
local file_Open = glua_file.Open
local file_IsDir = glua_file.IsDir
local file_Exists = glua_file.Exists

local FILE = std.debug.findmetatable( "File" )
---@cast FILE File

local FILE_Read, FILE_Write = FILE.Read, FILE.Write
local FILE_Close = FILE.Close

local debug = std.debug
local debug_getmetatable = debug.getmetatable

local table = std.table
local table_concat = table.concat
local table_remove = table.remove

local string = std.string
local string_len = string.len
local string_byte = string.byte
local string_match = string.match

local time = std.time
local time_now = time.now

local class = std.class

local raw = std.raw

--- [SHARED AND MENU]
---
--- The filesystem library.
---
---@class dreamwork.std.fs
local fs = std.fs or {}
std.fs = fs

---@class dreamwork.std.File : dreamwork.std.Object
---@field __class dreamwork.std.FileClass
---@field name string The name of the file. **READ-ONLY**
---@field path string The path to the file. **READ-ONLY**
---@field content string The content of the file.
---@field size integer The size of the file in bytes.
---@field time integer The last modified time of the file.
---@field parent dreamwork.std.Directory | nil The parent directory. **READ-ONLY**
---@field private mount_path string | nil The local mount_path in intenal game directory.
---@field private mount_point string | nil The name of the intenal game directory.
---@field private index integer The index of the file.
local File = class.base( "File", false )

---@class dreamwork.std.FileClass : dreamwork.std.File
---@field __base dreamwork.std.File
---@overload fun( name: string, content: string | nil, timestamp: integer | nil, mount_path: string | nil, mount_point: string | nil, parent: dreamwork.std.Directory | nil ): dreamwork.std.File
local FileClass = class.create( File )

---@protected
---@return string
function File:__tostring()
    return string.format( "File: %p [%s][%d bytes]", self, self.path, self.size )
end

do

    ---@return string
    local function get_path( self )
        return self.mount_path or self.name or ""
    end

    ---@return string
    local function get_mount( self )
        return self.mount_point or "GAME"
    end

    ---@protected
    function File:__index( key )
        if key == "size" then
            return file_Size( get_path( self ), get_mount( self ) )
        elseif key == "time" then
            return file_Time( get_path( self ), get_mount( self ) )
        elseif key == "content" then
            local handler = file_Open( get_path( self ), "rb", get_mount( self ) )
            if handler == nil then
                return -1
            else
                return FILE_Read( handler )
            end
        else
            return raw.index( File, key )
        end
    end

end

---@protected
---@param name string
---@param content string | nil
---@param timestamp integer | nil
---@param mount_path string | nil
---@param mount_point string | nil
---@param parent dreamwork.std.Directory | nil
function File:__init( name, content, timestamp, mount_path, mount_point, parent )
    self.name = name

    if parent == nil then
        self.path = "/" .. name
    else
        self:link( parent )
    end

    if mount_point == nil then
        self.time = timestamp or time_now()

        if content == nil then
            self.content = ""
            self.size = 0
        else
            self.content = content
            self.size = string_len( content )
        end

        return
    end

    self.mount_point = mount_point

    if mount_path == nil then
        mount_path = name
    end

    self.mount_path = mount_path
end

do


    ---@param self dreamwork.std.File
    ---@param parent dreamwork.std.Directory
    ---@param name string
    local function perform_update( self, parent, name )
        local directory_path = parent.path

        local uint8_1, uint8_2 = string_byte( directory_path, 1, 2 )
        if uint8_1 == 0x2F --[[ / ]] and uint8_2 == nil then
            self.path = "/" .. name
        else
            self.path = directory_path .. "/" .. name
        end

        self.parent = parent
    end

    function File:unlink()
        local parent = self.parent
        if parent == nil then
            return
        end

        self.parent = nil

        local name = self.name
        self.path = "/" .. name

        local content = parent.content

        table_remove( content, self.index )
        self.index = nil

        content[ name ] = nil
    end

    ---@param parent dreamwork.std.Directory
    function File:link( parent, half_link )
        local name = self.name

        local content = parent.content

        local child = content[ name ]
        if child ~= nil then
            if child == self then
                perform_update( self, parent, name )
                return
            else
                error( "child file with the same name already exists", 2 )
            end
        end

        perform_update( self, parent, name )

        if half_link then
            return
        end

        local next_index = #content + 1
        self.index = next_index

        content[ next_index ] = self
        content[ name ] = self
    end

end

---@class dreamwork.std.Directory : dreamwork.std.Object
---@field __class dreamwork.std.DirectoryClass
---@field name string The name of the directory.
---@field path string The full path of the directory.
---@field parent dreamwork.std.Directory | nil The parent directory.
---@field mount_path string | nil The local path in intenal game directory.
---@field mount_point string The name of the intenal game directory.
---@field private content table<string | integer, dreamwork.std.File | dreamwork.std.Directory> The content of the directory.
local Directory = class.base( "Directory", false )

---@class dreamwork.std.DirectoryClass : dreamwork.std.Directory
---@field __base dreamwork.std.Directory
---@overload fun( name: string, mount_point: string | nil, mount_path: string | nil, parent: dreamwork.std.Directory | nil ): dreamwork.std.Directory
local DirectoryClass = class.create( Directory )

---@protected
---@return string
function Directory:__tostring()
    return string.format( "Directory: %p [%s][%d files][%d directories]", self, self.path, self:contains() )
end

---@protected
---@param name string | nil
---@param mount_point string | nil
---@param mount_path string | nil
---@param parent dreamwork.std.Directory  | nil
function Directory:__init( name, mount_point, mount_path, parent )
    if name == nil then
        name = ""
    end

    self.name = name

    self.mount_path = mount_path
    self.mount_point = mount_point or "GAME"

    self.content = {}

    if parent == nil then
        self.path = "/" .. name
    else
        self:link( parent )
    end
end

---@return dreamwork.std.File[], integer, dreamwork.std.Directory[], integer
function Directory:contents()
    local mount_point = self.mount_point
    local fs_files, fs_directories

    local mount_path = self.mount_path
    if mount_path == nil then
        fs_files, fs_directories = file_Find( "*", mount_point )
    else
        fs_files, fs_directories = file_Find( mount_path .. "/*", mount_point )
    end

    local content = self.content

    local files, file_count = {}, 0

    for i = 1, #fs_files, 1 do
        local file_name = fs_files[ i ]
        if content[ file_name ] == nil then
            file_count = file_count + 1

            if mount_path == nil then
                files[ file_count ] = FileClass( file_name, nil, nil, file_name, mount_point, self )
            else
                files[ file_count ] = FileClass( file_name, nil, nil, mount_path .. "/" .. file_name, mount_point, self )
            end
        end
    end

    local directories, directory_count = {}, 0

    for i = 1, #fs_directories, 1 do
        local directory_name = fs_directories[ i ]
        if content[ directory_name ] == nil then
            directory_count = directory_count + 1

            if mount_path == nil then
                directories[ directory_count ] = DirectoryClass( directory_name, mount_point, directory_name, self )
            else
                directories[ directory_count ] = DirectoryClass( directory_name, mount_point, mount_path .. "/" .. directory_name, self )
            end
        end
    end

    for i = 1, #content, 1 do
        ---@type dreamwork.std.File | dreamwork.std.Directory
        local object = content[ i ]

        local metatable = debug_getmetatable( object )
        if metatable == File then
            file_count = file_count + 1
            files[ file_count ] = object
        elseif metatable == Directory then
            directory_count = directory_count + 1
            directories[ directory_count ] = object
        end
    end

    return files, file_count,
        directories, directory_count
end

---@return integer, integer
function Directory:contains()
    local mount_point = self.mount_point
    local fs_files, fs_directories

    local mount_path = self.mount_path
    if mount_path == nil then
        fs_files, fs_directories = file_Find( "*", mount_point )
    else
        fs_files, fs_directories = file_Find( mount_path .. "/*", mount_point )
    end

    local content = self.content

    local file_count = 0

    for i = 1, #fs_files, 1 do
        local file_name = fs_files[ i ]
        if content[ file_name ] == nil then
            file_count = file_count + 1
        end
    end

    local directory_count = 0

    for i = 1, #fs_directories, 1 do
        local directory_name = fs_directories[ i ]
        if content[ directory_name ] == nil then
            directory_count = directory_count + 1
        end
    end

    for i = 1, #content, 1 do
        local metatable = debug_getmetatable( content[ i ] )
        if metatable == File then
            file_count = file_count + 1
        elseif metatable == Directory then
            directory_count = directory_count + 1
        end
    end

    return file_count, directory_count
end

--- [SHARED AND MENU]
---
--- Returns a list of files and directories by given path.
---
---@param searchable? string The string to search for, or `nil` to return ALL files in the directory.
---@param with_pattern? boolean If set to `true`, `searchable` will be used as a pattern.
---@return dreamwork.std.File[], integer, dreamwork.std.Directory[], integer
function Directory:search( searchable, with_pattern )
    local files, file_count, directories, directory_count = self:contents()

    ---@type dreamwork.std.File[], integer
    local found_files, found_files_count = {}, 0

    for i = 1, file_count, 1 do
        local file = files[ i ]
        if not with_pattern or searchable == nil or string_match( file.name, searchable, 1 ) ~= nil then
            found_files_count = found_files_count + 1
            found_files[ found_files_count ] = file
        end
    end

    ---@type dreamwork.std.Directory[], integer
    local found_directories, found_directories_count = {}, 0

    for i = 1, directory_count, 1 do
        local directory = directories[ i ]
        if not with_pattern or searchable == nil or string_match( directory.name, searchable, 1 ) ~= nil then
            found_directories_count = found_directories_count + 1
            found_directories[ found_directories_count ] = directory
        end
    end

    return found_files, found_files_count,
        found_directories, found_directories_count
end

do

    local string_byteSplit = string.byteSplit

    --- [SHARED AND MENU]
    ---
    --- Returns a file object by given path.
    ---
    ---@param path_to_file string The path to the file.
    ---@return dreamwork.std.File | nil file The file object, or `nil` if not found.
    function Directory:getFile( path_to_file )
        local segments, segment_count = string_byteSplit( path_to_file, 0x2F --[[ / ]] )

        for index = 1, segment_count, 1 do
            local name = segments[ index ]

            local content_value = self.content[ name ]

            if content_value == nil then
                ---@cast self dreamwork.std.Directory

                local mount_point = self.mount_point
                local fs_files, fs_directories

                local mount_path = self.mount_path
                if mount_path == nil then
                    fs_files, fs_directories = file_Find( "*", mount_point )
                else
                    fs_files, fs_directories = file_Find( mount_path .. "/*", mount_point )
                end

                for i = 1, #fs_files, 1 do
                    local file_name = fs_files[ i ]
                    if file_name == name then
                        if mount_path == nil then
                            return FileClass( file_name, nil, nil, file_name, mount_point, self )
                        else
                            return FileClass( file_name, nil, nil, mount_path .. "/" .. file_name, mount_point, self )
                        end
                    end
                end

                if index == segment_count then
                    return nil
                end

                for i = 1, #fs_directories, 1 do
                    local directory_name = fs_directories[ i ]
                    if directory_name == name then
                        if mount_path == nil then
                            self = DirectoryClass( directory_name, mount_point, directory_name, self )
                        else
                            self = DirectoryClass( directory_name, mount_point, mount_path .. "/" .. directory_name, self )
                        end
                    end
                end
            elseif debug_getmetatable( content_value ) == File then
                if index == segment_count then
                    ---@diagnostic disable-next-line: cast-type-mismatch
                    ---@cast content_value dreamwork.std.File
                    return content_value
                else
                    return nil
                end
            else
                self = content_value
            end
        end

        return nil
    end

    --- [SHARED AND MENU]
    ---
    --- Returns a directory object by given path.
    ---
    ---@param path_to_directory string The path to the directory.
    ---@return dreamwork.std.Directory | nil directory The directory object, or `nil` if not found.
    function Directory:getDirectory( path_to_directory )
        local segments, segment_count = string_byteSplit( path_to_directory, 0x2F --[[ / ]] )

        for index = 1, segment_count, 1 do
            local name = segments[ index ]

            local content_value = self.content[ name ]
            if content_value == nil then
                local mount_point = self.mount_point
                local _, fs_directories

                local mount_path = self.mount_path
                if mount_path == nil then
                    _, fs_directories = file_Find( "*", mount_point )
                else
                    _, fs_directories = file_Find( mount_path .. "/*", mount_point )
                end

                for i = 1, #fs_directories, 1 do
                    local directory_name = fs_directories[ i ]
                    if directory_name == name then
                        if mount_path == nil then
                            self = DirectoryClass( directory_name, mount_point, directory_name, self )
                        else
                            self = DirectoryClass( directory_name, mount_point, mount_path .. "/" .. directory_name, self )
                        end
                    end
                end
            elseif debug_getmetatable( content_value ) == File then
                return nil
            else
                self = content_value
            end
        end

        ---@cast self dreamwork.std.Directory
        return self
    end

end

---@param file_callback nil | fun( file: dreamwork.std.File )
---@param directory_callback nil | fun( directory: dreamwork.std.Directory )
function Directory:foreach( file_callback, directory_callback )
    local files, file_count, directories, directory_count = self:contents()
    local content = self.content

    if file_callback == nil then
        if directory_callback == nil then
            return
        end
    else
        for i = 1, file_count, 1 do
            ---@type dreamwork.std.File
            ---@diagnostic disable-next-line: param-type-mismatch
            file_callback( content[ files[ i ].name ] )
        end
    end

    for i = 1, directory_count, 1 do
        ---@type dreamwork.std.Directory
        ---@diagnostic disable-next-line: assign-type-mismatch
        local directory = content[ directories[ i ].name ]

        directory:foreach( file_callback, directory_callback )

        if directory_callback ~= nil then
            directory_callback( directory )
        end
    end
end

do

    ---@param self dreamwork.std.Directory
    ---@param parent dreamwork.std.Directory
    ---@param name string
    local function perform_update( self, parent, name )
        local directory_path = parent.path

        local uint8_1, uint8_2 = string_byte( directory_path, 1, 2 )
        if uint8_1 == 0x2F --[[ / ]] and uint8_2 == nil then
            self.path = "/" .. name
        else
            self.path = directory_path .. "/" .. name
        end

        self.parent = parent

        for index = 1, #self, 1 do
            local child = self[ index ]
            perform_update( child, self, child.name )
        end
    end

    function Directory:unlink()
        local parent = self.parent
        if parent == nil then
            return
        end

        self.parent = nil

        local name = self.name
        self.path = "/" .. name

        local content = parent.content

        table_remove( content, self.index )
        self.index = nil

        content[ name ] = nil

        for index = 1, #self, 1 do
            local child = self[ index ]
            perform_update( child, self, child.name )
        end
    end

    ---@param parent dreamwork.std.Directory
    function Directory:link( parent )
        local name = self.name

        local content = parent.content

        local child = content[ name ]
        if child ~= nil then
            if child == self then
                perform_update( self, parent, name )
                return
            else
                error( "child directory with the same name already exists", 2 )
            end
        end

        local sub_directory = parent
        while sub_directory ~= nil do
            if sub_directory == self then
                error( "child directory cannot be parent", 2 )
            end

            sub_directory = sub_directory.parent
        end

        local next_index = #content + 1
        self.index = next_index

        content[ next_index ] = self
        content[ name ] = self

        perform_update( self, parent, name )
    end

end

local root = DirectoryClass( "", "BASE_PATH" )

local garrysmod = DirectoryClass( "garrysmod", "GAME", nil, root )

local lua = DirectoryClass( "lua",
    ( std.SERVER and "lsv" or
    ( std.CLIENT and "lcl" or
    ( std.MENU and "LuaMenu" or
    "LUA" ) ) ), nil, garrysmod )

-- PrintTable( root:contents(), nil )

-- lua:getDirectory( "dreamwork" ):foreach( print )

-- if SERVER then
--     local start = time.elapsed( "s", true )
--     root:foreach( std.debug.fempty )
--     std.printf( "%f", time.elapsed( "s", true ) - start )
-- end

local CLIENT, SERVER, MENU = std.CLIENT, std.SERVER, std.MENU

local path = std.path
local path_resolve = path.resolve

local string = std.string

local engine = dreamwork.engine

local perform_path
do

    local title2addon = engine.title2addon
    local name2game = engine.name2game

    -- TODO: remap all local paths like /lua, /materials, /models and etc to local package gma, like file.Read( "lua", "package_name" )


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

                if title2addon[ addon_name ] then
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
        }
    }

    for i = 1, #fstab do
        local data = fstab[ i ]
        data[ 5 ] = string.len( data[ 1 ] )
    end

    local fstab_length = #fstab

    ---@param resolved_path string
    ---@param write_mode boolean
    ---@param stack_level integer
    ---@return string local_path
    ---@return string game_path
    function perform_path( resolved_path, write_mode, stack_level )
        stack_level = stack_level + 1

        for i = 1, fstab_length, 1 do
            local data = fstab[ i ]

            local mounted_path = data[ 1 ]
            if mounted_path == resolved_path or string.sub( resolved_path, 1, data[ 5 ] + 1 ) == ( mounted_path .. "/" ) then
                if write_mode and not data[ 4 ] then
                    error( "Attempt to write into read-only directory '" .. path.getDirectory( resolved_path, true ) .. "'.", ( stack_level or 1 ) + 1 )
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

        local game_folder, local_path = string.match( resolved_path, "([^/]+)/?(.*)" )

        if game_folder == nil then
            return "", "BASE_PATH"
        elseif name2game[ game_folder ] then
            return local_path, game_folder
        else
            return local_path, "BASE_PATH"
        end
    end

end

-- TODO: path.unpack and path.pack for garrysmod filesystem

--- [SHARED AND MENU]
---
--- Checks if a file or directory exists by given path.
---@param file_path string The path to the file.
---@return boolean exists Returns `true` if the file or directory exists, otherwise `false`.
function fs.exists( file_path )
    return file_Exists( perform_path( path_resolve( file_path ), false, 2 ) )
end

--- [SHARED AND MENU]
---
--- Checks if a directory exists and is not a file by given path.
---@param directory_path string The path to the directory.
---@return boolean exists Returns `true` if the directory exists and is not a file, otherwise `false`.
function fs.isExistingDirectory( directory_path )
    return file_IsDir( perform_path( path_resolve( directory_path ), false, 2 ) )
end

--- [SHARED AND MENU]
---
--- Checks if a file exists and is not a directory by given path.
---@param file_path string The path to the fs.
---@return boolean exists Returns `true` if the file exists and is not a directory, otherwise `false`.
function fs.isExistingFile( file_path )
    local local_path, game_path = perform_path( path_resolve( file_path ), false, 2 )
    return file_Exists( local_path, game_path ) and not file_IsDir( local_path, game_path )
end

--- [SHARED AND MENU]
---
--- Returns the last modified time of a file or directory by given path.
---@param file_path string The path to the file or directory.
---@return integer unix_time The last modified time of the file or directory.
function fs.getLastWriteTime( file_path )
    return file_Time( perform_path( path_resolve( file_path ), false, 2 ) )
end

--- [SHARED AND MENU]
---
--- Returns a list of files and directories by given path.
---@param file_path string The path to the file or directory.
---@return table files The list of files.
---@return table directories The list of directories.
function fs.find( file_path )
    return file_Find( perform_path( path_resolve( file_path ), false, 2 ) )
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
    function fs.search( directory_path, searchable, plain )
        local lst, local_path, game_path = {}, perform_path( path_resolve( directory_path ), false, 2 )
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
---
---@param file_path string The path to the file or directory.
---@return integer size The size of the file or directory in bytes.
function fs.getSize( file_path )
    local local_path, game_path = perform_path( path_resolve( file_path ), false, 2 )
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
---
---@param file_path string The path to the file or directory to delete.
---@param forced? boolean If `true`, then the file or directory will be deleted even if it is not empty. (useless for files)
function fs.delete( file_path, forced )
    local local_path, game_path = perform_path( path_resolve( file_path ), true, 2 )
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
            local directory_path = table_concat( parts, "/", 1, index )
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
---
---@param file_path string The path to the directory to create. (creates all non-existing directories in the path)
---@param forced? boolean If `true`, all files in the path will be deleted if they exist.
function fs.createDirectory( file_path, forced )
    return directory_Create( forced, perform_path( path_resolve( file_path ), true, 2 ) )
end


---@param source_local_path string
---@param source_game_path string
---@param target_local_path string
---@param target_game_path string
---@param error_level? integer
local function file_Copy( source_local_path, source_game_path, target_local_path, target_game_path, error_level )
    error_level = ( error_level or 1 ) + 1

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
        error( "file '" .. target_local_path .. "' is not writable", error_level )
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
---
---@param source_path string The path to the file or directory to copy.
---@param target_path? string The path to the target file or directory.
---@param forced? boolean If `true`, the target file or directory will be deleted if it already exists.
---@return string new_path The path to the new file or directory.
function fs.copy( source_path, target_path, forced )
    local resolved_source_path = path_resolve( source_path )
    local source_local_path, source_game_path = perform_path( resolved_source_path, target_path == nil, 2 )

    local resolved_target_path, target_local_path, target_game_path

    if target_path == nil then
        if file_IsDir( source_local_path, source_game_path ) then
            target_local_path, target_game_path = source_local_path .. "-copy", source_game_path
            resolved_target_path = resolved_source_path .. "-copy"
        else

            local directory, file_name_with_ext = path.split( source_local_path, true )
            local file_name, extension = path.splitExtension( file_name_with_ext, true )
            local new_file_name = file_name .. "-copy" .. extension

            resolved_target_path = path.split( resolved_source_path, true ) .. new_file_name
            target_local_path, target_game_path = directory .. new_file_name, source_game_path
        end
    else
        resolved_target_path = path_resolve( target_path )
        target_local_path, target_game_path = perform_path( resolved_target_path, true, 2 )
        if target_game_path == source_game_path and target_local_path == source_local_path then
            error( "source and target paths cannot be the same", 2 )
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
---
---@param source_path string The path to the file or directory to move.
---@param target_path string The path to the target file or directory.
---@param forced? boolean If `true`, the target file or directory will be deleted if it already exists.
---@return string new_path The path to the new file or directory.
function fs.move( source_path, target_path, forced )
    local resolved_target_path = path_resolve( target_path )

    local target_local_path, target_game_path = perform_path( resolved_target_path, true, 2 )
    local source_local_path, source_game_path = perform_path( path_resolve( source_path ), false, 2 )

    if target_game_path == source_game_path and file_IsDir( source_local_path, source_game_path ) and string.startsWith( target_local_path, source_local_path ) then
        error( "cannot move the directory to itself", 2 )
    end

    if file_Exists( target_local_path, target_game_path ) then
        if forced then
            if file_IsDir( target_local_path, target_game_path ) then
                directory_Delete( do_tralling_slash( target_local_path ), target_game_path )
            else
                file_Delete( target_local_path, target_game_path )
            end
        elseif file_IsDir( target_local_path, target_game_path ) then
            error( "directory '" .. resolved_target_path .. "' already exists", 2 )
        else
            error( "file '" .. resolved_target_path .. "' already exists", 2 )
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
--- Reads content from a file by given path.
---
---@param file_path string The path to the file to read.
---@param length? integer The number of bytes to read, or `nil` to read the entire file.
---@return string content The content of the file or `nil` if failed.
function fs.read( file_path, length )
    local resolved_path = path_resolve( file_path )
    local local_path, game_path = perform_path( resolved_path, false, 2 )

    local handler = file_Open( local_path, "rb", game_path )
    if handler == nil then
        error( "file '" .. resolved_path .. "' is not readable", 2 )
    end

    ---@diagnostic disable-next-line: cast-type-mismatch
    ---@cast handler File

    local content = FILE_Read( handler, length )
    FILE_Close( handler )

    return content
end

--- [SHARED AND MENU]
---
--- Writes data to a file by given path.
---
---@param file_path string The path to the file to write.
---@param data string The data to write to the file.
---@param forced? boolean If `true`, the directory will not be created if it does not exist.
function fs.write( file_path, data, forced )
    local resolved_path = path_resolve( file_path )
    local local_path, game_path = perform_path( resolved_path, true, 2 )

    if forced then
        if file_IsDir( local_path, game_path ) then
            directory_Delete( do_tralling_slash( local_path ), game_path )
        else
            directory_Create( true, path.split( local_path, false ), game_path )
        end
    end

    local handler = file_Open( local_path, "wb", game_path )
    if handler == nil then
        error( "file '" .. resolved_path .. "' is not writable", 2 )
    end

    ---@diagnostic disable-next-line: cast-type-mismatch
    ---@cast handler File

    FILE_Write( handler, data )
    FILE_Close( handler )
end

--- [SHARED AND MENU]
---
--- Appends data to a file by given path.
---
---@param file_path string The path to the file to append.
---@param data string The data to append to the file.
---@param forced? boolean If `true`, the directory will not be created if it does not exist.
function fs.append( file_path, data, forced )
    local resolved_path = path_resolve( file_path )
    local local_path, game_path = perform_path( resolved_path, true, 2 )

    if forced then
        if file_IsDir( local_path, game_path ) then
            directory_Delete( do_tralling_slash( local_path ), game_path )
        else
            directory_Create( true, path.split( local_path, false ), game_path )
        end
    end

    local handler = file_Open( local_path, "ab", game_path )
    if handler == nil then
        error( "file '" .. resolved_path .. "' is not writable", 2 )
    end

    ---@diagnostic disable-next-line: cast-type-mismatch
    ---@cast handler File

    FILE_Write( handler, data )
    FILE_Close( handler )
end

-- TODO: Reader and Writer or something better like FileClass that can returns FileReader and FileWriter in cases

--[[

    TODO:

    _G.LoadAddonPresets
    _G.SaveAddonPresets

    https://wiki.facepunch.com/gmod/Global.LoadPresets
    https://wiki.facepunch.com/gmod/Global.SavePresets

]]
