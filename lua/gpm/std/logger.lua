local std = _G.gpm.std
local Color = std.Color

local infoColor = Color( 70, 135, 255 )
local warnColor = Color( 255, 130, 90 )
local errorColor = Color( 250, 55, 40 )
local debugColor = Color( 0, 200, 150 )
local secondaryTextColor = Color( 150 )
local primaryTextColor = Color( 200 )

local state, stateColor
if std.MENU then
    state = "[Main Menu] "
    stateColor = Color( 75, 175, 80 )
elseif std.CLIENT then
    state = "[ Client ]  "
    stateColor = Color( 225, 170, 10 )
elseif std.SERVER then
    state = "[ Server ]  "
    stateColor = Color( 5, 170, 250 )
else
    state = "[ Unknown ] "
    stateColor = std.color_white
end

---@class gpm.std.LoggerOptions
---@field color? Color The color of the title.
---@field interpolation? boolean Whether to interpolate the message.
---@field debug? fun(): boolean The developer mode check function.

--- [SHARED AND MENU]
--- The logger object.
---@alias Logger gpm.std.Logger
---@class gpm.std.Logger : gpm.std.Object
---@field __class gpm.std.LoggerClass
local Logger = std.class.base( "Logger" )

local function isInDebug()
    return std.DEVELOPER > 0
end

---@protected
---@param title string
---@param options gpm.std.LoggerOptions?
function Logger:__init( title, options )
    self.title = title
    self.title_color = std.color_white
    self.interpolation = true
    self.debug_fn = isInDebug

    if options then
        if options.color then
            self.title_color = options.color
        end

        if options.interpolation ~= nil then
            self.interpolation = options.interpolation == true
        end

        if options.debug then
            self.debug_fn = options.debug
        end
    end

    self.text_color = primaryTextColor
end

do

    local console_write = std.console.write
    local tostring = std.tostring
    local os_date = std.os.date

    local string = std.string
    local string_len, string_sub = string.len, string.sub
    local string_format, string_gsub = string.format, string.gsub

    --- [SHARED AND MENU]
    --- Logs a message.
    ---@param color Color: The log level color.
    ---@param level string: The log level name.
    ---@param str string: The log message.
    ---@param ... any: The log message arguments to format/interpolate.
    function Logger:log( color, level, str, ... )
        if self.interpolation then
            local args = { ... }
            for index = 1, select( '#', ... ) do
                args[ tostring( index ) ] = tostring( args[ index ] )
            end

            str = string_gsub( str, "{([0-9]+)}", args )
        else
            str = string_format( str, ... )
        end

        local title = self.title
        local titleLength = string_len( title )
        if titleLength > 64 then
            title = string_sub( title, 1, 64 )
            titleLength = 64
            self.title = title
        end

        if ( string_len( str ) + titleLength ) > 950 then
            str = string_sub( str, 1, 950 - titleLength ) .. "..."
        end

        console_write( secondaryTextColor, os_date( "%d-%m-%Y %H:%M:%S " ), stateColor, state, color, level, secondaryTextColor, " --> ", self.title_color, title, secondaryTextColor, " : ", self.text_color, str .. "\n")
    end

end

--- [SHARED AND MENU]
--- Logs an info message.
function Logger:info( ... )
    return self:log( infoColor, "INFO ", ... )
end

--- [SHARED AND MENU]
--- Logs a warning message.
function Logger:warn( ... )
    return self:log( warnColor, "WARN ", ... )
end

--- [SHARED AND MENU]
--- Logs an error message.
function Logger:error( ... )
    return self:log( errorColor, "ERROR", ... )
end

--- [SHARED AND MENU]
--- Logs a debug message.
function Logger:debug( ... )
    if self:debug_fn() then
        return self:log( debugColor, "DEBUG", ... )
    end
end

--- [SHARED AND MENU]
--- The logger class.
---@class gpm.std.LoggerClass : gpm.std.Logger
---@field __base gpm.std.Logger
---@overload fun(title: string, options: gpm.std.LoggerOptions?): Logger
local LoggerClass = std.class.create( Logger )

return LoggerClass
