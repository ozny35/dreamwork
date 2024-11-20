local _G = _G
local gpm = _G.gpm
local std, Logger = gpm.std, gpm.Logger
local CLIENT, SERVER, Future = std.CLIENT, std.SERVER, std.Future
local is_number = std.is.number

---@class gpm.std.http
local http = {}

local http_client, client_name
if SERVER and std.loadbinary( "reqwest" ) then
    local user_agent = "gLua Package Manager/" .. gpm.VERSION .. " - Garry's Mod/" .. _G.VERSIONSTR
    ---@diagnostic disable-next-line: undefined-field
    local reqwest = _G.reqwest

    function http_client( parameters )
        parameters["User-Agent"] = user_agent
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

---
---@param parameters HTTPRequest
---@return Future
local function request( parameters )
    local f = Future()

    if not is_number( parameters.timeout ) then
        parameters.timeout = std.console.variable.getFloat( "gpm_http_timeout" )
    end

    Logger:Debug( "%s HTTP request to '%s', using '%s', with timeout %d seconds.", parameters.method or "GET", parameters.url or "", client_name, parameters.timeout )

    function parameters.success( code, body, headers )
        f:setResult( { code, body, headers } )
    end

    function parameters.failed( msg )
        f:setError( msg )
    end

    if http_client( parameters ) then
        return f
    end

    parameters.failed( "failed to connect to http client" )
    return f
end

http.request = request

return http
