
local _G = _G
local gpm = _G.gpm

local std = gpm.std

local tonumber, tostring = std.tonumber, std.tostring
local HTTPClientError = std.HTTPClientError

local game_getSystemTime = std.game.getSystemTime

---@class gpm.std.http
local http = std.http

local http_request = http.request
local futures_sleep = std.sleep
local os_time = std.os.time

local base64_decode, json_deserialize
do
    local crypto = std.crypto
    base64_decode = crypto.base64.decode
    json_deserialize = crypto.json.deserialize
end

local string_gsub = std.string.gsub

local api_token
if std.SERVER then
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

--- [SHARED AND MENU]
---
--- The Github API library.
---
---@class gpm.std.http.github
local github = http.github or {}
http.github = github

-- https://docs.github.com/en/rest/overview/resources-in-the-rest-api#rate-limiting
local next_mutation_time = 0
local ratelimit_reset_time = 0

--- [SHARED AND MENU]
---
--- Sends a request to the Github API.
---
---@param method gpm.std.http.Request.Method The request method.
---@param pathname string The path to send the request to.
---@param headers? table The headers to send with the request.
---@param body? string The body to send with the request.
---@param do_cache? boolean Whether to cache the response.
---@return gpm.std.http.Response response The response.
---@async
local function request( method, pathname, headers, body, do_cache )
    local url = std.URL( pathname, "https://api.github.com" )

    if headers == nil then
        headers = {
            ["Authorization"] = "Bearer " .. api_token,
            ["Accept"] = "application/vnd.github+json",
            ["X-GitHub-Api-Version"] = "2022-11-28"
        }
    else

        if headers["Authorization"] == nil and api_token ~= "" then
            headers["Authorization"] = "Bearer " .. api_token
        end

        if headers["Accept"] == nil then
            headers["Accept"] = "application/vnd.github+json"
        end

        if headers["X-GitHub-Api-Version"] == nil then
            headers["X-GitHub-Api-Version"] = "2022-11-28"
        end

    end

    local current_time = os_time()
    if ratelimit_reset_time > current_time then
        local diff = ratelimit_reset_time - current_time
        if diff < 30 then
            futures_sleep( diff )
        else
            std.error( HTTPClientError( "Github API rate limit exceeded (" .. url.href .. ")" ) )
        end
    end

    -- Rate limit mutative requests
    if method > 1 and method < 6 then
        local diff = next_mutation_time - game_getSystemTime()
        if diff > 0 then
            next_mutation_time = next_mutation_time + 1000
            futures_sleep( diff )
        else
            next_mutation_time = game_getSystemTime() + 1000
        end
    end

    -- i believe there is no reason to implement queue, since requests are queued by the engine
    ---@diagnostic disable-next-line: missing-fields
    local result = http_request( {
        url = url,
        method = method,
        headers = headers,
        body = body,
        etag = do_cache ~= false,
        cache = do_cache ~= false
    } )

    if ( result.status == 429 or result.status == 403 ) and headers["x-ratelimit-remaining"] == "0" then
        local ratelimit_reset = tonumber( headers["x-ratelimit-reset"], 10 )
        if ratelimit_reset == nil then
            std.error( HTTPClientError( "Github API rate limit exceeded (" .. tostring( result.status ) .. ") (" .. tostring( url ) .. ")" ) )
        else
            ratelimit_reset_time = ratelimit_reset
        end
    end

    return result
end

github.request = request

--- [SHARED AND MENU]
---
--- Makes a request to the Github API.
---
---@param method gpm.std.http.Request.Method The request method.
---@param pathname string The path to send the request to.
---@param headers? table The headers to send with the request.
---@param body? string The body to send with the request.
---@param do_cache? boolean Whether to cache the response.
---@return table data The data returned from the API.
---@async
local function apiRequest( method, pathname, headers, body, do_cache )
    local result = request( method, pathname, headers, body, do_cache )
    if not ( result.status >= 200 and result.status < 300 ) then
        std.error( HTTPClientError( "Failed to fetch data from Github API (" .. tostring( result.status ) .. ") (" .. tostring( pathname ) .. ")" ) )
    end

    local data = json_deserialize( result.body, true, true )
    if data == nil then
        std.error( HTTPClientError( "Failed to parse JSON response from Github API (" .. tostring( result.status ) .. ") (" .. tostring( pathname ) .. ")" ) )
    end

    ---@cast data table

    return data
end

github.apiRequest = apiRequest

--- [SHARED AND MENU]
---
--- Replaces all occurrences of `{name}` in `pathname` with `tbl[name]`.
---
---@param pathname string The path to replace placeholders in.
---@param replaces table<string, any> The table to replace placeholders with.
---@return string pathname The path with placeholders replaced.
local function template( pathname, replaces )
    return string_gsub( pathname, "{([%w_-]-)}", function( str )
        return tostring( replaces[ str ] )
        ---@diagnostic disable-next-line: redundant-return-value
    end ), nil
end

github.template = template

--- [SHARED AND MENU]
---
--- Replaces all occurrences of `{name}` in `pathname` with `tbl[name]` and makes a request to the Github API.
---
---@param method gpm.std.http.Request.Method The request method.
---@param pathname string The path to send the request to.
---@param replaces table<string, any> The table to replace placeholders with.
---@return table data The data returned from the API.
---@async
local function templateRequest( method, pathname, replaces )
    return apiRequest( method, template( pathname, replaces ) )
end

github.templateRequest = templateRequest

--- [SHARED AND MENU]
---
--- Fetches a list of all github emojis.
---
---@return table<string, string> data The list of emojis.
---@async
function github.getEmojis()
    return apiRequest( 1, "/emojis" )
end

--- [SHARED AND MENU]
---
--- Fetches a list of all github licenses.
---
---@return gpm.std.http.github.License[]
---@async
function github.getLicenses()
    return apiRequest( 1, "/licenses" )
end

--- [SHARED AND MENU]
---
--- Fetches a list of all repositories owned by an organization.
---
---@param organization string The name of the organization.
---@return gpm.std.http.github.Repository[] repos The list of repositories.
---@async
function github.getRepositories( organization )
    return templateRequest( 1, "/orgs/{org}/repos", {
        org = organization
    } )
end

--- [SHARED AND MENU]
---
--- Fetches a detailed information about a specific repository.
---
---@param owner string The owner of the repository.
---@param repo string The name of the repository.
---@return gpm.std.http.github.Repository repo The repository.
---@async
function github.getRepository( owner, repo )
    return templateRequest( 1, "/repos/{owner}/{repo}", {
        owner = owner,
        repo = repo
    } )
end

--- [SHARED AND MENU]
---
--- Fetches a lists the tags (versions) of a repository.
---
---@param owner string The owner of the repository.
---@param repo string The name of the repository.
---@param page? integer The page number, default value is `1`.
---@return gpm.std.http.github.Repository.Tag[] tags The list of tags.
---@async
function github.getRepositoryTags( owner, repo, page )
    return templateRequest( 1, "/repos/{owner}/{repo}/tags?per_page=100&page={page}", {
        owner = owner,
        repo = repo,
        page = page or 1
    } )
end

--- [SHARED AND MENU]
---
--- Fetches a single Git tree — that is, a snapshot of the repository's file structure at a specific commit or tree.
---
---@param owner string The account owner of the repository. The name is not case sensitive.
---@param repo string The name of the repository without the .git extension. The name is not case sensitive.
---@param tree_sha string The SHA1 value or ref (branch or tag) name of the tree.
---@param recursive? boolean Setting this parameter to any value returns the objects or subtrees referenced by the tree specified in :tree_sha.
---@return gpm.std.http.github.Tree tree The tree.
---@async
function github.getTree( owner, repo, tree_sha, recursive )
    return templateRequest( 1, "/repos/{owner}/{repo}/git/trees/{tree_sha}?recursive={recursive}", {
        owner = owner,
        repo = repo,
        tree_sha = tree_sha,
        recursive = recursive == true
    } )
end

--- [SHARED AND MENU]
---
--- Fetches the content of a blob (a blob = file contents) in a repository, using its SHA-1.
---
---@param owner string The owner of the repository.
---@param repo string The name of the repository.
---@param file_sha string The SHA1 value of the blob.
---@return gpm.std.http.github.Blob blob The blob.
---@async
function github.getBlob( owner, repo, file_sha )
    local result = templateRequest( 1, "/repos/{owner}/{repo}/git/blobs/{file_sha}", {
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

--- [SHARED AND MENU]
---
--- Fetches a list of repository contributors.
---
---@param owner string The owner of the repository.
---@param repo string The name of the repository.
---@return gpm.std.http.github.Contributor[] contributors The list of contributors.
---@async
function github.getContributors( owner, repo )
    return templateRequest( 1, "/repos/{owner}/{repo}/contributors", {
        owner = owner,
        repo = repo
    } )
end

--- [SHARED AND MENU]
---
--- Fetches a list of repository languages.
---
---@param owner string The owner of the repository.
---@param repo string The name of the repository.
---@return table<string, integer> languages The languages.
---@async
function github.getLanguages( owner, repo )
    return templateRequest( 1, "/repos/{owner}/{repo}/languages", {
        owner = owner,
        repo = repo
    } )
end

--- [SHARED AND MENU]
---
--- Fetches the repository contents as a ZIP archive based on a specific reference (branch name, tag name, or commit sha-1).
---
---@param owner string The owner of the repository.
---@param repo string The name of the repository.
---@param ref string The branch name, tag name, or commit sha-1.
---@return string content The body of the zipball.
---@async
function github.fetchZip( owner, repo, ref )
    local result = templateRequest( 1, "/repos/{owner}/{repo}/zipball/{ref}", {
        owner = owner,
        repo = repo,
        ref = ref
    } )

    if result.status ~= 200 then
        std.error( HTTPClientError( "Failed to fetch zipball (" .. tostring( owner ) .. "/" .. tostring( repo ) .. "/" .. tostring( ref ) .. ") from Github API (" .. tostring( result.status ) .. ")" ) )
    end

    return result.body
end
