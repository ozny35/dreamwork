local _G = _G

---@class gpm.std
local std = _G.gpm.std
local string = std.string

local glua_sql = _G.sql

--- [SHARED AND MENU]
---
--- The local SQLite library.
---
---@class gpm.std.sqlite
local sqlite = std.sqlite or {}
std.sqlite = sqlite

--- [SHARED AND MENU]
---
--- Returns the last error message from the last query.
---
---@return string | nil err_msg The last error message.
function sqlite.getLastError()
    return glua_sql.m_strError
end

local escape
do

    local string_replace, string_find, string_sub = string.replace, string.find, string.sub

    --- [SHARED AND MENU]
    ---
    --- Converts a string to a safe string for use in an SQL query.
    ---
    ---@param str string? The string to convert.
    ---@return string str The safe string.
    function escape( str, no_quotes )
        if str == nil then
            return "null"
        end

        str = string_replace( str, "'", "''", false )

        local null_chr = string_find( str, "\0", 1, false )
        if null_chr then
            str = string_sub( str, 1, null_chr - 1 )
        end

        if no_quotes then
            return str
        else
            return "'" .. str .. "'"
        end
    end

end

sqlite.escape = escape

local rawQuery
do

    local sql_Query = glua_sql.Query
    local gpm_Logger = _G.gpm.Logger
    local getfenv = std.getfenv
    local type = std.type

    --- [SHARED AND MENU]
    ---
    --- Executes a raw SQL query.
    ---
    ---@param str string The SQL query to execute.
    ---@return table? result The result of the query.
    function rawQuery( str )
        local fenv = getfenv( 2 )
        if fenv == nil then
            gpm_Logger:debug( "Executing SQL query: " .. str )
        else
            local logger = fenv.Logger
            if type( logger ) == "Logger" then
                ---@cast logger Logger
                logger:debug( "Executing SQL query: " .. str )
            else
                gpm_Logger:debug( "Executing SQL query: " .. str )
            end
        end

        ---@type table | false | nil
        local result = sql_Query( str )
        if result == false then
            error( glua_sql.m_strError, 2 )
        end

        return result
    end

end

sqlite.rawQuery = rawQuery

--- [SHARED AND MENU]
---
--- Checks if a table exists in the database.
---
---@param name string The name of the table to check.
---@return boolean exist `true` if the table exists, `false` otherwise.
function sqlite.tableExists( name )
    return rawQuery( "select name from sqlite_master where name=" .. escape( name ) .. " and type='table'" ) ~= nil
end

--- [SHARED AND MENU]
---
--- Checks if an index exists in the database.
---
---@param name string The name of the index to check.
---@return boolean exist `true` if the index exists, `false` otherwise.
function sqlite.indexExists( name )
    return rawQuery( "select name from sqlite_master where name=" .. escape( name ) .. " and type='index'" ) ~= nil
end

local query
do

    local string_gsub = string.gsub

    --- [SHARED AND MENU]
    ---
    --- Executes a SQL query with parameters.
    ---
    ---@param str string The SQL query to execute.
    ---@param ... string The parameters to use in the query.
    ---@return table? result The result of the query.
    function query( str, ... )
        local args, counter = { ... }, 0

        str = string_gsub( str, "?", function()
            counter = counter + 1
            return escape( args[ counter ] )
        end )

        local result = rawQuery( str )
        if result == nil then return nil end

        for j = 1, #result, 1 do
            local row = result[ j ]
            for key, value in pairs( row ) do
                if value == "NULL" then
                    row[ key ] = nil
                end
            end
        end

        return result
    end

    sqlite.query = query

end

--- [SHARED AND MENU]
---
--- Executes a SQL query and returns a specific row.
---
---@param str string The SQL query to execute.
---@param row number? The row to return.
---@param ... string? The parameters to use in the query.
---@return table? result The selected row of the result.
local function queryRow( str, row, ... )
    local result = query( str, ... )
    if result == nil then
        return nil
    else
        return result[ row or 1 ]
    end
end

sqlite.queryRow = queryRow

--- [SHARED AND MENU]
---
--- Executes a SQL query and returns the first row.
---
---@param str string The SQL query to execute.
---@param ... string? The parameters to use in the query.
---@return table? result The first row of the result.
local function queryOne( str, ... )
    return queryRow( str, 1, ... )
end

sqlite.queryOne = queryOne

do

    local next = std.next

    --- [SHARED AND MENU]
    ---
    --- Executes a SQL query and returns the first value of the first row.
    ---
    ---@param str string The SQL query to execute.
    ---@param ... string? The parameters to use in the query.
    ---@return any value The first value of the first row of the result.
    function sqlite.queryValue( str, ... )
        local result = queryOne( str, ... )
        if result == nil then
            return nil
        else
            return next( result )
        end
    end

end

do

    local pcall = std.pcall

    --- [SHARED AND MENU]
    ---
    --- Executes a transaction of SQL queries in one block.
    ---
    ---@param fn function The function to execute all SQL queries in one transaction.
    ---@return any value The result of function execution.
    function sqlite.transaction( fn )
        rawQuery( "begin" )

        local ok, result = pcall( fn, query )
        if ok then
            rawQuery( "commit" )
            return result
        end

        rawQuery( "rollback" )
        return error( result, 2 )
    end

end
