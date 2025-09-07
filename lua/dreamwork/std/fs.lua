local _G = _G
local dreamwork = _G.dreamwork

---@class dreamwork.std
local std = dreamwork.std
local engine = dreamwork.engine

local CLIENT, SERVER, MENU = std.CLIENT, std.SERVER, std.MENU
local setmetatable = std.setmetatable

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
local gc_setTableRules = debug.gc.setTableRules

local table = std.table
local table_concat = table.concat
local table_remove = table.remove

local string = std.string
local string_len = string.len
local string_byte = string.byte
local string_match = string.match
local string_hasByte = string.hasByte
local string_byteTrim = string.byteTrim

local class = std.class

local time = std.time
local time_now = time.now

local raw = std.raw
local raw_set = raw.set
local raw_index = raw.index

local path = std.path
local path_resolve = path.resolve

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
---@field size integer The size of the file in bytes. **READ-ONLY**
---@field time integer The last modified time of the file. **READ-ONLY**
---@field path string The path to the file. **READ-ONLY**
---@field parent dreamwork.std.Directory | nil The parent directory. **READ-ONLY**
local File = class.base( "File", true )

---@class dreamwork.std.Directory : dreamwork.std.Object
---@field __class dreamwork.std.DirectoryClass
---@field name string The name of the directory. **READ-ONLY**
---@field size integer The size of the directory in bytes. **READ-ONLY**
---@field time integer The last modified time of the directory. **READ-ONLY**
---@field path string The full path of the directory. **READ-ONLY**
---@field writeable boolean If `true`, the directory is directly writeable.
---@field parent dreamwork.std.Directory | nil The parent directory. **READ-ONLY**
local Directory = class.base( "Directory", true )

---@type table<dreamwork.std.File | dreamwork.std.Directory, string>
local names = {}

do

    local invalid_characters = {
        [ 0x22 ] = true,
        [ 0x2A ] = true,
        [ 0x2F ] = true,
        [ 0x5C ] = true,
        [ 0x7C ] = true,
        [ 0x7F ] = true
    }

    for i = 0, 31, 1 do
        invalid_characters[ i ] = true
    end

    for i = 58, 63, 1 do
        invalid_characters[ i ] = true
    end

    setmetatable( names, {
        __newindex = function( self, object, name )
            for index = 1, string_len( name ), 1 do
                if invalid_characters[ string_byte( name, index, index ) ] then
                    error( string.format( "directory or file name contains invalid character \\%X at index %d in '%s'", string_byte( name, index, index ), index, name ), 2 )
                end
            end

            raw_set( self, object, name )
        end,
        __mode = "k"
    } )

end

---@type table<dreamwork.std.File | dreamwork.std.Directory, string>
local paths = {}

setmetatable( paths, {
    ---@param object dreamwork.std.File | dreamwork.std.Directory
    __index = function( self, object )
        local object_path = "/" .. names[ object ]
        raw_set( self, object, object_path )
        return object_path
    end,
    __mode = "k"
} )

---@type table<dreamwork.std.File | dreamwork.std.Directory, dreamwork.std.Directory>
local parents = {}
gc_setTableRules( parents, true, false )

---@type table<dreamwork.std.Directory, table<string | integer, dreamwork.std.File | dreamwork.std.Directory>>
local descendants = {}

setmetatable( descendants, {
    __index = function( self, object )
        ---@type table<string | integer, dreamwork.std.File | dreamwork.std.Directory>
        local directory_children = {}
        raw_set( self, object, directory_children )
        return directory_children
    end,
    __mode = "k"
} )

---@type table<dreamwork.std.Directory, integer>
local descendant_counts = {}

setmetatable( descendant_counts, {
    __index = function( self, object )
        return 0
    end,
    __mode = "k"
} )

---@type table<dreamwork.std.File | dreamwork.std.Directory, integer>
local indexes = {}
gc_setTableRules( indexes, true, false )

---@type table<dreamwork.std.File | dreamwork.std.Directory, boolean>
local is_directory_object = {}
gc_setTableRules( is_directory_object, true, false )

---@type table<dreamwork.std.Directory, string>
local mount_points = {}
gc_setTableRules( mount_points, true, false )

---@type table<dreamwork.std.Directory, string>
local mount_paths = {}
gc_setTableRules( mount_paths, true, false )

---@type table<dreamwork.std.File | dreamwork.std.Directory, integer>
local sizes = {}

setmetatable( sizes, {
    ---@param object dreamwork.std.File | dreamwork.std.Directory
    __index = function( self, object )
        local object_size

        local mount_point = mount_points[ object ]
        if mount_point == nil or is_directory_object[ object ] then
            object_size = 0
        else
            object_size = file_Size( mount_paths[ object ] or "", mount_point ) or 0
        end

        raw_set( self, object, object_size )
        return object_size
    end,
    __mode = "k"
} )

---@type table<dreamwork.std.File | dreamwork.std.Directory, integer>
local times = {}

setmetatable( times, {
    ---@param object dreamwork.std.File | dreamwork.std.Directory
    __index = function( self, object )
        local object_time

        local mount_point = mount_points[ object ]
        if mount_point == nil then
            object_time = time_now()
        else
            object_time = file_Time( mount_paths[ object ] or "", mount_point )
        end

        raw_set( self, object, object_time )
        return object_time
    end,
    __mode = "k"
} )

---@type table<string, boolean>
local writeable_mounts = {
    ["DATA"] = true
}

---@type table<string, boolean>
local deletable_mounts = {
    ["MOD"] = MENU
}

---@protected
---@param name string
---@param mount_point string | nil
---@param mount_path string | nil
function File:__init( name, mount_point, mount_path )
    names[ self ] = name
    is_directory_object[ self ] = false
    mount_paths[ self ] = mount_path
    mount_points[ self ] = mount_point
end

---@protected
---@param key string
---@return any
function File:__index( key )
    if key == "name" then
        return names[ self ]
    elseif key == "size" then
        return sizes[ self ]
    elseif key == "time" then
        return times[ self ]
    elseif key == "path" then
        return paths[ self ]
    elseif key == "parent" then
        return parents[ self ]
    else
        return raw_index( File, key )
    end
end

---@protected
---@return string
function File:__tostring()
    return string.format( "File: %p [%s][%s][%d bytes]", self, self.path, time.toDuration( time_now() - self.time ), self.size )
end

---@param object dreamwork.std.File | dreamwork.std.Directory
---@param parent dreamwork.std.Directory | nil
local function update_path( object, parent )
    if parent == nil then
        paths[ object ] = "/" .. names[ object ]
    else

        local parent_path = paths[ parent ]

        local uint8_1, uint8_2 = string_byte( parent_path, 1, 2 )
        if uint8_1 == 0x2F --[[ '/' ]] and uint8_2 == nil then
            paths[ object ] = parent_path .. names[ object ]
        else
            paths[ object ] = parent_path .. "/" .. names[ object ]
        end

    end

    if is_directory_object[ object ] then
        ---@cast object dreamwork.std.Directory

        local descendant_list = descendants[ object ]
        for index = 1, descendant_counts[ object ], 1 do
            update_path( descendant_list[ index ], object )
        end
    end
end

---@param name string
---@param mount_point string | nil
---@param mount_path string | nil
---@protected
function Directory:__init( name, mount_point, mount_path )
    names[ self ] = name
    is_directory_object[ self ] = true
    mount_paths[ self ] = mount_path
    mount_points[ self ] = mount_point
    update_path( self, nil )
end

---@protected
---@param key string
---@return any
function Directory:__index( key )
    if key == "name" then
        return names[ self ]
    elseif key == "size" then
        return sizes[ self ]
    elseif key == "time" then
        return times[ self ]
    elseif key == "path" then
        return paths[ self ]
    elseif key == "writeable" then
        local mount_point = mount_points[ self ]
        if mount_point == nil then
            return false
        else
            return writeable_mounts[ mount_point ] == true
        end
    elseif key == "parent" then
        return parents[ self ]
    else
        return raw_index( Directory, key )
    end
end

---@protected
---@return string
function Directory:__tostring()
    return string.format( "Directory: %p [%s][%s][%d bytes][%d files][%d directories]", self, self.path, time.toDuration( time_now() - self.time ), self.size, self:count() )
end

---@class dreamwork.std.FileClass : dreamwork.std.File
---@field __base dreamwork.std.File
---@overload fun( name: string, mount_point: string | nil, mount_path: string | nil ): dreamwork.std.File
local FileClass = class.create( File )

---@class dreamwork.std.DirectoryClass : dreamwork.std.Directory
---@field __base dreamwork.std.Directory
---@overload fun( name: string, mount_point: string | nil, mount_path: string | nil ): dreamwork.std.Directory
local DirectoryClass = class.create( Directory )

---@param child dreamwork.std.File | dreamwork.std.Directory
function Directory:add( child )
    if is_directory_object[ child ] == nil then
        error( "new child must be a File or a Directory", 2 )
    end

    local name = names[ child ]
    local children = descendants[ self ]

    local previous = children[ name ]
    if previous ~= nil then
        if previous == child then
            return
        else
            error( "file or directory with the same name already exists", 2 )
        end
    end

    local child_time, time_sync = times[ child ], true
    local child_size = sizes[ child ]
    local directory = self

    while directory ~= nil do
        if directory == child then
            error( "child directory cannot be parent", 2 )
        end

        sizes[ directory ] = sizes[ directory ] + child_size

        if time_sync then
            if child_time > times[ directory ] then
                times[ directory ] = child_time
            else
                time_sync = false
            end
        end

        directory = parents[ directory ]
    end

    parents[ child ] = self

    local index = descendant_counts[ self ] + 1
    descendant_counts[ self ] = index

    indexes[ child ] = index

    children[ index ] = child
    children[ name ] = child

    update_path( child, self )
end

---@param name string
function Directory:delete( name )
    local children = descendants[ self ]
    local child = children[ name ]

    if child == nil then
        return
    end

    children[ name ] = nil
    parents[ child ] = nil

    table_remove( children, indexes[ child ] )
    indexes[ child ] = nil

    update_path( child, nil )
end

---@param wildcard string | nil
---@return dreamwork.std.File[], integer, dreamwork.std.Directory[], integer
function Directory:contents( wildcard )
    local children = descendants[ self ]

    local directories, directory_count = {}, 0
    local files, file_count = {}, 0

    for index = 1, descendant_counts[ self ], 1 do
        ---@type dreamwork.std.File | dreamwork.std.Directory
        local object = children[ index ]
        if is_directory_object[ object ] then
            directory_count = directory_count + 1
            directories[ directory_count ] = object
        else
            file_count = file_count + 1
            files[ file_count ] = object
        end
    end

    local mount_point = mount_points[ self ]

    if mount_point == nil then
        return files, file_count, directories, directory_count
    end

    if wildcard == nil then
        wildcard = "*"
    elseif string_hasByte( wildcard, 0x2F --[[ '/' ]] ) then
        error( "wildcard cannot contain '/'", 2 )
    end

    local fs_files, fs_directories

    local mount_path = mount_paths[ self ]
    if mount_path == nil then
        fs_files, fs_directories = file_Find( wildcard, mount_point )
    else
        fs_files, fs_directories = file_Find( mount_path .. "/" .. wildcard, mount_point )
    end

    for index = 1, #fs_files, 1 do
        local file_name = fs_files[ index ]
        if children[ file_name ] == nil then
            file_count = file_count + 1

            local file_object

            if mount_path == nil then
                file_object = FileClass( file_name, mount_point, file_name )
            else
                file_object = FileClass( file_name, mount_point, mount_path .. "/" .. file_name )
            end

            files[ file_count ] = file_object
            self:add( file_object )
        end
    end

    for index = 1, #fs_directories, 1 do
        local directory_name = fs_directories[ index ]
        if children[ directory_name ] == nil and string_byte( directory_name, 1, 1 ) ~= 0x2F --[[ '/' ]] then
            directory_count = directory_count + 1

            local directory_object

            if mount_path == nil then
                directory_object = DirectoryClass( directory_name, mount_point, directory_name )
            else
                directory_object = DirectoryClass( directory_name, mount_point, mount_path .. "/" .. directory_name )
            end

            directories[ directory_count ] = directory_object
            self:add( directory_object )
        end
    end

    return files, file_count, directories, directory_count
end

---@return integer, integer
function Directory:count()
    local file_count, directory_count = 0, 0
    local children = descendants[ self ]

    for index = 1, descendant_counts[ self ], 1 do
        if is_directory_object[ children[ index ] ] then
            directory_count = directory_count + 1
        else
            file_count = file_count + 1
        end
    end

    return file_count, directory_count
end

---@param deep_scan boolean
---@param callback nil | fun( directory: dreamwork.std.Directory, callback_value: any )
function Directory:scan( deep_scan, callback, callback_value )
    local mount_point = mount_points[ self ]
    if mount_point == nil then
        return
    end

    local children = descendants[ self ]

    local mount_path = mount_paths[ self ]
    if mount_path == nil then
        local fs_files, fs_directories = file_Find( "*", mount_point )

        for i = 1, #fs_files, 1 do
            local file_name = fs_files[ i ]
            if children[ file_name ] == nil then
                self:add( FileClass( file_name, mount_point, file_name ) )
            end
        end

        for i = 1, #fs_directories, 1 do
            local directory_name = fs_directories[ i ]
            if children[ directory_name ] == nil then
                self:add( DirectoryClass( directory_name, mount_point, directory_name ) )
            end
        end
    else
        local fs_files, fs_directories = file_Find( mount_path .. "/*", mount_point )

         for i = 1, #fs_files, 1 do
            local file_name = fs_files[ i ]
            if children[ file_name ] == nil then
                self:add( FileClass( file_name, mount_point, mount_path .. "/" .. file_name ) )
            end
        end

        for i = 1, #fs_directories, 1 do
            local directory_name = fs_directories[ i ]
            if children[ directory_name ] == nil then
                self:add( DirectoryClass( directory_name, mount_point, mount_path .. "/" .. directory_name ) )
            end
        end
    end

    if callback ~= nil then
        callback( self, callback_value )
    end

    if deep_scan then
        for i = 1, descendant_counts[ self ], 1 do
            local directory = children[ i ]
            if is_directory_object[ directory ] then
                ---@cast directory dreamwork.std.Directory
                directory:scan( deep_scan, callback, callback_value )
            end
        end
    end
end

do

    local string_byteSplit = string.byteSplit

    ---@param path_to string
    ---@param start_position integer | nil
    function Directory:get( path_to, start_position )
        local segments, segment_count = string_byteSplit( path_to, 0x2F --[[ '/' ]], start_position )

        for i = 1, segment_count, 1 do
            local name = segments[ i ]
            local content_value = descendants[ self ][ name ]

            if content_value == nil then
                ---@cast self dreamwork.std.Directory

                local mount_point = mount_points[ self ]
                if mount_point == nil then
                    return nil, false
                end

                local mount_path = mount_paths[ self ]
                if mount_path == nil then
                    mount_path = name
                else
                    mount_path = mount_path .. "/" .. name
                end

                if file_Exists( mount_path, mount_point ) then
                    if file_IsDir( mount_path, mount_point ) then
                        local directory_object = DirectoryClass( name, mount_point, mount_path )
                        self:add( directory_object )

                        if i == segment_count then
                            return directory_object, true
                        else
                            self = directory_object
                        end
                    elseif i == segment_count then
                        local file_object = FileClass( name, mount_point, mount_path )
                        self:add( file_object )
                        return file_object, false
                    else
                        return nil, false
                    end
                else
                    return nil, false
                end
            elseif is_directory_object[ content_value ] then
                if i == segment_count then
                    ---@diagnostic disable-next-line: cast-type-mismatch
                    ---@cast content_value dreamwork.std.File
                    return content_value, true
                else
                    self = content_value
                end
            elseif i == segment_count then
                return content_value, false
            else
                return nil, false
            end
        end

        return nil, false
    end

end

---@param file_callback nil | fun( file: dreamwork.std.File )
---@param directory_callback nil | fun( directory: dreamwork.std.Directory )
function Directory:foreach( file_callback, directory_callback )
    local files, file_count, directories, directory_count = self:contents()

    if file_callback == nil then
        if directory_callback == nil then
            return
        end
    else
        for index = 1, file_count, 1 do
            ---@type dreamwork.std.File
            ---@diagnostic disable-next-line: param-type-mismatch
            file_callback( files[ index ] )
        end
    end

    for index = 1, directory_count, 1 do
        ---@type dreamwork.std.Directory
        ---@diagnostic disable-next-line: assign-type-mismatch
        local directory = directories[ index ]

        if directory_callback ~= nil then
            directory_callback( directory )
        end

        directory:foreach( file_callback, directory_callback )
    end
end

---@param prefix? string
---@param is_last? boolean
---@return string
function Directory:visualize( prefix, is_last )
    local lines, line_count = {}, 1

    local children = descendants[ self ]

    local next_prefix
    if prefix == nil then
        lines[ 1 ] = std.tostring( self )
        next_prefix = " "
    else
        lines[ 1 ] = prefix .. ( is_last and "╚═ " or "╠═ " ) .. std.tostring( self )

        local spaces = ( is_last and "    " or " " )
        next_prefix = prefix .. ( is_last and spaces or "║  " .. spaces )
    end

    local children_length = descendant_counts[ self ]

    for i = 1, children_length, 1 do
        line_count = line_count + 1
        lines[ line_count ] = next_prefix .. "║  "

        line_count = line_count + 1

        local child = children[ i ]
        if is_directory_object[ child ] then
            ---@cast child dreamwork.std.Directory
            lines[ line_count ] = child:visualize( next_prefix, i == children_length )
        else
            ---@cast child dreamwork.std.File
            lines[ line_count ] = next_prefix .. string.format( "%s %s", i == children_length and "╚═ " or "╠═ ", child )
        end
    end

    return table.concat( lines, "\n", 1, line_count )
end

local root = DirectoryClass( "", "BASE_PATH" )

---@param game_info dreamwork.engine.GameInfo
engine.hookCatch( "GameMounted", function( game_info )
    local game_folder = game_info.folder
    root:add( DirectoryClass( game_folder, game_folder ) )
end, 2 )

---@param game_info dreamwork.engine.GameInfo
engine.hookCatch( "GameUnmounted", function( game_info )
    root:delete( game_info.folder )
end, 2 )

do

    local garrysmod = DirectoryClass( "garrysmod", "MOD" )
    root:add( garrysmod )

    local data = DirectoryClass( "data", "DATA" )
    garrysmod:add( data )

end

do

    local workspace = DirectoryClass( "workspace", "GAME" )
    root:add( workspace )

    local addons = DirectoryClass( "addons" )
    workspace:add( addons )

    ---@param addon_info dreamwork.engine.AddonInfo
    engine.hookCatch( "AddonMounted", function( addon_info )
        local addon_title = addon_info.title
        addons:add( DirectoryClass( addon_title, addon_title ) )
    end, 2 )

    ---@param addon_info dreamwork.engine.AddonInfo
    engine.hookCatch( "AddonUnmounted", function( addon_info )
        addons:delete( addon_info.title )
    end, 2 )

    local download = DirectoryClass( "download", "DOWNLOAD" )
    workspace:add( download )

    local lua = DirectoryClass( "lua", ( SERVER and "lsv" or ( CLIENT and "lcl" or ( MENU and "LuaMenu" or "LUA" ) ) ) )
    workspace:add( lua )

    local map = DirectoryClass( "map", "BSP" )
    workspace:add( map )

end

--- [SHARED AND MENU]
---
--- Checks if a file or directory exists by given path.
---
---@param file_path string The path to the file.
---@return boolean exists Returns `true` if the file or directory exists, otherwise `false`.
function fs.exists( file_path )
    local resolved_path = path_resolve( file_path )

    local resolved_length = string_len( resolved_path )
    if string_byte( resolved_path, resolved_length, resolved_length ) == 0x2F --[[ '/' ]] then
        resolved_path, resolved_length = string_byteTrim( resolved_path, 0x2F, true, resolved_length )
    end

    return root:get( resolved_path, 2 ) ~= nil
end

--- [SHARED AND MENU]
---
--- Checks if a directory exists and is not a file by given path.
---
---@param directory_path string The path to the directory.
---@return boolean exists Returns `true` if the directory exists and is not a file, otherwise `false`.
function fs.isExistingDirectory( directory_path )
    local resolved_path = path_resolve( directory_path )

    local resolved_length = string_len( resolved_path )
    if string_byte( resolved_path, resolved_length, resolved_length ) == 0x2F --[[ '/' ]] then
        resolved_path, resolved_length = string_byteTrim( resolved_path, 0x2F, true, resolved_length )
    end

    local directory_object, is_directory = root:get( resolved_path, 2 )
    return directory_object ~= nil and is_directory
end

--- [SHARED AND MENU]
---
--- Checks if a file exists and is not a directory by given path.
---
---@param file_path string The path to the fs.
---@return boolean exists Returns `true` if the file exists and is not a directory, otherwise `false`.
function fs.isExistingFile( file_path )
    local resolved_path = path_resolve( file_path )

    local resolved_length = string_len( resolved_path )
    if string_byte( resolved_path, resolved_length, resolved_length ) == 0x2F --[[ '/' ]] then
        resolved_path, resolved_length = string_byteTrim( resolved_path, 0x2F, true, resolved_length )
    end

    local file_object, is_directory = root:get( resolved_path, 2 )
    return file_object ~= nil and not is_directory
end

--- [SHARED AND MENU]
---
--- Returns the last modified time of a file or directory by given path.
---
---@param file_path string The path to the file or directory.
---@return integer unix_time The last modified time of the file or directory.
function fs.time( file_path )
    local resolved_path = path_resolve( file_path )

    local resolved_length = string_len( resolved_path )
    if string_byte( resolved_path, resolved_length, resolved_length ) == 0x2F --[[ '/' ]] then
        resolved_path, resolved_length = string_byteTrim( resolved_path, 0x2F, true, resolved_length )
    end

    local object = root:get( resolved_path, 2 )
    if object == nil then
        return 0
    else
        return object.time
    end
end

--- [SHARED AND MENU]
---
--- Returns the size of a file or directory by given path.
---
---@param file_path string The path to the file or directory.
---@return integer size The size of the file or directory in bytes.
function fs.size( file_path )
    local resolved_path = path_resolve( file_path )

    local resolved_length = string_len( resolved_path )
    if string_byte( resolved_path, resolved_length, resolved_length ) == 0x2F --[[ '/' ]] then
        resolved_path, resolved_length = string_byteTrim( resolved_path, 0x2F, true, resolved_length )
    end

    local object = root:get( resolved_path, 2 )
    if object == nil then
        return 0
    else
        return object.size
    end
end

--- [SHARED AND MENU]
---
--- Returns a list of files and directories by given path.
---
---@param file_path string The path to the file or directory.
---@param searchable? string The pattern to search for, or `nil` to return ALL files and directories in the directory.
function fs.find( file_path, searchable )
    -- local resolved_path = path_resolve( file_path )

    -- local resolved_length = string_len( resolved_path )
    -- if string_byte( resolved_path, resolved_length, resolved_length ) == 0x2F --[[ '/' ]] then
    --     resolved_path, resolved_length = string_byteTrim( resolved_path, 0x2F, true, resolved_length )
    -- end

    -- local object, is_directory = root:get( resolved_path, 2 )
    -- if object == nil then
    --     return {}, 0, {}, 0
    -- elseif is_directory then
    --     ---@cast object dreamwork.std.Directory

    --     local file_objects, file_count, directory_objects, directory_count = object:find( searchable )
    --     local files, directories = {}, {}

    --     for index = 1, file_count, 1 do
    --         files[ index ] = file_objects[ index ].path
    --     end

    --     for index = 1, directory_count, 1 do
    --         directories[ index ] = directory_objects[ index ].path
    --     end

    --     return files, file_count,
    --         directories, directory_count
    -- else
    --     ---@cast object dreamwork.std.File
    --     return { object.path }, 1, {}, 0
    -- end
end

do

    local futures_yield = std.futures.yield

    ---@param file_object dreamwork.std.File
    ---@async
    local function iterate_file( file_object )
        return futures_yield( file_object.path, false )
    end

    ---@param directory_object dreamwork.std.Directory
    ---@async
    local function iterate_directory( directory_object )
        return futures_yield( directory_object.path, true )
    end

    ---@async
    function fs.iterator( file_path )
        local directory_object, is_directory = root:get( path_resolve( file_path ), 2 )

        if directory_object == nil or not is_directory then
            return
        end

        ---@cast directory_object dreamwork.std.Directory

        directory_object:foreach( iterate_file, iterate_directory )
    end

end

local function do_tralling_slash( str )
    return ( str == "" or string.byte( str, -1 ) == 0x2F --[[ '/' ]] ) and str or ( str .. "/" )
end

local function perform_path( absolute_path, write_mode, path_type )
    return "fuck", "GAME"
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
        local parts, count = string.byteSplit( local_path, 0x2F --[[ '/' ]] )
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
