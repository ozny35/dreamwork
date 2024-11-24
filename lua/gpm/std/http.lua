local _G = _G
local gpm = _G.gpm
local std, Logger = gpm.std, gpm.Logger
local CLIENT, SERVER, Future, tonumber = std.CLIENT, std.SERVER, std.Future, std.tonumber

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

local cache = {}

local json_serialize = std.crypto.json.serialize

local http_cache_get, http_cache_set
do
    local http_cache = gpm.http_cache
    http_cache_get, http_cache_set = http_cache.get, http_cache.set
end

local function isValidCache( data )
    return ( SysTime() - data.start ) < data.age
end

--- Executes an asynchronous http request with the given parameters.
---@param parameters HTTPRequest: The request parameters. See `HTTPRequest` structure.
---@return Future
local function request( parameters )
    local f = Future()

    local url = parameters.url
    if not is_string( url ) then
        f:setError( "url must be a string" )
        return f
    end

    if is_string( parameters.method ) then
        parameters.method = string_upper( parameters.method )
    else
        parameters.method = "GET"
    end

    if not is_number( parameters.timeout ) then
        parameters.timeout = gpm_http_timeout:GetInt()
    end

    Logger:Debug( "%s HTTP request to '%s', using '%s', with timeout %d seconds.", parameters.method or "GET", parameters.url or "", client_name, parameters.timeout )

    function parameters.success( code, body, headers )
        f:setResult( { code, body, headers } )
    end

    function parameters.failed( msg )
        f:setError( msg )
    end

    -- Cache
    if parameters.cache then
        local identifier = json_serialize( {
            url = parameters.url,
            method = parameters.method,
            parameters = parameters.parameters,
            headers = parameters.headers
        }, false )

        local data = cache[ identifier ]
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
        cache[ identifier ] = data

        local success = parameters.success

        function parameters.success( status, body, headers )
            local cache_control = headers["cache-control"]
            if cache_control then
                local options = {}
                for key, value in string_gmatch( cache_control, "([%w_-]+)=?([%w_-]*)" ) do
                    options[ key ] = tonumber( value, 10 ) or true
                end

                if options["no-cache"] or options["no-store"] then
                    cache[ identifier ] = nil
                elseif options["s-maxage"] or options["max-age"] then
                    data[ 3 ] = options["s-maxage"] or options["max-age"]
                end
            end

            success( status, body, headers )
        end

        local failed = parameters.failed

        function parameters.failed( msg )
            cache[ identifier ] = nil
            failed( msg )
        end
    end

    parameters.cache = nil

    -- ETag extension
    if parameters.etag then
        local data = http_cache_get( parameters.url )
        if data then
            if is_table( parameters.headers ) then
                parameters.headers[ "If-None-Match" ] = data.etag
            else
                parameters.headers = { [ "If-None-Match" ] = data.etag }
            end
        end

        local success = parameters.success

        function parameters.success( status, body, headers )
            if status == 304 then
                status, body = 200, data and data.content or ""
            elseif status == 200 and headers.etag then
                http_cache_set( parameters.url, headers.etag, body )
            end

            success( status, body, headers )
        end
    end

    parameters.etag = nil

    if not make_request( parameters ) then
        parameters.failed( "failed to connect to http client" )
    end

    return f
end

http.request = request

if std.MENU then

    local json_deserialize = std.crypto.json.deserialize
    local GetAPIManifest = _G.GetAPIManifest

    function http.getFacepunchManifest()
        local f = Future()

        GetAPIManifest( function( json )
            if is_string( json ) then
                local data = json_deserialize( json, false, false )
                if data ~= nil then
                    f:setResult( data )
                    return
                end
            end

            f:setError( "failed to get facepunch manifest" )
        end )

        return f
    end

end

return http
