---@meta

---@class gpm.std
std = {}

--- Table used by `http.request` function.
---@class HTTPRequest
local HTTPRequest = {}

--- Request method, case insensitive. Possible values are:
--- * GET
--- * POST
--- * HEAD
--- * PUT
--- * DELETE
--- * PATCH
--- * OPTIONS
---@type string?
HTTPRequest.method = nil

--- The target url
---@type string
HTTPRequest.url = nil

--- KeyValue table for parameters. This is only applicable to the following request methods:
--- * GET
--- * POST
--- * HEAD
---@type table?
HTTPRequest.parameters = nil

--- KeyValue table for headers
---@type table?
HTTPRequest.headers = nil

--- Body string for POST data. If set, will override parameters
---@type string?
HTTPRequest.body = nil

--- Content type for body.
---@type string?
HTTPRequest.type = "text/plain; charset=utf-8"

--- The timeout for the connection.
---@type number?
HTTPRequest.timeout = 60

--- Whether to cache the response.
---@type boolean?
HTTPRequest.cache = false

--- The cache lifetime for the request.
---@type number?
HTTPRequest.lifetime = nil

--- Whether to use ETag caching.
---@type boolean?
HTTPRequest.etag = false

--- The success callback.
---@class HTTPResponse
local HTTPResponse = {}

--- The response status code.
---@type number
HTTPResponse.status = nil

--- The response body.
---@type string
HTTPResponse.body = nil

--- The response headers.
---@type table
HTTPResponse.headers = nil

--- The server information table.
---@class ServerInfo
local ServerInfo = {}

--- The server ping.
---@type number
ServerInfo.ping = 0

--- The server name.
---
--- This value is set on the server by the []() convar.
---@type string
ServerInfo.name = "Garry's Mod"

--- The server map.
---@type string
ServerInfo.map_name = "gm_construct"

--- Contains the version number of GMod.
---@type number
ServerInfo.version = 201211

--- The server address.
---@type string
ServerInfo.address = "127.0.0.1:27015"

--- Two digit country code in the [ISO 3166-1 alpha-2](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2) standard.
---
--- This value is set on the server by the [sv_location](https://wiki.facepunch.com/gmod/Downloading_a_Dedicated_Server#locationflag) convar.
---@type string?
ServerInfo.country = nil

--- Time when you last played on this server, as UNIX timestamp or 0.
---@type number
ServerInfo.last_played_time = 0

--- Whether this server has password or not.
---@type boolean
ServerInfo.has_password = false

--- Is the server signed into an anonymous account?
---@type boolean
ServerInfo.is_anonymous = false

--- The number of players on the server.
---@type number
ServerInfo.player_count = 0

--- The maximum number of players on the server.
---@type number
ServerInfo.player_limit = 0

--- The number of bots on the server.
---@type number
ServerInfo.bot_count = 0

--- The number of humans on the server.
---@type number
ServerInfo.human_count = 0

--- The [gamemode folder](https://wiki.facepunch.com/gmod/Gamemode_Creation#gamemodefolder) name and the [`GM.Folder`](https://wiki.facepunch.com/gmod/Gamemode_Creation#gamemodefoldername) value.
---@type string
ServerInfo.gamemode_name = "sandbox"

--- The [`GM.Name`](https://wiki.facepunch.com/gmod/Gamemode_Creation#sharedlua) value.
---@type string
ServerInfo.gamemode_title = "Sandbox"

--- ID of the gamemode in Steam Workshop.
---@type string?
ServerInfo.gamemode_wsid = nil

--- The [category](https://wiki.facepunch.com/gmod/Gamemode_Creation#gamemodetextfile) of the gamemode, ex. `pvp`, `pve`, `rp` or `roleplay`.
---@type string
ServerInfo.gamemode_category = "other"

--- Used for [serverlist.Query](https://wiki.facepunch.com/gmod/serverlist.Query).
---@class ServerQueryData
local ServerQueryData = {}

--- The game directory to get the servers for
---@type string
ServerQueryData.directory = "garrysmod"

--- Type of servers to retrieve. Valid values are `internet`, `favorite`, `history` and `lan`
---@type string
ServerQueryData.type = nil

--- Steam application ID to get the servers for
---@type number
ServerQueryData.appid = 4000

--- Called when a new server is found and queried.
---
--- Function argument(s):
--- * number `ping` - Latency to the server.
--- * string `name` - Name of the server
--- * string `gamemode_title` - "Nice" gamemode name
--- * string `map_name` - Current map
--- * number `player_count` - Total player number ( bot + human )
--- * number `player_limit` - Maximum reported amount of players
--- * number `bot_count` - Amount of bots on the server
--- * boolean `has_password` - Whether this server has password or not
--- * number `last_played_time` - Time when you last played on this server, as UNIX timestamp or 0
--- * string `address` - IP Address of the server
--- * string `gamemode_name` - Gamemode folder name
--- * number `gamemode_wsid` - Gamemode Steam Workshop ID
--- * boolean `is_anonymous` - Is the server signed into an anonymous account?
--- * string `version` - Version number, same format as jit.version_num
--- * string `country` - Two digit country code, `us` if nil
--- * string `gamemode_category` - Category of the gamemode, ex. `pvp`, `pve`, `rp` or `roleplay`
---
--- Function return value(s):
--- * boolean `stop` - Return `false` to stop the query.
---@type fun(ping: number, name: string, gamemode_title: string, map_name: string, player_count: number, player_limit: number, bot_count: number, has_password: boolean, last_played_time: number, address: string, gamemode_name: string, gamemode_wsid: number, is_anonymous: boolean, version: string, country: string, gamemode_category: string): boolean
ServerQueryData.server_queried = nil

--- Called if the query has failed, called with the servers IP Address
---@type function
ServerQueryData.query_failed = nil

--- Called when the query is finished. No arguments
---@type function
ServerQueryData.finished = nil

--- Table used by `console.Variable` class constructor.
---@class gpm.std.console.Variable.Data
local ConsoleVariableData = {}

--- The name of the console variable.
---@type string
ConsoleVariableData.name = nil

--- The type of the console variable.
---@type gpm.std.console.Variable.Type?
ConsoleVariableData.type = nil

--- The flags of the console variable.
---@type gpm.std.FCVAR?
ConsoleVariableData.flags = nil

--- The default value of the console variable.
---@type string | number | boolean | nil
ConsoleVariableData.default = nil

--- The description of the console variable.
---@type string?
ConsoleVariableData.description = nil

--- The minimal value of the console variable.
---@type number?
ConsoleVariableData.min = nil

--- The maximum value of the console variable.
---@type number?
ConsoleVariableData.max = nil

--- The result table of executing `file.path.parse`.
---@class ParsedFilePath
local ParsedFilePath = {}

--- The root of the file path.
---@type string
ParsedFilePath.root = ""

--- The directory of the file path.
---@type string
ParsedFilePath.dir = ""

--- The basename of the file path.
---@type string
ParsedFilePath.base = ""

--- The name of the file path.
---@type string
ParsedFilePath.name = ""

--- The extension of the file path.
---@type string
ParsedFilePath.ext = ""

--- Whether the file path is absolute.
---@type boolean
ParsedFilePath.abs = false

--- The params table that was used in `Addon` search functions.
---@class WorkshopSearchParams
local WorkshopSearchParams = {}

--- The type of items to retrieve.
---@type gpm.std.WORKSHOP_SEARCH?
WorkshopSearchParams.type = nil

--- A table of tags to match.
---@type string[]?
WorkshopSearchParams.tags = nil

--- How much of results to skip from first one.
---@type number?
WorkshopSearchParams.offset = 0

--- How many items to retrieve, up to 50 at a time.
---@type number?
WorkshopSearchParams.count = 50

--- This determines a time period, in range of days from 0 to 365.
---@type number?
WorkshopSearchParams.days = 365

--- If specified, receives items from the workshop created by the owner of SteamID64.
---@type string?
WorkshopSearchParams.steamid64 = "0"

--- If specified, retrieves items from your workshop, and also eliminates the 'steamid64' key.
---@type boolean?
WorkshopSearchParams.owned = false

--- Response time, after which the function will be terminated with an error (default 30)
---@type number?
WorkshopSearchParams.timeout = 30

---@alias URLState gpm.std.URLState
---@class gpm.std.URLState
---@field scheme string?
---@field username string?
---@field password string?
---@field hostname string | table | number | nil
---@field port number?
---@field path string | table | nil
---@field query string | URLSearchParams
local URLState = {}

---@alias URLSearchParams gpm.std.URLSearchParams
---@class gpm.std.URLSearchParams : gpm.std.Object
---@field __class gpm.std.URLSearchParamsClass
local URLSearchParams = {}

--- Appends name and value to the end
---@param name string
---@param value string?
function URLSearchParams:append(name, value) end

--- searches all parameters with given name, and deletes them
--- if `value` is given, then searches for exactly given name AND value
---@param name string
---@param value string?
function URLSearchParams:delete(name, value) end

--- Finds first value associated with given name
---@param name string
---@return string | nil
function URLSearchParams:get(name) end

--- Finds all values associated with given name and returns them as list
---@param name string
---@return table
function URLSearchParams:getAll(name) end

--- Returns true if parameters with given name exists
--- and value if given
---@param name string
---@param value string?
---@return boolean
function URLSearchParams:has(name, value) end

--- Sets first name to a given value (or appends [name, value])
--- and deletes other parameters with the same name
---@param name string
---@param value string?
function URLSearchParams:set(name, value) end

--- Sorts parameters inside URLSearchParams
function URLSearchParams:sort() end

--- returns iterator that can be used in for loops
--- e.g. `for name, value in searchParams:entries() do ... end`
---@return fun(): string, string
function URLSearchParams:iterator() end

--- returns iterator that can be used in for loops
---@return fun(): string
function URLSearchParams:keys() end

--- returns iterator that can be used in for loops
---@return fun(): string
function URLSearchParams:values() end

---@class URLSearchParamsClass : gpm.std.URLSearchParams
---@field __base URLSearchParams
---@operator len:integer

--- Parses given `init` and returns a new URLSearchParams object
--- if `init` is table, then it must be a list that consists of tables
--- that have two value, name and value
--- e.g. `{ {"name", "value"}, {"foo", "bar"}, {"good"} }`
---
--- also calling tostring(...) with URLSearchParams given will result in getting serialized query
--- also `#` can be used to get a total count of parameters (e.g. #searchParams)
---@return URLSearchParams
function std.URLSearchParams(init, url) end

---@alias URL gpm.std.URL
---@class gpm.std.URL : gpm.std.Object, gpm.std.URLState
---@field __class gpm.std.URLClass
---@field state URLState internal state of URL
---@field href string full url
---@field origin string? *readonly* scheme + hostname + port
---@field protocol string? just a scheme with ':' appended at the end
---@field username string?
---@field password string?
---@field host string hostname + port
---@field hostname string?
---@field port number?
---@field pathname string?
---@field query string?
---@field search string? a query with '?' prepended
---@field searchParams URLSearchParams
---@field fragment string?
---@field hash string? fragment with # prepended
local URL = {}

---@class gpm.std.URLClass : gpm.std.URL
---@field __base URL
local URLClass = {}

--- Parses given URL string but returns URLState object instead
---@see std.URL
---@param url string
---@param base string | URL | nil
---@return URLState
function URLClass.parse(url, base) end

--- Returns true if given url can be parsed with URLState
--- otherwise returns false and error string
---@param url string
---@param base string | URL | nil
---@return boolean
---@return URLState | string
function URLClass.canParse(url, base) end

--- see https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/encodeURI
---@param uri string
---@return string
function URLClass.encodeURI(uri) end

--- see https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/encodeURIComponent
---@param uri string
---@return string
function URLClass.encodeURIComponent(uri) end

--- see https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/decodeURI
---@param uri string
---@return string
function URLClass.decodeURI(uri) end

--- see https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/decodeURIComponent
---@param uri string
---@return string
function URLClass.decodeURIComponent(uri) end

--- Serializes given URLState object to full url string
--- basically same as accessing ``.href`` of URL object
---@param state URLState
---@param excludeFragment boolean if true, fragment will be excluded (default: false)
---@return string
function URLClass.serialize(state, excludeFragment) end

--- Parses given URL string and returns a new URL object
--- using URL object with tostring(...) will result in getting `.href`
--- ```lua
--- local baseUrl = "https://developer.mozilla.org"
---
--- local A = URL("/", baseURL)
--- -- => 'https://developer.mozilla.org/'
---
--- local B = URL(baseURL)
--- -- => 'https://developer.mozilla.org/'
---
--- URL("en-US/docs", B)
--- -- => 'https://developer.mozilla.org/en-US/docs'
---
--- local D = URL("/en-US/docs", B)
--- -- => 'https://developer.mozilla.org/en-US/docs'
---
--- URL("/en-US/docs", D)
--- -- => 'https://developer.mozilla.org/en-US/docs'
---
--- URL("/en-US/docs", A)
--- -- => 'https://developer.mozilla.org/en-US/docs'
---
--- URL("/en-US/docs", "https://developer.mozilla.org/fr-FR/toto")
--- -- => 'https://developer.mozilla.org/en-US/docs'
--- ```
---@param url string an url string to parse
---@param base string | URL | nil optional base url
---@return URL
function std.URL(url, base) end
