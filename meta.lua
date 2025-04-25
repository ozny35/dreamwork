---@meta

---@class gpm.std
std = {}

do

    --- [SHARED AND MENU]
    ---
    --- Table used by `Logger` constructor.
    ---@class gpm.std.Logger.Options
    local logger_options = {}

    --- The title of the logger.
    ---@type string | nil
    logger_options.title = nil

    --- The color of the title.
    ---@type gpm.std.Color | nil
    logger_options.color = nil

    --- The color of the text.
    ---@type gpm.std.Color | nil
    logger_options.text_color = nil

    --- Whether to interpolate the message.
    ---@type boolean | nil
    logger_options.interpolation = nil

    --- The developer mode check function.
    ---@type ( fun(): boolean ) | nil
    logger_options.debug = nil

end

--- [SHARED AND MENU]
---
--- HTTP request method.
--- 0. HEAD
--- 1. GET
--- 2. POST
--- 3. PUT
--- 4. PATCH
--- 5. DELETE
--- 6. OPTIONS
---
---@alias gpm.std.http.Request.Method
---| integer
---| `0` HEAD
---| `1` GET
---| `2` POST
---| `3` PUT
---| `4` PATCH
---| `5` DELETE
---| `6` OPTIONS

do

    --- [SHARED AND MENU]
    ---
    --- Table used by `http.request` function.
    ---@class gpm.std.http.Request
    local request = {}

    --- Request method (0 = HEAD, 1 = GET, 2 = POST, 3 = PUT, 4 = PATCH, 5 = DELETE, 6 = OPTIONS).
    ---
    --- The default value is 1 (GET).
    ---@type gpm.std.http.Request.Method | nil
    request.method = nil

    --- The target url
    ---@type string | URL
    request.url = nil

    --- KeyValue table for parameters.
    ---
    --- This is only applicable to the following request methods:
    --- (0 = HEAD, 1 = GET, 2 = POST)
    ---@type gpm.std.URL.SearchParams | table | nil
    request.parameters = nil

    --- Body string for POST data.
    --- If set, will override parameters.
    ---@type string | nil
    request.body = nil

    --- KeyValue table for headers.
    ---@type table | nil
    request.headers = nil

    --- Content type for body.
    ---@type string | nil
    request.type = "text/plain; charset=utf-8"

    --- The timeout for the connection.
    ---@type number | nil
    request.timeout = 60

    --- Whether to cache the response.
    ---@type boolean | nil
    request.cache = false

    --- The cache lifetime for the request.
    ---@type number | nil
    request.lifetime = nil

    --- Whether to use ETag caching.
    ---@type boolean | nil
    request.etag = false

end

do

    --- [SHARED AND MENU]
    ---
    --- The success callback.
    ---@class gpm.std.http.Response
    local response = {}

    --- The response status code.
    ---@type number
    response.status = nil

    --- The response body.
    ---@type string
    response.body = nil

    --- The response headers.
    ---@type table
    response.headers = nil

end

do

    --- [SHARED AND MENU]
    ---
    --- The server information table.
    ---@class gpm.std.server.Info
    local server_info = {}

    --- The server ping in milliseconds.
    ---@type number
    server_info.ping = 0

    --- The server name.
    ---
    --- This value is set on the server by the `hostname` convar.
    ---@type string
    server_info.name = "Garry's Mod"

    --- The name of the loaded level on the server.
    ---
    --- BSP: `maps/{name}.bsp`
    --- AI navigation: `maps/{name}.ain`
    --- Navigation Mesh: `maps/{name}.nav`
    ---@type string
    server_info.level_name = "gm_construct"

    --- Contains the version number of GMod.
    ---@type number
    server_info.version = 201211

    --- The server address in IP:Port format.
    ---@type string
    server_info.address = "127.0.0.1:27015"

    --- Two digit country code in the [ISO 3166-1 alpha-2](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2) standard.
    ---
    --- This value is set on the server by the [sv_location](https://wiki.facepunch.com/gmod/Downloading_a_Dedicated_Server#locationflag) convar.
    ---@type string?
    server_info.country = nil

    --- Time when you last played on this server, as UNIX timestamp or 0.
    ---@type number
    server_info.last_played_time = 0

    --- Whether this server has password or not.
    ---
    --- On the server, this value is set by the console variable `sv_password`.
    ---@type boolean
    server_info.has_password = false

    --- Is the server signed into an anonymous account?
    ---
    --- The value will be `false` if `+sv_setsteamaccount` is equal to a valid Steam game server token.
    ---
    --- [Steam Game Server Accounts](https://wiki.facepunch.com/gmod/Steam_Game_Server_Accounts)
    ---@type boolean
    server_info.is_anonymous = false

    --- The number of players on the server.
    ---
    --- This is a total player count including both real people and bots created by the server.
    ---@type number
    server_info.player_count = 0

    --- The maximum number of players on the server.
    ---
    --- This value can be set at server startup using the console variable [`+maxplayers`](https://developer.valvesoftware.com/wiki/Maxplayers).
    ---@type number
    server_info.player_limit = 0

    --- The number of bots on the server created by the server itself.
    ---@type number
    server_info.bot_count = 0

    --- The number of real people (game clients) on the server.
    ---@type number
    server_info.human_count = 0

    --- The [gamemode folder](https://wiki.facepunch.com/gmod/Gamemode_Creation#gamemodefolder) name and the [`GM.Folder`](https://wiki.facepunch.com/gmod/Gamemode_Creation#gamemodefoldername) value.
    ---
    --- This applies to Garry's gamemodes, they are different from the gamemodes in gpm...
    ---@type string
    server_info.gamemode_name = "sandbox"

    --- The [`GM.Name`](https://wiki.facepunch.com/gmod/Gamemode_Creation#sharedlua) value.
    ---
    --- This applies to Garry's gamemodes, they are different from the gamemodes in gpm...
    ---@type string
    server_info.gamemode_title = "Sandbox"

    --- The identifier of the gamemode workshop item in the Steam workshop.
    ---@type string?
    server_info.gamemode_wsid = nil

    --- The [category](https://wiki.facepunch.com/gmod/Gamemode_Creation#gamemodetextfile) of the gamemode, ex. `pvp`, `pve`, `rp` or `roleplay`.
    ---@type string
    server_info.gamemode_category = "other"

end

do

    --- [MENU]
    ---
    --- Queries the servers for it's information.
    ---@class gpm.std.server.QueryData
    local query_data = {}

    --- The game directory to get the servers for
    ---@type string
    query_data.directory = "garrysmod"

    --- Type of servers to retrieve. Valid values are `internet`, `favorite`, `history` and `lan`
    ---@type string
    query_data.type = nil

    --- Steam application ID to get the servers for
    ---@type number
    query_data.appid = 4000

    --- Called when a new server is found and queried.
    ---
    --- Function argument(s):
    --- * number `ping` - Latency to the server.
    --- * string `name` - Name of the server
    --- * string `gamemode_title` - "Nice" gamemode name
    --- * string `level_name` - Current map
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
    ---@type fun( ping: number, name: string, gamemode_title: string, level_name: string, player_count: number, player_limit: number, bot_count: number, has_password: boolean, last_played_time: number, address: string, gamemode_name: string, gamemode_wsid: number, is_anonymous: boolean, version: string, country: string, gamemode_category: string ): boolean
    query_data.server_queried = nil

    --- Called if the query has failed, called with the servers IP Address
    ---@type function
    query_data.query_failed = nil

    --- Called when the query is finished. No arguments
    ---@type function
    query_data.finished = nil

end

do

    --- [SHARED AND MENU]
    ---
    --- Table used by `console.Variable` class constructor.
    ---
    ---@class gpm.std.console.Variable.Data
    local console_variable_data = {}

    --- The name of the console variable.
    ---@type string
    console_variable_data.name = "variable_name"

    --- The type of the console variable.
    ---@type gpm.std.console.Variable.Type?
    console_variable_data.type = nil

    --- The flags of the console variable.
    ---@type gpm.std.console.Variable.Flags?
    console_variable_data.flags = nil

    --- The default value of the console variable.
    ---@type string | number | boolean | nil
    console_variable_data.default = nil

    --- The description of the console variable.
    ---@type string?
    console_variable_data.description = nil

    --- The minimal value of the console variable.
    ---@type number?
    console_variable_data.min = nil

    --- The maximum value of the console variable.
    ---@type number?
    console_variable_data.max = nil

end

do

    --- [SHARED AND MENU]
    ---
    --- The result table of executing `file.path.parse`.
    ---
    ---    ┌─────────────────────┬────────────┐
    ---    │          dir        │    base    │
    ---    ├──────┬              ├──────┬─────┤
    ---    │ root │              │ name │ ext │
    ---    "  /    home/user/dir/  file  .txt "
    ---    └──────┴──────────────┴──────┴─────┘
    ---    (All spaces in the "" line should be ignored. They are purely for formatting.)
    ---
    ---@class gpm.std.file.path.Data
    local path_data = {}

    --- The root of the file path.
    ---@type string
    path_data.root = ""

    --- The directory of the file path.
    ---@type string
    path_data.dir = ""

    --- The basename of the file path.
    ---@type string
    path_data.base = ""

    --- The name of the file path.
    ---@type string
    path_data.name = ""

    --- The extension of the file path.
    ---@type string
    path_data.ext = ""

    --- Whether the file path is absolute.
    ---@type boolean
    path_data.abs = false

end

do

    --- The params table that was used in `Addon` search functions.
    ---@class gpm.std.steam.WorkshopItem.SearchParams
    local search_params = {}

    --- The type of items to retrieve.
    ---@type gpm.std.steam.WorkshopItem.SearchType?
    search_params.type = nil

    --- A table of tags to match.
    ---@type string[]?
    search_params.tags = nil

    --- How much of results to skip from first one.
    ---@type number?
    search_params.offset = 0

    --- How many items to retrieve, up to 50 at a time.
    ---@type number?
    search_params.count = 50

    --- This determines a time period, in range of days from 0 to 365.
    ---@type number?
    search_params.days = 365

    --- If specified, receives items from the workshop created by the owner of SteamID64.
    ---@type string?
    search_params.steamid64 = "0"

    --- If specified, retrieves items from your workshop, and also eliminates the 'steamid64' key.
    ---@type boolean?
    search_params.owned = false

    --- Response time, after which the function will be terminated with an error (default 30)
    ---@type number?
    search_params.timeout = 30

end

do

    --- [SHARED AND MENU]
    ---
    --- The result table of fetching workshop item info.
    ---@class gpm.std.steam.WorkshopItem.Info
    local item_info = {}

    --- The Workshop item ID
    ---@type number
    item_info.id = nil

    --- The title of the Workshop item
    ---@type string
    item_info.title = nil

    --- The description of the Workshop item
    ---@type string
    item_info.description = nil

    --- The internal File ID of the workshop item, if any
    ---@type number
    item_info.fileid = nil

    --- The internal File ID of the workshop item preview, if any
    ---@type number
    item_info.previewid = nil

    --- A URL to the preview image of the workshop item
    ---@type string
    item_info.previewurl = nil

    --- The SteamID64 of the original uploader of the addon
    ---@type number
    item_info.owner = nil

    --- Unix timestamp of when the item was created
    ---@type number
    item_info.created = nil

    --- Unix timestamp of when the file was last updated
    ---@type number
    item_info.updated = nil

    --- Whether the file is banned or not
    ---@type boolean
    item_info.banned = nil

    --- Comma (,) separated list of tags, may be truncated to some length
    ---@type string
    item_info.tags = nil

    --- File size of the workshop item contents
    ---@type number
    item_info.size = nil

    --- Filesize of the preview file
    ---@type number
    item_info.previewsize = nil

    --- If the addon is subscribed, this value represents whether it is installed on the client and its files are accessible, false otherwise.
    ---@type boolean
    item_info.installed = nil

    --- If the addon is subscribed, this value represents whether it is disabled on the client, false otherwise.
    ---@type boolean
    item_info.disabled = nil

    --- A list of child Workshop Items for this item.
    ---
    --- For collections this will be sub-collections, for workshop items this will be the items they depend on.
    ---@type table
    item_info.children = nil

    --- We advise against using this. It may be changed or removed in a future update.
    ---
    --- The "nice" name of the Uploader, or "Unnammed Player" if we failed to get the data for some reason.
    ---
    --- Do not use this field as it will most likely not be updated in time. Use steamworks.RequestPlayerInfo instead.
    ---@type string
    item_info.ownername = nil

    --- If this key is set, no other data will be present in the response.
    ---
    --- Values above 0 represent Steam Error codes, values below 0 mean the following:
    --- * -1 means Failed to create query
    --- * -2 means Failed to send query
    --- * -3 means Received 0 or more than 1 result
    --- * -4 means Failed to get item data from the response
    --- * -5 means Workshop item ID in the response is invalid
    --- * -6 means Workshop item ID in response is mismatching the requested file ID
    ---@type number
    item_info.error = nil

    --- Number of "up" votes for this item.
    ---@type number
    item_info.up = nil

    --- Number of "down" votes for this item.
    ---@type number
    item_info.down = nil

    --- Number of total votes (up and down) for this item. This is NOT `up - down`.
    ---@type number
    item_info.total = nil

    --- The up down vote ratio for this item, i.e. `1` is when every vote is `up`, `0.5` is when half of the total votes are the up votes, etc.
    ---@type number
    item_info.score = nil

end

do

    --- [SHARED AND MENU]
    ---
    --- The URL state object.
    ---@alias URLState gpm.std.URL.State
    ---@class gpm.std.URL.State
    ---@field scheme string?
    ---@field username string?
    ---@field password string?
    ---@field hostname string | table | number | nil
    ---@field port number?
    ---@field path string | table | nil
    ---@field fragment string?
    ---@field query string | gpm.std.URL.SearchParams
    local URLState = {}

end

do

    --- [SHARED AND MENU]
    ---
    --- Git Tree
    ---
    --- The hierarchy between files in a Git repository.
    ---
    ---@class gpm.std.http.github.Tree
    local tree = {}

    --- The SHA1 of the tree.
    ---
    ---@type string
    tree.sha = nil

    --- The URL of the tree.
    ---
    ---@type string
    tree.url = nil

    --- Whether the tree is truncated.
    ---
    --- If truncated is true in the response
    --- then the number of items in the tree
    --- array exceeded our maximum limit.
    ---
    --- If you need to fetch more items,
    --- use the non-recursive method of
    --- fetching trees, and fetch one
    --- sub-tree at a time.
    ---
    ---@type boolean
    tree.truncated = nil

    --- [SHARED AND MENU]
    ---
    --- A list of files and directories in the tree.
    ---
    ---@class gpm.std.http.github.Tree.Item[]
    tree.tree = nil

    --- [SHARED AND MENU]
    ---
    --- A single file or directory in a tree.
    ---
    ---@class gpm.std.http.github.Tree.Item
    local item = {}

    --- The path to the file or directory.
    ---
    ---@type string
    tree.path = nil

    --- The type of item that this is.
    ---
	---| Mode    | Meaning                      | Types    |
	---|:--------|:-----------------------------|:---------|
    ---|`100644` | Normal file (non-executable) | `Blob`
    ---|`100755` | Executable file              | `Blob`
    ---|`040000` | Directory                    | `Tree`
    ---|`120000` | Symbolic link                | `Blob`
    ---|`160000` | Git submodule (commit ref)   | `Commit`
    ---
    ---@type string
    tree.mode = nil

    --- The type of item that this is.
    ---
    --- One of "blob", "tree", "commit".
    ---
    ---@type string
    tree.type = nil

    --- The SHA1 of the item.
    ---
    ---@type string
    tree.sha = nil

    --- The size of the item in bytes.
    ---
    ---@type number
    tree.size = nil

    --- The URL of the item.
    ---
    ---@type string
    tree.url = nil

end

do

    --- [SHARED AND MENU]
    ---
    --- A hashing method.
    ---
    ---@class gpm.std.crypto.hashlib
    local hashlib = {}

    --- The block size in bytes.
    ---
    --- @type integer
    hashlib.block = nil

    --- The digest ( fingerprint ) size in bytes.
    ---
    --- @type integer
    hashlib.digest = nil

    --- The digest ( fingerprint ) size in hex.
    ---
    --- @type integer
    hashlib.hex = nil

    --- The hash function.
    ---
    --- @type fun( data: string ): string
    hashlib.hash = nil

end
