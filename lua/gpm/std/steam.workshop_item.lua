local _G = _G
local gpm = _G.gpm
local steamworks = _G.steamworks

local std = gpm.std
local string = std.string
local Future = std.Future

local MENU = std.MENU
local CLIENT_MENU = std.CLIENT_MENU

---@class gpm.std.steam
local steam = std.steam or {}
std.steam = steam

local isstring = std.isstring
local Timer_wait = std.Timer.wait


---@alias gpm.std.steam.WorkshopItem.ContentType
---| string # The type of the content.
---| `"addon"`
---| `"save"`
---| `"dupe"`
---| `"demo"`

---@alias gpm.std.steam.WorkshopItem.Type
---| string # The type of the publication.
---| `"gamemode"`
---| `"map"`
---| `"weapon"`
---| `"vehicle"`
---| `"npc"`
---| `"entity"`
---| `"tool"`
---| `"effects"`
---| `"model"`
---| `"servercontent"`

---@alias gpm.std.steam.WorkshopItem.AddonTag
---| string # The tag of the addon.
---| `"fun"`
---| `"roleplay"`
---| `"scenic"`
---| `"movie"`
---| `"realism"`
---| `"cartoon"`
---| `"water"`
---| `"comic"`
---| `"build"`

---@alias gpm.std.steam.WorkshopItem.DupeTag
---| string # The tag of the dupe.
---| `"buildings"`
---| `"machines"`
---| `"posed"`
---| `"scenes"`
---| `"vehicles"`
---| `"other"`

---@alias gpm.std.steam.WorkshopItem.SaveTag
---| string # The tag of the save.
---| `"buildings"`
---| `"courses"`
---| `"machines"`
---| `"scenes"`
---| `"other"`

---@alias gpm.std.steam.WorkshopItem.SearchType
---| string # The workshop search types.
---| `"friendfavorite"` # A favorite publication of the client's friends.
---| `"subscribed"` # The addons to which the client is subscribed.
---| `"friends"` # The publish to which the client is subscribed.
---| `"favorite"` # The client's favorite publications.
---| `"trending"` # The publications sorted by popularity.
---| `"popular"` # The publications are actively gaining popularity right now.
---| `"latest"` # The most recently published publications.
---| `"mine"` # The publications produced by the client.

--- [SHARED AND MENU]
---
--- The Steam Workshop publication object.
---
---@alias WorkshopItem gpm.std.steam.WorkshopItem
---@class gpm.std.steam.WorkshopItem: gpm.std.Object
---@field __class gpm.std.steam.WorkshopItemClass
---@field wsid string The workshop ID of the addon.
local WorkshopItem = std.class.base( "steam.WorkshopItem" )

--- [SHARED AND MENU]
---
--- The Steam Workshop publication class.
---
---@class gpm.std.steam.WorkshopItemClass: gpm.std.steam.WorkshopItem
---@field __base gpm.std.steam.WorkshopItem
---@overload fun( wsid: string ): WorkshopItem
local WorkshopItemClass = std.class.create( WorkshopItem )
steam.WorkshopItem = WorkshopItemClass

local findWorkshopItem
do

    local engine = gpm.engine

    function findWorkshopItem( wsid )
        local addons = engine.addons
        for i = 1, engine.addon_count, 1 do
            local data = addons[ i ]
            if data.wsid == wsid then
                return data
            end
        end
    end

    --- [SHARED AND MENU]
    ---
    --- Returns all subscribed publications.
    ---
    ---@return WorkshopItem[]: The subscribed addons.
    ---@return integer: The length of the addons found array (`#addons`).
    function WorkshopItemClass.getDownloaded()
        local addons, count = engine.addons, engine.addon_count

        for i = 1, count, 1 do
            addons[ i ] = WorkshopItemClass( addons[ i ].wsid )
        end

        return addons, count
    end

    --- [SHARED AND MENU]
    ---
    --- Returns all mounted addons.
    ---
    ---@return WorkshopItem[]: The mounted addons.
    ---@return integer: The length of the addons found array (`#addons`).
    function WorkshopItemClass.getMounted()
        local addons = engine.addons

        local result, length = {}, 0
        for i = 1, engine.addon_count, 1 do
            local data = addons[ i ]
            if data.mounted then
                length = length + 1
                result[ length ] = WorkshopItemClass( data.wsid )
            end
        end

        return result, length
    end

end

---@protected
function WorkshopItem:__tostring()
    local title = self:getTitle()
    if title == nil then
        return string.format( "steam.WorkshopItem [%s]", self:getWorkshopID() )
    else
        local size = self:getSize()
        if size == nil then
            return string.format( "steam.WorkshopItem [%s][%s]", self:getWorkshopID(), title )
        else
            return string.format( "steam.WorkshopItem [%s][%s][%.1fMB]", self:getWorkshopID(), title, size / 1024 / 1024 )
        end
    end
end

do

    local cache = {}

    ---@param wsid string The workshop ID of the addon.
    ---@protected
    function WorkshopItem:__init( wsid )
        self[ 0 ] = wsid
        cache[ wsid ] = self
    end

    ---@protected
    function WorkshopItem:__new( wsid )
        return cache[ wsid ]
    end

end

--- [SHARED AND MENU]
---
--- Returns the workshop ID of the publication.
---
---@return string: The workshop ID of the publication.
function WorkshopItem:getWorkshopID()
    return self[ 0 ]
end

do

    local wsid2title = {}

    --- [SHARED AND MENU]
    ---
    --- Returns the title of the publication.
    ---
    ---@param wsid string The workshop ID of the publication.
    ---@return string?: The title of the publication.
    local function getTitle( wsid )
        local title = wsid2title[ wsid ]
        if title == nil then
            local data = findWorkshopItem( wsid )
            if data == nil then
                return nil
            end

            title = data.title
            wsid2title[ wsid ] = title
        end

        return title
    end

    --- [SHARED AND MENU]
    ---
    --- Returns the title of the publication.
    ---
    ---@return string?: The title of the publication.
    function WorkshopItem:getTitle()
        return getTitle( self[ 0 ] )
    end

    WorkshopItemClass.getTitle = getTitle

end

do

    --- [SHARED AND MENU]
    ---
    --- Returns the absolute file path of the addon `.gma`.
    ---
    ---@param wsid string The workshop ID of the publication.
    ---@return string?: The absolute file path of the publication `.gma`.
    local function getFilePath( wsid )
        local data = findWorkshopItem( wsid )
        if data == nil then return nil end

        local filePath = data.file
        if filePath == "" then return nil end

        return "/" .. filePath
    end

    --- [SHARED AND MENU]
    ---
    --- Returns the absolute file path of the addon `.gma`.
    ---
    ---@return string?: The absolute file path of the publication `.gma`.
    function WorkshopItem:getFilePath()
        return getFilePath( self[ 0 ] )
    end

    WorkshopItemClass.getFilePath = getFilePath

end

do

    --- [SHARED AND MENU]
    ---
    --- Checks if the addon is mounted.
    ---
    ---@param wsid string The workshop ID of the addon.
    ---@return boolean: `true` if the addon is mounted, `false` otherwise.
    local function isMounted( wsid )
        local data = findWorkshopItem( wsid )
        if data == nil then return false end
        return data.mounted == true
    end

    --- [SHARED AND MENU]
    ---
    --- Checks if the addon is mounted.
    ---
    ---@return boolean: `true` if the addon is mounted, `false` otherwise.
    function WorkshopItem:isMounted()
        return isMounted( self[ 0 ] )
    end

    WorkshopItemClass.isMounted = isMounted

end

do

    --- [SHARED AND MENU]
    ---
    --- Checks if the publication is downloaded.
    ---
    ---@param wsid string The workshop ID of the publication.
    ---@return boolean: `true` if the publication is downloaded, `false` otherwise.
    local function isDownloaded( wsid )
        local data = findWorkshopItem( wsid )
        if data == nil then return false end
        return data.downloaded == true
    end

    --- [SHARED AND MENU]
    ---
    --- Checks if the addon is downloaded.
    ---
    ---@return boolean: `true` if the addon is downloaded, `false` otherwise.
    function WorkshopItem:isDownloaded()
        return isDownloaded( self[ 0 ] )
    end

    WorkshopItemClass.isDownloaded = isDownloaded

end

do

    local string_lower = string.lower
    local table_remove = std.table.remove
    local string_byteSplit = string.byteSplit

    do

        local addon_types = {
            gamemode = true,
            map = true,
            weapon = true,
            vehicle = true,
            npc = true,
            entity = true,
            tool = true,
            effects = true,
            model = true,
            servercontent = true
        }

        --- [SHARED AND MENU]
        ---
        --- Returns the type of the publication.
        ---
        ---@param wsid string The workshop ID of the publication.
        ---@return gpm.std.steam.WorkshopItem.Type?: The type of the publication.
        local function getType( wsid )
            local data = findWorkshopItem( wsid )
            if data == nil then return nil end

            local tags, length = string_byteSplit( data.tags, 0x2C --[[ , ]] )

            for i = length, 1, -1 do
                local tag = string_lower( tags[ i ] )
                if addon_types[ tag ] then return tag end
            end

            return nil
        end

        --- [SHARED AND MENU]
        ---
        --- Returns the type of the publication.
        ---
        ---@return gpm.std.steam.WorkshopItem.Type?: The type of the publication.
        function WorkshopItem:getType()
            return getType( self[ 0 ] )
        end

        WorkshopItemClass.getType = getType

    end

    do

        local addon_tags = {
            fun = true,
            roleplay = true,
            scenic = true,
            movie = true,
            realism = true,
            cartoon = true,
            water = true,
            comic = true,
            build = true
        }

        --- [SHARED AND MENU]
        ---
        --- Returns the tags of the addon.
        ---
        ---@param wsid string The workshop ID of the addon.
        ---@return gpm.std.steam.WorkshopItem.AddonTag[]?: The tags of the addon.
        ---@return integer?: The number of tags.
        local function getTags( wsid )
            local data = findWorkshopItem( wsid )
            if data == nil then return nil end

            local tags, length = string_byteSplit( data.tags, 0x2C --[[ , ]] )

            for i = length, 1, -1 do
                local tag = string_lower( tags[ i ] )
                if addon_tags[ tag ] then
                    tags[ i ] = tag
                else
                    table_remove( tags, i )
                    length = length - 1
                end
            end

            return tags, length
        end

        --- [SHARED AND MENU]
        ---
        --- Returns the tags of the addon.
        ---
        ---@return string[]?: The tags of the addon.
        function WorkshopItem:getTags()
            return getTags( self[ 0 ] )
        end

        WorkshopItemClass.getTags = getTags

    end

end

do

    --- [SHARED AND MENU]
    ---
    --- Returns the last time the addon was updated.
    ---
    ---@param wsid string The workshop ID of the publication.
    ---@return integer?: The last time the publication was updated in UNIX time.
    local function getUpdateTime( wsid )
        local data = findWorkshopItem( wsid )
        if data == nil then return nil end
        return data.timeupdated
    end

    --- [SHARED AND MENU]
    ---
    --- Returns the last time the publication was updated.
    ---
    ---@return integer?: The last time the publication was updated in UNIX time.
    function WorkshopItem:getUpdateTime()
        return getUpdateTime( self[ 0 ] )
    end

    WorkshopItemClass.getUpdateTime = getUpdateTime

end

do

    --- [SHARED AND MENU]
    ---
    --- Returns the creation time of the publication.
    ---
    ---@param wsid string The workshop ID of the publication.
    ---@return integer?: The creation time of the publication in UNIX time.
    local function getCreationTime( wsid )
        local data = findWorkshopItem( wsid )
        if data == nil then return nil end
        return data.timecreated
    end

    --- [SHARED AND MENU]
    ---
    --- Returns the creation time of the publication.
    ---
    ---@return integer?: The creation time of the publication in UNIX time.
    function WorkshopItem:getCreationTime()
        return getCreationTime( self[ 0 ] )
    end

    WorkshopItemClass.getCreationTime = getCreationTime

end

do

    --- [SHARED AND MENU]
    ---
    --- Returns the size of the publication.
    ---
    ---@param wsid string The workshop ID of the publication.
    ---@return integer?: The size of the publication in bytes.
    local function getSize( wsid )
        local data = findWorkshopItem( wsid )
        if data == nil then return nil end
        return data.size
    end

    --- [SHARED AND MENU]
    ---
    --- Returns the size of the publication.
    ---
    ---@return integer?: The size of the publication in bytes.
    function WorkshopItem:getSize()
        return getSize( self[ 0 ] )
    end

    WorkshopItemClass.getSize = getSize

end

if CLIENT_MENU then

    local steamworks_ShouldMountAddon = steamworks.ShouldMountAddon

    --- [MENU]
    ---
    --- Returns whether the addon should be mounted.
    ---
    ---@return boolean?: Whether the addon should be mounted.
    function WorkshopItem:isShouldMount()
        return steamworks_ShouldMountAddon( self[ 0 ] )
    end

    WorkshopItemClass.isShouldMount = steamworks_ShouldMountAddon

end

if MENU then

    local steamworks_SetShouldMountAddon = steamworks.SetShouldMountAddon

    --- [SHARED AND MENU]
    ---
    --- Sets whether the addon should be mounted.
    ---
    ---@param should_mount boolean Whether the addon should be mounted.
    function WorkshopItem:setShouldMount( should_mount )
        steamworks_SetShouldMountAddon( self[ 0 ], should_mount )
    end

    WorkshopItemClass.setShouldMount = steamworks_SetShouldMountAddon

end

if MENU then

    local steamworks_SetFilePlayed = steamworks.SetFilePlayed

    --- [SHARED AND MENU]
    ---
    --- Marks the publication as played.
    ---
    function WorkshopItem:markAsPlayed()
        steamworks_SetFilePlayed( self[ 0 ] )
    end

    WorkshopItemClass.markAsPlayed = steamworks_SetFilePlayed

end

if MENU then

    local steamworks_SetFileCompleted = steamworks.SetFileCompleted

    --- [SHARED AND MENU]
    ---
    --- Marks the publication as completed.
    ---
    function WorkshopItem:markAsCompleted()
        steamworks_SetFileCompleted( self[ 0 ] )
    end

    WorkshopItemClass.markAsCompleted = steamworks_SetFileCompleted

end

if CLIENT_MENU then

    local steamworks_IsSubscribed = steamworks.IsSubscribed

    --- [SHARED AND MENU]
    ---
    --- Checks if the publication is subscribed.
    ---
    ---@return boolean: `true` if the publication is subscribed, `false` otherwise.
    function WorkshopItem:isSubscribed()
        return steamworks_IsSubscribed( self[ 0 ] )
    end

    WorkshopItemClass.isSubscribed = steamworks_IsSubscribed

end

if MENU then

    local steamworks_Subscribem, steamworks_Unsubscribe = steamworks.Subscribe, steamworks.Unsubscribe

    --- [SHARED AND MENU]
    ---
    --- Subscribes or unsubscribes the publication.
    ---
    ---@param wsid string The workshop ID of the publication.
    ---@param subscribed boolean `true` to subscribe, `false` to unsubscribe.
    local function setSubscribed( wsid, subscribed )
        if subscribed then
            steamworks_Subscribem( wsid )
        else
            steamworks_Unsubscribe( wsid )
        end
    end

    --- [SHARED AND MENU]
    ---
    --- Subscribes or unsubscribes the publication.
    ---
    ---@param subscribed boolean `true` to subscribe, `false` to unsubscribe.
    function WorkshopItem:setSubscribed( subscribed )
        setSubscribed( self[ 0 ], subscribed )
    end

    WorkshopItemClass.setSubscribed = setSubscribed

end

if MENU then

    local steamworks_Vote = steamworks.Vote

    --- [SHARED AND MENU]
    ---
    --- Votes for or against the publication.
    ---
    ---@param up_or_down boolean `true` to vote for, `false` to vote against.
    function WorkshopItem:vote( up_or_down )
        steamworks_Vote( self[ 0 ], up_or_down )
    end

    WorkshopItemClass.vote = steamworks_Vote

end

if CLIENT_MENU then

    local steamworks_ViewFile = steamworks.ViewFile

    --- [SHARED AND MENU]
    ---
    --- Opens the workshop page of the publication.
    ---
    function WorkshopItem:openWorkshopPage()
        steamworks_ViewFile( self[ 0 ] )
    end

    WorkshopItem.openWorkshopPage = steamworks_ViewFile

end

if CLIENT_MENU then

    local steamworks_Download = steamworks.Download

    --- [SHARED AND MENU]
    ---
    --- Downloads the icon of the publication.
    ---
    ---@param wsid string The workshop ID of the publication.
    ---@param uncompress boolean?: Whether the icon should be uncompressed. Default is `true`.
    ---@return string: The absolute path to the icon file.
    ---@async
    local function downloadIcon( wsid, uncompress, timeout )
        if uncompress == nil then uncompress = true end
        local f = Future()

        steamworks_Download( wsid, uncompress, function( filePath )
            if isstring( filePath ) then
                ---@cast filePath string
                f:setResult( "/" .. filePath )
            else
                f:setError( "failed to download icon file for '" .. wsid .. "', unknown error." )
            end
        end )

        Timer_wait( function()
            if f:isPending() then
                f:setError( "failed to download icon file for '" .. wsid .. "', timed out." )
            end
        end, timeout or 30 )

        return f:await()
    end

    --- [SHARED AND MENU]
    ---
    --- Downloads the icon of the publication.
    ---
    ---@param uncompress boolean?: Whether the icon should be uncompressed. Default is `true`.
    ---@return string: The absolute path to the icon file.
    ---@async
    function WorkshopItem:downloadIcon( uncompress )
        return downloadIcon( self[ 0 ], uncompress )
    end

    WorkshopItemClass.downloadIcon = downloadIcon

end

if CLIENT_MENU then

    local steamworks_DownloadUGC = steamworks.DownloadUGC
    local file_write = std.file.write

    --- [SHARED AND MENU]
    ---
    --- Downloads the addon and returns the absolute path to the `.gma` file.
    ---
    ---@param wsid string The workshop ID of the addon.
    ---@param timeout number | nil | false: The timeout in seconds. Set to `false` to disable the timeout.
    ---@return string: The absolute path to the downloaded addon `.gma`.
    ---@async
    local function download( wsid, timeout )
        local f = Future()

        steamworks_DownloadUGC( wsid, function( filePath, file )
            if isstring( filePath ) then
                f:setResult( "/" .. filePath )
            else
                if file == nil then
                    f:setError( "failed to download addon '" .. wsid .. "', unknown error." )
                else
                    ---@cast file File
                    file_write( "/gpm/cache/workshop/" .. wsid .. ".gma", file:Read( file:Size() ) )
                end
            end
        end )

        if timeout ~= false then
            Timer_wait( function()
                if f:isPending() then
                    f:setError( "failed to download addon '" .. wsid .. "', timed out." )
                end
            end, timeout or 30 )
        end

        return f:await()
    end

    --- [SHARED AND MENU]
    ---
    --- Downloads the addon from Steam Workshop and returns the absolute path to the `.gma` file.
    ---
    ---@param timeout number | nil | false: The timeout in seconds. Set to `false` to disable the timeout.
    ---@return string: The absolute path to the `.gma` file.
    ---@async
    function WorkshopItem:download( timeout )
        return download( self[ 0 ], timeout )
    end

    WorkshopItemClass.download = download

end

do

    local steamworks_FileInfo = steamworks.FileInfo
    local istable = std.istable

    --- [SHARED AND MENU]
    ---
    --- Fetches the info of the publication from Steam Workshop.
    ---
    ---@param wsid string The workshop ID of the publication.
    ---@param timeout number | nil | false The timeout in seconds. Set to `false` to disable the timeout.
    ---@return gpm.std.steam.WorkshopItem.Info info The info of the publication.
    ---@async
    local function fetchInfo( wsid, timeout )
        local f = Future()

        steamworks_FileInfo( wsid, function( info )
            if istable( info ) then
                ---@cast info gpm.std.steam.WorkshopItem.Info
                f:setResult( info )
            else
                f:setError( "failed to fetch info for addon '" .. wsid .. "', unknown error." )
            end
        end )

        if timeout ~= false then
            Timer_wait( function()
                if f:isPending() then
                    f:setError( "failed to fetch info for addon '" .. wsid .. "', timed out." )
                end
            end, timeout or 30 )
        end

        return f:await()
    end

    --- [SHARED AND MENU]
    ---
    --- Fetches the info of the publication from Steam Workshop.
    ---
    ---@param timeout number | nil | false The timeout in seconds. Set to `false` to disable the timeout.
    ---@return gpm.std.steam.WorkshopItem.Info info The info of the publication.
    ---@async
    function WorkshopItem:fetchInfo( timeout )
        return fetchInfo( self[ 0 ], timeout )
    end

    WorkshopItemClass.fetchInfo = fetchInfo

end

-- WorkshopItem presets stuff, I think an additional library/package will be needed in the future..
if MENU and WorkshopItemClass.PresetsLoaded == nil then

    --- [MENU]
    ---
    --- A hook that is called when publication presets are loaded.
    ---
    local PresetsLoaded = std.Hook( "WorkshopItem.PresetsLoaded" )
    gpm.engine.hookCatch( "AddonPresetsLoaded", PresetsLoaded )
    WorkshopItemClass.PresetsLoaded = PresetsLoaded

end

WorkshopItemClass.loadPresets = WorkshopItemClass.loadPresets or _G.LoadAddonPresets
WorkshopItemClass.savePresets = WorkshopItemClass.savePresets or _G.SaveAddonPresets

do

    local math_max, math_clamp = std.math.max, std.math.clamp
    local steamworks_GetList = steamworks.GetList

    local type2type = {
        subscribed = "followed",
        friendfavorite = "friend_favs"
    }

    setmetatable( type2type, {
        __index = function( _, key )
            return key
        end
    } )

    --- [SHARED AND MENU]
    ---
    --- Performs a search for publications.
    ---
    ---@param params gpm.std.steam.WorkshopItem.SearchParams The search parameters.
    ---@async
    function WorkshopItemClass.search( params )
        local f = Future()

        steamworks_GetList( type2type[ params.type or "latest" ], params.tags, math_max( 0, params.offset or 0 ), math_clamp( params.count or 50, 1, 50 ), math_clamp( params.days or 365, 1, 365 ), params.owned and "1" or ( params.steamid64 or "0" ), function( data )
            f:setResult( data )
        end )

        Timer_wait( function()
            if f:isPending() then
                f:setError( "failed to perform quick workshop search, timed out." )
            end
        end, params.timeout or 30 )

        local data = f:await()
        local results, count = data.results, data.numresults

        local addons = {}
        for i = 0, count - 1, 1 do
            addons[ i + 1 ] = WorkshopItemClass( results[ i ] )
        end

        return addons, count, data.totalresults
    end

    --- [SHARED AND MENU]
    ---
    --- Performs a quick search for publications.
    ---
    ---@param wtype gpm.std.steam.WorkshopItem.SearchType The type of the search.
    ---@param wtags string[]? The tags of the search.
    ---@param woffset integer? The offset of the search.
    ---@param timeout number? The timeout in seconds of the search.
    ---@return WorkshopItem[] items The found publications.
    ---@return integer item_count The length of the publications found array (`#publications`).
    ---@return integer total The total number of publications found.
    ---@async
    function WorkshopItemClass.qickSearch( wtype, wtags, woffset, timeout )
        local f = Future()

        ---@diagnostic disable-next-line: param-type-mismatch
        steamworks_GetList( type2type[ wtype or "latest" ], wtags, math_max( 0, woffset or 0 ), 50, 365, "0", function( data )
            f:setResult( data )
        end )

        Timer_wait( function()
            if f:isPending() then
                f:setError( "failed to perform quick workshop search, timed out." )
            end
        end, timeout or 30 )

        local data = f:await()
        local results, count = data.results, data.numresults

        local publications = {}
        for i = 0, count - 1, 1 do
            publications[ i + 1 ] = WorkshopItemClass( results[ i ] )
        end

        return publications, count, data.totalresults
    end

    --- [SHARED AND MENU]
    ---
    --- Returns a list of publications published by the client.
    ---
    ---@param wtype gpm.std.steam.WorkshopItem.SearchType The type of the search.
    ---@param wtags string[]? The tags of the search.
    ---@param woffset integer? The offset of the search.
    ---@param timeout number? The timeout in seconds of the search.
    ---@return WorkshopItem[] items The found publications.
    ---@return integer item_count The length of the publications found array (`#publications`).
    ---@return integer total The total number of publications found.
    ---@async
    function WorkshopItemClass.getPublished( wtype, wtags, woffset, timeout )
        local f = Future()

        ---@diagnostic disable-next-line: param-type-mismatch
        steamworks_GetList( type2type[ wtype or "latest" ], wtags, math_max( 0, woffset or 0 ), 50, 365, "1", function( data )
            f:setResult( data )
        end )

        Timer_wait( function()
            if f:isPending() then
                f:setError( "failed to perform quick workshop search, timed out." )
            end
        end, timeout or 30 )

        local data = f:await()
        local results, count = data.results, data.numresults

        local publications = {}
        for i = 0, count - 1, 1 do
            publications[ i + 1 ] = WorkshopItemClass( results[ i ] )
        end

        return publications, count, data.totalresults
    end

end
