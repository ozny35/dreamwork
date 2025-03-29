---@class gpm.std
local std = _G.gpm.std

local debug_getstack, debug_getupvalue, debug_getlocal
do
    local debug = std.debug
    debug_getstack, debug_getupvalue, debug_getlocal = debug.getstack, debug.getupvalue, debug.getlocal
end

local string = std.string
local string_rep, string_format = string.rep, string.format

local table_concat = std.table.concat

local class_base, class_create
do
    local class = std.class
    class_base, class_create = class.base, class.create
end

---@diagnostic disable-next-line: undefined-field
local ErrorNoHalt, ErrorNoHaltWithStack = _G.ErrorNoHalt, _G.ErrorNoHaltWithStack

if not ErrorNoHalt then
    ErrorNoHalt = std.print
end

if not ErrorNoHaltWithStack then
    ErrorNoHaltWithStack = std.print
end

local callStack, callStackSize = {}, 0

-- local function pushCallStack( stack )
--     local size = callStackSize + 1
--     callStack[ size ] = stack
--     callStackSize = size
-- end

-- local function popCallStack()
--     local pos = callStackSize
--     if pos == 0 then
--         return nil
--     end

--     local stack = callStack[ pos ]
--     callStack[ pos ] = nil
--     callStackSize = pos - 1
--     return stack
-- end

-- local function appendStack( stack )
--     return pushCallStack( { stack, callStack[ callStackSize ] } )
-- end

local function mergeStack( stack )
    local pos = #stack

    local currentCallStack = callStack[ callStackSize ]
    while currentCallStack do
        local lst = currentCallStack[ 1 ]
        for i = 1, #lst do
            local info = lst[ i ]
            pos = pos + 1
            stack[ pos ] = info
        end

        currentCallStack = currentCallStack[ 2 ]
    end

    return stack
end

local dumpFile
do

    local math_min, math_max, math_floor, math_log10, math_huge
    do
        local math = std.math
        math_min, math_max, math_floor, math_log10, math_huge = math.min, math.max, math.floor, math.log10, math.huge
    end

    local string_split, string_find, string_sub, string_len = string.split, string.find, string.sub, string.len
    local console_write = std.console.write

    -- TODO: Repace later with new File class
    local file_Open = _G.file.Open

    local gray = Color( 180, 180, 180 )
    local white = Color( 225, 225, 225 )
    local danger = Color( 239, 68, 68 )

    dumpFile = function( message, fileName, line )
        if not ( fileName and line ) then return end

        ---@class File
        ---@diagnostic disable-next-line: assign-type-mismatch
        local handler = file_Open( fileName, "rb", "GAME" )
        if handler == nil then return end

        local str = handler:Read( handler:Size() )
        handler:Close()

        if string_len( str ) == 0 then
            return
        end

        local lines = string_split( str, "\n" )
        if not ( lines and lines[ line ] ) then
            return
        end

        local start = math_max( 1, line - 5 )
        local finish = math_min( #lines, line + 3 )
        local numWidth = math_floor( math_log10( finish ) ) + 1

        local longestLine, firstChar = 0, math_huge
        for i = start, finish do
            local code = lines[ i ]
            local pos = string_find( code, "%S" )
            if pos and pos < firstChar then
                firstChar = pos
            end

            longestLine = math_max( longestLine, string_len( code ) )
        end

        longestLine = math_min( longestLine - firstChar, 120 )
        console_write( gray, string_rep( " ", numWidth + 3 ), string_rep( "_", longestLine + 4 ), "\n", string_rep( " ", numWidth + 2 ), "|\n" )

        local numFormat = " %0" .. numWidth .. "d | "
        for i = start, finish do
            local code = lines[ i ]

            console_write( i == line and white or gray, string_format( numFormat, i ), string_sub( code, firstChar, longestLine + firstChar ), "\n" )

            if i == line then
                console_write(
                    gray, string_rep(" ", numWidth + 2), "| ", string_sub( code, firstChar, ( string_find( code, "%S" ) or 1 ) - 1 ), danger, "^ ", tostring( message ), "\n",
                    gray, string_rep(" ", numWidth + 2), "|\n"
                )
            end
        end

        console_write( gray, string_rep( " ", numWidth + 2 ), "|\n", string_rep( " ", numWidth + 3 ), string_rep( "¯", longestLine + 4 ), "\n\n" )
    end

end

--- [SHARED AND MENU]
---
--- Error object.
---@alias Error gpm.std.Error
---@class gpm.std.Error : gpm.std.Object
---@field __class gpm.std.ErrorClass
---@field __parent gpm.std.Error | nil
---@field name string
local Error = class_base( "Error" )

---@protected
function Error:__index( key )
    if key == "name" then
        return self.__type
    end

    return Error[ key ]
end

---@protected
function Error:__tostring()
    if self.fileName then
        return string_format( "%s:%d: %s: %s", self.fileName, self.lineNumber or 0, self.name, self.message )
    else
        return self.name .. ": " .. self.message
    end
end

---@protected
---@param message string
---@param fileName string?
---@param lineNumber number?
---@param stackPos integer?
function Error:__init( message, fileName, lineNumber, stackPos )
    if stackPos == nil then stackPos = 0 end
    self.lineNumber = lineNumber
    self.fileName = fileName
    self.message = message

    local stack = debug_getstack( stackPos )
    self.stack = stack
    mergeStack( stack )

    local first = stack[ 1 ]
    if first == nil then return end

    self.fileName = self.fileName or first.short_src
    self.lineNumber = self.lineNumber or first.currentline

    if debug_getupvalue and first.func and first.nups and first.nups > 0 then
        local upvalues = {}
        self.upvalues = upvalues

        for i = 1, first.nups do
            local name, value = debug_getupvalue( first.func, i )
            if name == nil then
                self.upvalues = nil
                break
            end

            upvalues[ i ] = { name, value }
        end
    end

    if debug_getlocal then
        local locals, count, i = {}, 0, 1
        while true do
            local name, value = debug_getlocal( stackPos, i )
            if name == nil then break end

            if name ~= "(*temporary)" then
                count = count + 1
                locals[ count ] = { name, value }
            end

            i = i + 1
        end

        if count ~= 0 then
            self.locals = locals
        end
    end
end

--- [SHARED AND MENU]
---
--- Displays the error.
function Error:display()
    if isstring( self ) then
        ---@diagnostic disable-next-line: cast-type-mismatch
        ---@cast self string
        ErrorNoHaltWithStack( self )
        return
    end

    local lines, length = { "\n[ERROR] " .. tostring( self ) }, 1

    local stack = self.stack
    if stack then
        for i = 1, #stack do
            local info = stack[ i ]
            length = length + 1
            lines[ length ] = string_format( "%s %d. %s - %s:%d", string_rep( " ", i ), i, info.name or "unknown", info.short_src, info.currentline or -1 )
        end
    end

    local locals = self.locals
    if locals then
        length = length + 1
        lines[ length ] = "\n=== Locals ==="

        for i = 1, #locals do
            local entry = locals[ i ]
            length = length + 1
            lines[ length ] = string_format( "  - %s = %s", entry[ 1 ], entry[ 2 ] )
        end
    end

    local upvalues = self.upvalues
    if upvalues ~= nil then
        length = length + 1
        lines[ length ] = "\n=== Upvalues ==="

        for i = 1, #upvalues do
            local entry = upvalues[ i ]
            length = length + 1
            lines[ length ] = string_format( "  - %s = %s", entry[ 1 ], entry[ 2 ] )
        end
    end

    length = length + 1
    lines[ length ] = "\n"
    ErrorNoHalt( table_concat( lines, "\n", 1, length ) )

    if self.message and self.fileName and self.lineNumber then
        dumpFile( self.name .. ": " .. self.message, self.fileName, self.lineNumber )
    end
end

--- [SHARED AND MENU]
---
--- Basic error class.
---@class gpm.std.ErrorClass : gpm.std.Error
---@field __base gpm.std.Error
---@overload fun(message: string, fileName: string?, lineNumber: number?, stackPos: number?): Error
local ErrorClass = class_create( Error )
std.Error = ErrorClass

--- [SHARED AND MENU]
---
--- Creates a new `Error` with custom name.
---@param name string The name of the error.
---@param base Error | nil: The base class of the error.
---@return Error cls The new error class.
function ErrorClass.make( name, base )
    return class_create( class_base( name, base or ErrorClass ) ) ---@type Error
end

-- Built-in error classes.
std.NotImplementedError = ErrorClass.make( "NotImplementedError" )
std.FutureCancelError = ErrorClass.make( "FutureCancelError" )
std.InvalidStateError = ErrorClass.make( "InvalidStateError" )
std.CodeCompileError = ErrorClass.make( "CodeCompileError" )
std.FileSystemError = ErrorClass.make( "FileSystemError" )
std.HTTPClientError = ErrorClass.make( "HTTPClientError" )
std.RuntimeError = ErrorClass.make( "RuntimeError" )
std.PackageError = ErrorClass.make( "PackageError" )
std.ModuleError = ErrorClass.make( "ModuleError" )
std.SourceError = ErrorClass.make( "SourceError" )
std.FutureError = ErrorClass.make( "FutureError" )
std.AddonError = ErrorClass.make( "AddonError" )
std.RangeError = ErrorClass.make( "RangeError" )
std.TypeError = ErrorClass.make( "TypeError" )

---@alias gpm.std.ErrorType
---| number # error with level
---| `-1` # ErrorNoHalt
---| `-2` # ErrorNoHaltWithStack
