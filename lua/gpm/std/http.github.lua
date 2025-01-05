
local _G = _G
local gpm = _G.gpm
local std = gpm.std
local error, tonumber, tostring, HTTPClientError = std.error, std.tonumber, std.tostring, std.HTTPClientError
local game_getSystemTime = std.game.getSystemTime
local futures_sleep = std.futures.sleep
local http_request = std.http.request
local os_time = std.os.time

local base64_decode, json_deserialize
do
    local crypto = std.crypto
    base64_decode = crypto.base64.decode
    json_deserialize = crypto.json.deserialize
end

local string_upper, string_gsub, string_isURL
do
    local string = std.string
    string_upper, string_gsub, string_isURL = string.upper, string.gsub, string.isURL
end

local api_token
if SERVER then
    local gpm_github_token = std.console.Variable( {
        name = "gpm.github.token",
        description = "https://github.com/settings/tokens",
        flags = std.bit.bor( 16, 32, 128 ),
        type = "string"
    } )

    gpm_github_token:addChangeCallback( "http.github", function( _, __, str ) api_token = str end )
    api_token = gpm_github_token:get()
else
    api_token = ""
end

--- Github API library
---@class gpm.std.http.github
local github = {}

-- https://docs.github.com/en/rest/overview/resources-in-the-rest-api#rate-limiting
local mutationNextTime = 0
local rateLimitReset = 0

---@async
local function request( method, url, headers, body, cache )
    if not string_isURL( url ) then
        url = "https://api.github.com" .. url
    end

    headers = headers or {}

    if headers["Authorization"] == nil and api_token ~= "" then
        headers["Authorization"] = "Bearer " .. api_token
    end

    if headers["Accept"] == nil then
        headers["Accept"] = "application/vnd.github+json"
    end

    if headers["X-GitHub-Api-Version"] == nil then
        headers["X-GitHub-Api-Version"] = "2022-11-28"
    end

    local currentTime = os_time()
    if rateLimitReset > currentTime then
        local diff = rateLimitReset - currentTime
        if diff < 30 then
            futures_sleep( diff )
        else
            error( HTTPClientError( "Github API rate limit exceeded (" .. tostring( url ) .. ")" ) )
        end
    end

    method = string_upper( method )

    -- Rate limit mutative requests
    if method == "POST" or method == "PATCH" or method == "PUT" or method == "DELETE" then
        local diff = mutationNextTime - game_getSystemTime()
        if diff > 0 then
            mutationNextTime = mutationNextTime + 1000
            futures_sleep( diff )
        else
            mutationNextTime = game_getSystemTime() + 1000
        end
    end

    -- i believe there is no reason to implement queue, since requests are queued by the engine
    ---@diagnostic disable-next-line: missing-fields
    local result = http_request( {
        url = url,
        method = method,
        headers = headers,
        body = body,
        etag = cache ~= false,
        cache = cache ~= false
    } )

    if ( result.status == 429 or result.status == 403 ) and headers["x-ratelimit-remaining"] == "0" then
        local reset = tonumber( headers["x-ratelimit-reset"], 10 )
        if reset then
            rateLimitReset = reset
        end

        error( HTTPClientError( "Github API rate limit exceeded (" .. tostring( result.status ) .. ") (" .. tostring( url ) .. ")" ) )
    end

    return result
end

github.request = request

---@async
local function apiRequest( method, pathname, headers, body, cache )
    local result = request( method, pathname, headers, body, cache )
    if not ( result.status >= 200 and result.status < 300 ) then
        error( HTTPClientError( "Failed to fetch data from Github API (" .. tostring( result.status ) .. ") (" .. tostring( pathname ) .. ")" ) )
    end

    local data = json_deserialize( result.body, true, true )
    if not data then
        error( HTTPClientError( "Failed to parse JSON response from Github API (" .. tostring( result.status ) .. ") (" .. tostring( pathname ) .. ")" ) )
    end

    return data
end

github.apiRequest = apiRequest

--- TODO
---@param pathname any
---@param data any
---@return unknown
local function template( pathname, data )
    return string_gsub( pathname, "{([%w_-]-)}", function( str )
        return tostring( data[ str ] )
        ---@diagnostic disable-next-line: redundant-return-value
    end ), nil
end

github.template = template

---@async
local function templateRequest( method, pathname, data )
    return apiRequest( method, template( pathname, data ) )
end

github.templateRequest = templateRequest

---@async
local function getRepository( owner, repo )
    return templateRequest( "GET", "/repos/{owner}/{repo}", {
        owner = owner,
        repo = repo
    } )
end

github.getRepository = getRepository

---@async
local function getRepositoryTags( owner, repo )
    -- TODO: implement pagination?
    return templateRequest( "GET", "/repos/{owner}/{repo}/tags?per_page=100", {
        owner = owner,
        repo = repo
    } )
end

github.getRepositoryTags = getRepositoryTags

---@async
local function getTree( owner, repo, tree_sha, recursive )
    return templateRequest( "GET", "/repos/{owner}/{repo}/git/trees/{tree_sha}?recursive={recursive}", {
        owner = owner,
        repo = repo,
        tree_sha = tree_sha,
        recursive = recursive == true
    } )
end

github.getTree = getTree

---@async
local function getBlob( owner, repo, file_sha )
    local result = templateRequest( "GET", "/repos/{owner}/{repo}/git/blobs/{file_sha}", {
        owner = owner,
        repo = repo,
        file_sha = file_sha
    } )

    if result.encoding == "base64" then
        result.content = base64_decode( result.content )
        result.encoding = "raw"
    end

    return result
end

github.getBlob = getBlob

---@async
local function fetchZip( owner, repo, ref )
    local result = request( "GET", "/repos/" .. tostring( owner ) .. "/" .. tostring( repo ) .. "/zipball/" .. tostring( ref ) )
    if result.status ~= 200 then
        error( HTTPClientError( "Failed to fetch zipball (" .. tostring( owner ) .. "/" .. tostring( repo ) .. "/" .. tostring( ref ) .. ") from Github API (" .. tostring( result.status ) .. ")" ) )
    end

    return result.body
end

github.fetchZip = fetchZip

return github
