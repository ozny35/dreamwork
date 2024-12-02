local _G = _G
local gpm = _G.gpm
local std, Logger = gpm.std, gpm.Logger
local CLIENT, SERVER, Future, tonumber, HTTPClientError = std.CLIENT, std.SERVER, std.Future, std.tonumber, std.HTTPClientError

local string_gmatch, string_upper
do
    local string = std.string
    string_gmatch, string_upper = string.gmatch, string.upper
end

local is_number, is_string, is_table
do
    local is = std.is
    is_number, is_string, is_table = is.number, is.string, is.table
end

local http_client, client_name
if SERVER and std.loadbinary( "reqwest" ) then
    local user_agent = "gLua Package Manager/" .. gpm.VERSION .. " - Garry's Mod/" .. _G.VERSIONSTR
    ---@diagnostic disable-next-line: undefined-field
    local reqwest = _G.reqwest

    local default_headers = {
        ["User-Agent"] = user_agent
    }

    function http_client( parameters )
        if parameters.headers == nil then
            parameters.headers = default_headers
        else
            parameters.headers["User-Agent"] = user_agent
        end

        reqwest( parameters )
        return true
    end

    client_name = "reqwest"
elseif ( CLIENT or SERVER ) and std.loadbinary( "chttp" ) then
    ---@diagnostic disable-next-line: undefined-field
    local CHTTP = _G.CHTTP

    function http_client( parameters )
        CHTTP( parameters )
        return true
    end

    client_name = "chttp"
else
    http_client = _G.HTTP
    client_name = "Garry's Mod"
end

Logger:Info( "'%s' was connected as HTTP client.", client_name )

local make_request
do

    local queue, length = {}, 0

    function make_request( parameters )
        length = length + 1
        queue[ length ] = { parameters }
    end

    _G.timer.Simple( 0, function()
        make_request = http_client

        for i = 1, length do
            http_client( queue[ i ] )
        end

        ---@diagnostic disable-next-line: cast-local-type
        queue, length = nil, nil
    end )

end

---@class gpm.std.http
local http = {}

local gpm_http_timeout, gpm_http_lifetime
do

    local flags = std.MENU and std.FCVAR.ARCHIVE or std.bit.bor( std.FCVAR.ARCHIVE, std.FCVAR.REPLICATED )
    local variable_create = std.console.variable.create

    gpm_http_timeout = variable_create( "gpm_http_lifetime", "10", flags, "Default http timeout for gpm http library.", 0, 300 )
    gpm_http_lifetime = variable_create( "gpm_http_lifetime", "1", flags, "Cache lifetime for gpm http library in minutes.", 0, 40320 )

end

local json_serialize = std.crypto.json.serialize

local http_cache_get, http_cache_set
do
    local http_cache = gpm.http_cache
    http_cache_get, http_cache_set = http_cache.get, http_cache.set
end

local session_cache = {}

local function isValidCache( data )
    return ( SysTime() - data.start ) < data.age
end

--- Executes an asynchronous http request with the given parameters.
---@param parameters HTTPRequest: The request parameters. See `HTTPRequest` structure.
---@return HTTPResponse
---@async
local function request( parameters )
    local f = Future()

    local url = parameters.url
    if not is_string( url ) then
        f:setError( HTTPClientError( "url must be a string" ) )
        return f:await()
    end

    local method = parameters.method
    if is_string( method ) then
        method = string_upper( method )
    else
        method = "GET"
    end

    parameters.method = method

    local timeout = parameters.timeout
    if not is_number( timeout ) then
        timeout = gpm_http_timeout:GetInt()
        parameters.timeout = timeout
    end

    Logger:Debug( "%s HTTP request to '%s', using '%s', with timeout %d seconds.", method, url, client_name, timeout )

    function parameters.success( status, body, headers )
        f:setResult( { status = status, body = body, headers = headers } )
    end

    function parameters.failed( msg )
        f:setError( HTTPClientError( msg ) )
    end

    -- Cache
    if parameters.cache then
        parameters.cache = nil

        local identifier = json_serialize( {
            url = url,
            method = method,
            parameters = parameters.parameters,
            headers = parameters.headers
        }, false )

        local data = session_cache[ identifier ]
        if data and isValidCache( data ) then
            return data[ 1 ]
        end

        local lifetime = parameters.lifetime
        parameters.lifetime = nil

        if not is_number( lifetime ) then
            lifetime = gpm_http_lifetime:GetInt() * 60
        end

        -- future, start, age
        data = { f, SysTime(), lifetime }
        session_cache[ identifier ] = data

        local success = parameters.success

        function parameters.success( status, body, headers )
            local cache_control = headers["cache-control"]
            if cache_control then
                local options = {}
                for key, value in string_gmatch( cache_control, "([%w_-]+)=?([%w_-]*)" ) do
                    options[ key ] = tonumber( value, 10 ) or true
                end

                if options["no-cache"] or options["no-store"] then
                    session_cache[ identifier ] = nil
                elseif options["s-maxage"] or options["max-age"] then
                    data[ 3 ] = options["s-maxage"] or options["max-age"]
                end
            end

            success( status, body, headers )
        end

        local failed = parameters.failed

        function parameters.failed( msg )
            session_cache[ identifier ] = nil
            failed( msg )
        end
    end

    -- ETag extension
    if parameters.etag then
        parameters.etag = nil

        local data = http_cache_get( url )
        if data then
            local headers = parameters.headers
            if is_table( headers ) then
                headers[ "If-None-Match" ] = data.etag
            else
                headers = { [ "If-None-Match" ] = data.etag }
                parameters.headers = headers
            end
        end

        local success = parameters.success

        function parameters.success( status, body, headers )
            if status == 304 then
                status, body = 200, data and data.content or ""
            elseif status == 200 and headers.etag then
                http_cache_set( url, headers.etag, body )
            end

            success( status, body, headers )
        end
    end

    if not make_request( parameters ) then
        parameters.failed( "failed to connect to http client" )
    end

    return f:await()
end

http.request = request

if std.MENU then

    local json_deserialize = std.crypto.json.deserialize
    local GetAPIManifest = _G.GetAPIManifest
    local timer_Simple = _G.timer.Simple

    --- Gets miscellaneous information from Facepunches API.
    ---@return table data: The data returned from the API.
    ---@async
    function http.getFacepunchManifest()
        local f, finished = Future(), false

        GetAPIManifest( function( json )
            finished = true

            if is_string( json ) then
                local data = json_deserialize( json, false, false )
                if data ~= nil then
                    f:setResult( data )
                    return
                end
            end

            f:setError( HTTPClientError( "failed to get facepunch manifest" ) )
        end )

        timer_Simple( 30, function()
            if finished then return end
            f:setError( HTTPClientError( "timed out getting facepunch manifest" ) )
        end )

        return f:await()
    end

end

---@class gpm.std.http.github
http.github = include( "http.github.lua" )

---@class gpm.std.http.steam
http.steam = include( "http.steam.lua" )

return http
