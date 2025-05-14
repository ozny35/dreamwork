local _G = _G

local gpm = _G.gpm
local Logger = gpm.Logger

---@class gpm.std
local std = gpm.std

local tonumber = std.tonumber
local Timer_wait = std.Timer.wait
local string_gmatch = std.string.gmatch
local isnumber, isstring, istable = std.isnumber, std.isstring, std.istable

local futures_Future = std.futures.Future

local http_client, client_name
if std.loadbinary( "reqwest" ) then
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
elseif std.SHARED and std.loadbinary( "chttp" ) then
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

if http_client == nil then
    Logger:error( "HTTP client '%s' loading failed, sending requests is not possible.", client_name )
else
    Logger:info( "'%s' was connected as HTTP client.", client_name )
end


local make_request
do

    local queue, length = {}, 0

    function make_request( parameters )
        length = length + 1
        queue[ length ] = { parameters }
    end

    Timer_wait( function()
        make_request = http_client

        for i = 1, length, 1 do
            ---@diagnostic disable-next-line: need-check-nil
            http_client( queue[ i ] )
        end

        ---@diagnostic disable-next-line: cast-local-type
        queue, length = nil, nil
    end )

end

--- [SHARED AND MENU]
---
--- http library
---@class gpm.std.http
local http = std.http or {}
std.http = http

local gpm_http_timeout, gpm_http_lifetime
do

    local cvar_options = {
        name = "gpm.http.timeout",
        description = "Default timeout for http requests.",
        replicated = not std.MENU,
        type = "number",
        archive = true,
        default = 10,
        min = 0,
        max = 300
    }

    gpm_http_timeout = std.console.Variable( cvar_options )

    cvar_options.name = "gpm.http.lifetime"
    cvar_options.description = "Cache lifetime for gpm http library in minutes."
    cvar_options.default = 1
    cvar_options.max = 40320

    gpm_http_lifetime = std.console.Variable( cvar_options )

end

local http_cache_get, http_cache_set = gpm.http_cache.get, gpm.http_cache.set
local json_serialize = std.crypto.json.serialize
local game_getUptime = std.game.getUptime

local session_cache = {}

--[[

    todo

        http method as string luals
        http success and failure as one

        add private request structures
        add private response structures

]]

--- [SHARED AND MENU]
---
--- Executes an asynchronous http request with the given options.
---
---@param options gpm.std.http.Request The request options.
---@return gpm.std.http.Response data The response.
---@see gpm.std.http.Request for the request options structure.
---@see gpm.std.http.Response for the response structure.
---@async
local function request( options )
    local search_parameters = options.parameters
    if std.isURLSearchParams( search_parameters ) then
        ---@cast search_parameters gpm.std.URL.SearchParams

        local parameters = {}

        for key, value in search_parameters:iterator() do
            local old_value = parameters[ key ]
            if old_value == nil then
                parameters[ key ] = value
            elseif istable( old_value ) then
                old_value[ #old_value + 1 ] = value
            else
                parameters[ key ] = { old_value, value }
            end
        end

        options.parameters = parameters
    elseif not istable( search_parameters ) then
        options.parameters = nil
    end

    local url = options.url
    if url == nil then
        error( "URL is nil", 2 )
    elseif not isstring( url ) then
        ---@cast url gpm.std.URL
        url = url.href
        options.url = url
    end

    ---@cast url string

    local method = options.method or "GET"
    options.method = method

    local timeout = options.timeout
    if timeout == nil or not isnumber( timeout ) then
        ---@diagnostic disable-next-line: cast-local-type
        timeout = gpm_http_timeout:get()
        ---@cast timeout number
    end

    options.timeout = timeout

    -- TODO: add package logger searching
    Logger:debug( "%s HTTP request to '%s', using '%s', with timeout %f seconds.", method, url, client_name, timeout )

    local f = futures_Future()

    ---@diagnostic disable-next-line: inject-field
    function options.success( status, body, headers )
        f:setResult( { status = status, body = body, headers = headers } )
    end

    ---@diagnostic disable-next-line: inject-field
    function options.failed( msg )
        f:setError( msg )
    end

    -- Cache extension
    if options.cache then
        options.cache = nil

        local identifier = json_serialize( {
            url = url,
            method = method,
            parameters = options.parameters,
            headers = options.headers
        }, false )

        local data = session_cache[ identifier ]
        if data ~= nil and ( game_getUptime() - data.start ) < data.age then
            return data[ 1 ]
        end

        local lifetime = options.lifetime
        options.lifetime = nil

        if not isnumber( lifetime ) then
            lifetime = gpm_http_lifetime:get() * 60
        end

        -- future, start, age
        data = { f, SysTime(), lifetime }
        session_cache[ identifier ] = data

        local success = options.success

        ---@diagnostic disable-next-line: inject-field
        function options.success( status, body, headers )
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

        local failed = options.failed

        ---@diagnostic disable-next-line: inject-field
        function options.failed( msg )
            session_cache[ identifier ] = nil
            failed( msg )
        end
    end

    -- ETag extension
    if options.etag then
        options.etag = nil

        local data = http_cache_get( url )
        if data then
            local headers = options.headers
            if istable( headers ) then
                headers[ "If-None-Match" ] = data.etag
            else
                headers = { [ "If-None-Match" ] = data.etag }
                options.headers = headers
            end
        end

        local success = options.success

        ---@diagnostic disable-next-line: inject-field
        function options.success( status, body, headers )
            if status == 304 then
                status, body = 200, data and data.content or ""
            elseif status == 200 and headers.etag then
                http_cache_set( url, headers.etag, body )
            end

            success( status, body, headers )
        end
    end

    if not make_request( options ) then
        options.failed( "failed to connect to '" .. client_name .. "' http client for '" .. url .. "'" )
    end

    return f:await()
end

http.request = request

if std.MENU then

    local json_deserialize = std.crypto.json.deserialize
    local GetAPIManifest = _G.GetAPIManifest

    --- [MENU]
    ---
    --- Gets miscellaneous information from Facepunches API.
    ---@param timeout number? The timeout in seconds.
    ---@return table data The data returned from the API.
    ---@async
    function http.getFacepunchManifest( timeout )
        local f = futures_Future()

        GetAPIManifest( function( json )
            if isstring( json ) then
                local data = json_deserialize( json )
                if data ~= nil then
                    f:setResult( data )
                    return
                end
            end

            f:setError( "failed to get facepunch manifest" )
        end )

        Timer_wait( function()
            if f:isPending() then
                f:setError( "timed out getting facepunch manifest" )
            end
        end, timeout or 30 )

        return f:await()
    end

end
