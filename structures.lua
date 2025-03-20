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
