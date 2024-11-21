local _G = _G
local gpm = _G.gpm
local std, Logger = gpm.std, gpm.Logger
local CLIENT, SERVER, Future = std.CLIENT, std.SERVER, std.Future
local is_number = std.is.number

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
    gpm_http_lifetime = variable_create( "gpm_http_lifetime", "30", flags, "Cache lifetime for gpm http library in minutes.", 0, 40320 )

end

--- Executes an asynchronous http request with the given parameters.
---@param parameters HTTPRequest: The request parameters. See `HTTPRequest` structure.
---@return Future
local function request( parameters )
    local f = Future()

    if not is_number( parameters.timeout ) then
        parameters.timeout = gpm_http_timeout:GetInt()
    end

    if not is_number( parameters.lifetime ) then
        parameters.lifetime = gpm_http_lifetime:GetInt() * 60
    end

    Logger:Debug( "%s HTTP request to '%s', using '%s', with timeout %d seconds.", parameters.method or "GET", parameters.url or "", client_name, parameters.timeout )

    function parameters.success( code, body, headers )
        f:setResult( { code, body, headers } )
    end

    function parameters.failed( msg )
        f:setError( msg )
    end


    if make_request( parameters ) then
        return f
    end

    parameters.failed( "failed to connect to http client" )
    return f
end

http.request = request

return http
