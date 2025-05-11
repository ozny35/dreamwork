---@class gpm.std
local std = _G.gpm.std
local scheme = std.Color.scheme

local realm_text, realm_color

if std.MENU then
    realm_text, realm_color = "[Main Menu] ", scheme.realm_menu
elseif std.CLIENT then
    realm_text, realm_color = "[ Client ]  ", scheme.realm_client
elseif std.SERVER then
    realm_text, realm_color = "[ Server ]  ", scheme.realm_server
else
    realm_text, realm_color = "[ Unknown ] ", color_white
end

--- [SHARED AND MENU]
---
--- The logger object.
---
---@alias Logger gpm.std.Logger
---@class gpm.std.Logger : gpm.std.Object
---@field __class gpm.std.LoggerClass
local Logger = std.class.base( "Logger" )

--- [SHARED AND MENU]
---
--- The logger class.
---
---@class gpm.std.LoggerClass : gpm.std.Logger
---@field __base gpm.std.Logger
---@overload fun( options: gpm.std.Logger.Options? ) : gpm.std.Logger
local LoggerClass = std.class.create( Logger )
std.Logger = LoggerClass

local function default_debug_fn()
    return std.DEVELOPER > 0
end

--[[

    Logger:
        [ 1 ] - Title
        [ 2 ] - Color
        [ 3 ] - Text color
        [ 4 ] - Interpolation
        [ 5 ] - Debug function

--]]

local white_color = scheme.white
local primary_text_color = scheme.text_primary
local secondary_text_color = scheme.text_secondary

---@protected
function Logger:__init( options )
    if options == nil then
        self[ 1 ] = "unknown"
        self[ 2 ] = white_color
        self[ 3 ] = primary_text_color
        self[ 4 ] = true
        self[ 5 ] = default_debug_fn
    else
        local title = options.title
        if title == nil then
            self[ 1 ] = "unknown"
        else
            self[ 1 ] = title
        end

        local color = options.color
        if color == nil then
            self[ 2 ] = color_white
        else
            self[ 2 ] = color
        end

        local text_color = options.text_color
        if text_color == nil then
            self[ 3 ] = primary_text_color
        else
            self[ 3 ] = text_color
        end

        local interpolation = options.interpolation
        if interpolation == nil then
            self[ 4 ] = true
        else
            self[ 4 ] = interpolation == true
        end

        local debug_fn = options.debug
        if debug_fn == nil then
            self[ 5 ] = default_debug_fn
        else
            self[ 5 ] = debug_fn
        end
    end
end

local write_log
do

    local console_write = std.console.write
    local tostring = std.tostring
    local os_date = std.os.date

    local string = std.string
    local string_len, string_sub = string.len, string.sub
    local string_format, string_gsub = string.format, string.gsub

    --- [SHARED AND MENU]
    ---
    --- Logs a message.
    ---@param color Color The log level color.
    ---@param level string The log level name.
    ---@param str string The log message.
    ---@param ... any The log message arguments to format/interpolate.
    function write_log( object, color, level, str, ... )
        if object[ 4 ] then
            local args = { ... }
            for index = 1, select( '#', ... ), 1 do
                args[ tostring( index ) ] = tostring( args[ index ] )
            end

            str = string_gsub( str, "{([0-9]+)}", args )
        else
            str = string_format( str, ... )
        end

        local title = object[ 1 ]

        local title_length = string_len( title )
        if title_length > 64 then
            title = string_sub( title, 1, 64 )
            title_length = 64
            object[ 1 ] = title
        end

        if ( string_len( str ) + title_length ) > 950 then
            str = string_sub( str, 1, 950 - title_length ) .. "..."
        end

        console_write( secondary_text_color, os_date( "%d-%m-%Y %H:%M:%S " ), realm_color, realm_text, color, level, secondary_text_color, " --> ", object[ 2 ], title, secondary_text_color, " : ", object[ 3 ], str .. "\n")
    end

    Logger.log = write_log

end

do

    local info_color = scheme.info

    --- [SHARED AND MENU]
    ---
    --- Logs an info message.
    function Logger:info( ... )
        return write_log( self, info_color, "INFO ", ... )
    end

end

do

    local warn_color = scheme.warn

    --- [SHARED AND MENU]
    ---
    --- Logs a warning message.
    function Logger:warn( ... )
        return write_log( self, warn_color, "WARN ", ... )
    end

end

do

    local error_color = scheme.error

    --- [SHARED AND MENU]
    ---
    --- Logs an error message.
    function Logger:error( ... )
        return write_log( self, error_color, "ERROR", ... )
    end

end

do

    local debug_color = scheme.debug

    --- [SHARED AND MENU]
    ---
    --- Logs a debug message.
    function Logger:debug( ... )
        if self[ 5 ]( self ) then
            return write_log( self, debug_color, "DEBUG", ... )
        end
    end

end
