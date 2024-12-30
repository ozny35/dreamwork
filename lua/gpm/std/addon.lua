local _G = _G
local gpm = _G.gpm
local steamworks = _G.steamworks


---@class gpm.std
local std = gpm.std
local Future, is = std.Future, std.is

local timer_simple = std.timer.simple
local is_string = is.string


---@alias gpm.std.CONTENT_TYPE
---| string # The type of the content.
---| `"addon"`
---| `"save"`
---| `"dupe"`
---| `"demo"`

---@alias gpm.std.ADDON_TYPE
---| string # The type of the addon.
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

---@alias gpm.std.ADDON_TAG
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

---@alias gpm.std.DUPE_TAG
---| string # The tag of the dupe.
---| `"buildings"`
---| `"machines"`
---| `"posed"`
---| `"scenes"`
---| `"vehicles"`
---| `"other"`

---@alias gpm.std.SAVE_TAG
---| string # The tag of the save.
---| `"buildings"`
---| `"courses"`
---| `"machines"`
---| `"scenes"`
---| `"other"`


---@alias Addon gpm.std.Addon
---@class gpm.std.Addon: gpm.std.Object
---@field __class gpm.std.AddonClass
---@field private wsid string: The workshop ID of the addon.
local Addon = std.class.base( "Addon" )

---@class gpm.std.AddonClass: gpm.std.Addon
---@field __base gpm.std.Addon
---@overload fun( wsid: string ): Addon
local AddonClass = std.class.create( Addon )

local findAddon
do

    local engine_GetAddons = _G.engine.GetAddons
    local ipairs = _G.ipairs

    function findAddon( wsid )
        for _, data in ipairs( engine_GetAddons() ) do
            if data.wsid == wsid then
                return data
            end
        end
    end

    function AddonClass.getAll()
        local lst = engine_GetAddons()

        for i = 1, #lst, 1 do
            lst[ i ] = AddonClass( lst[ i ].wsid )
        end

        return lst
    end

end

do

    local string_format = std.string.format

    ---@protected
    function Addon:__tostring()
        local title = self:getTitle()
        if title == nil then
            return string_format( "Addon [%s]", self.wsid )
        else
            local size = self:getSize()
            if size == nil then
                return string_format( "Addon [%s][%s]", self.wsid, title )
            else
                return string_format( "Addon [%s][%s][%.1fMB]", self.wsid, title, size / 1024 / 1024 )
            end
        end
    end

end

do

    local cache = {}

    --- Creates a new addon.
    ---@param wsid string: The workshop ID of the addon.
    ---@protected
    function Addon:__init( wsid )
        self.wsid = wsid
        cache[ wsid ] = self
    end

    ---@protected
    function Addon.__new( wsid )
        return cache[ wsid ]
    end

end

--- Returns the workshop ID of the addon.
---@return string: The workshop ID of the addon.
function Addon:getWorkshopID()
    return self.wsid
end

do

    local wsid2title = {}

    --- Returns the title of the addon.
    ---@param wsid string: The workshop ID of the addon.
    ---@return string?: The title of the addon.
    local function getTitle( wsid )
        local title = wsid2title[ wsid ]
        if title == nil then
            local data = findAddon( wsid )
            if data == nil then
                return nil
            end

            title = data.title
            wsid2title[ wsid ] = title
        end

        return title
    end

    --- Returns the title of the addon.
    ---@return string?: The title of the addon.
    function Addon:getTitle()
        return getTitle( self.wsid )
    end

    AddonClass.getTitle = getTitle

end

do

    --- Returns the absolute file path of the addon `.gma`.
    ---@param wsid string: The workshop ID of the addon.
    ---@return string?: The absolute file path of the addon `.gma`.
    local function getFilePath( wsid )
        local data = findAddon( wsid )
        if data == nil then return nil end

        local filePath = data.file
        if filePath == "" then return nil end

        return "/" .. filePath
    end

    --- Returns the absolute file path of the addon `.gma`.
    ---@return string?: The absolute file path of the addon `.gma`.
    function Addon:getFilePath()
        return getFilePath( self.wsid )
    end

    AddonClass.getFilePath = getFilePath

end

do

    local mounted = {}

    --- Checks if the addon is mounted.
    ---@param wsid string: The workshop ID of the addon.
    ---@return boolean: `true` if the addon is mounted, `false` otherwise.
    local function isMounted( wsid )
        local value = mounted[ wsid ]
        if value == nil then
            local data = findAddon( wsid )
            if data == nil then return false end
            value = data.mounted == true
            mounted[ wsid ] = value
        end

        return value
    end

    --- Checks if the addon is mounted.
    ---@return boolean: `true` if the addon is mounted, `false` otherwise.
    function Addon:isMounted()
        return isMounted( self.wsid )
    end

    AddonClass.isMounted = isMounted

end

do

    local downloaded = {}

    --- Checks if the addon is downloaded.
    ---@param wsid string: The workshop ID of the addon.
    ---@return boolean: `true` if the addon is downloaded, `false` otherwise.
    local function isDownloaded( wsid )
        local value = downloaded[ wsid ]
        if value == nil then
            local data = findAddon( wsid )
            if data == nil then return false end
            value = data.downloaded == true
            downloaded[ wsid ] = value
        end

        return value
    end

    --- Checks if the addon is downloaded.
    ---@return boolean: `true` if the addon is downloaded, `false` otherwise.
    function Addon:isDownloaded()
        return isDownloaded( self.wsid )
    end

    AddonClass.isDownloaded = isDownloaded

end

do

    local string = std.string
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

        --- Returns the type of the addon.
        ---@param wsid string: The workshop ID of the addon.
        ---@return gpm.std.ADDON_TYPE?: The type of the addon.
        local function getType( wsid )
            local data = findAddon( wsid )
            if data == nil then return nil end

            local tags, length = string_byteSplit( data.tags, 0x2C --[[ , ]] )

            for i = length, 1, -1 do
                local tag = string_lower( tags[ i ] )
                if addon_types[ tag ] then return tag end
            end

            return nil
        end

        --- Returns the type of the addon.
        ---@return gpm.std.ADDON_TYPE?: The type of the addon.
        function Addon:getType()
            return getType( self.wsid )
        end

        AddonClass.getType = getType

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

        --- Returns the tags of the addon.
        ---@param wsid string: The workshop ID of the addon.
        ---@return gpm.std.ADDON_TAG[]?: The tags of the addon.
        ---@return integer?: The number of tags.
        local function getTags( wsid )
            local data = findAddon( wsid )
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

        --- Returns the tags of the addon.
        ---@return string[]?: The tags of the addon.
        function Addon:getTags()
            return getTags( self.wsid )
        end

        AddonClass.getTags = getTags

    end

end

do

    --- Returns the last time the addon was updated.
    ---@param wsid string: The workshop ID of the addon.
    ---@return integer?: The last time the addon was updated in UNIX time.
    local function getUpdateTime( wsid )
        local data = findAddon( wsid )
        if data == nil then return nil end
        return data.timeupdated
    end

    --- Returns the last time the addon was updated.
    ---@return integer?: The last time the addon was updated in UNIX time.
    function Addon:getUpdateTime()
        return getUpdateTime( self.wsid )
    end

    AddonClass.getUpdateTime = getUpdateTime

end

do

    --- Returns the creation time of the addon.
    ---@param wsid string: The workshop ID of the addon.
    ---@return integer?: The creation time of the addon in UNIX time.
    local function getCreationTime( wsid )
        local data = findAddon( wsid )
        if data == nil then return nil end
        return data.timecreated
    end

    --- Returns the creation time of the addon.
    ---@return integer?: The creation time of the addon in UNIX time.
    function Addon:getCreationTime()
        return getCreationTime( self.wsid )
    end

    AddonClass.getCreationTime = getCreationTime

end

do

    --- Returns the size of the addon.
    ---@param wsid string: The workshop ID of the addon.
    ---@return integer?: The size of the addon in bytes.
    local function getSize( wsid )
        local data = findAddon( wsid )
        if data == nil then return nil end
        return data.size
    end

    --- Returns the size of the addon.
    ---@return integer?: The size of the addon in bytes.
    function Addon:getSize()
        return getSize( self.wsid )
    end

    AddonClass.getSize = getSize

end

do

    local steamworks_ShouldMountAddon = steamworks.ShouldMountAddon

    function Addon:isShouldMount()
        return steamworks_ShouldMountAddon( self.wsid )
    end

    AddonClass.isShouldMount = steamworks_ShouldMountAddon

end

do

    local steamworks_SetShouldMountAddon = steamworks.SetShouldMountAddon

    function Addon:setShouldMount( shouldMount )
        steamworks_SetShouldMountAddon( self.wsid, shouldMount )
    end

    AddonClass.setShouldMount = steamworks_SetShouldMountAddon

end

do

    local steamworks_SetFilePlayed = steamworks.SetFilePlayed

    function Addon:markAsPlayed()
        steamworks_SetFilePlayed( self.wsid )
    end

    AddonClass.markAsPlayed = steamworks_SetFilePlayed

end

do

    local steamworks_SetFileCompleted = steamworks.SetFileCompleted

    function Addon:markAsCompleted()
        steamworks_SetFileCompleted( self.wsid )
    end

    AddonClass.markAsCompleted = steamworks_SetFileCompleted

end

do

    local steamworks_IsSubscribed = steamworks.IsSubscribed

    function Addon:isSubscribed()
        return steamworks_IsSubscribed( self.wsid )
    end

    AddonClass.isSubscribed = steamworks_IsSubscribed

end

do

    local steamworks_Subscribem, steamworks_Unsubscribe = steamworks.Subscribe, steamworks.Unsubscribe

    --- Subscribes or unsubscribes the addon.
    ---@param wsid string: The workshop ID of the addon.
    ---@param subscribed boolean: `true` to subscribe, `false` to unsubscribe.
    local function setSubscribed( wsid, subscribed )
        if subscribed then
            steamworks_Subscribem( wsid )
        else
            steamworks_Unsubscribe( wsid )
        end
    end

    --- Subscribes or unsubscribes the addon.
    ---@param subscribed boolean: `true` to subscribe, `false` to unsubscribe.
    function Addon:setSubscribed( subscribed )
        setSubscribed( self.wsid, subscribed )
    end

    AddonClass.setSubscribed = setSubscribed

end

do

    local steamworks_Vote = steamworks.Vote

    function Addon:vote( upOrDown )
        steamworks_Vote( self.wsid, upOrDown )
    end

    AddonClass.vote = steamworks_Vote

end

do

    local steamworks_ViewFile = steamworks.ViewFile

    function Addon:openWorkshopPage()
        steamworks_ViewFile( self.wsid )
    end

    Addon.openWorkshopPage = steamworks_ViewFile

end

do

    local steamworks_Download = steamworks.Download

    --- Downloads the icon of the addon.
    ---@param wsid string: The workshop ID of the addon.
    ---@param uncompress boolean?: Whether the icon should be uncompressed. Default is `true`.
    ---@return string: The absolute path to the icon file.
    ---@async
    local function downloadIcon( wsid, uncompress, timeout )
        if uncompress == nil then uncompress = true end
        local f = Future()

        steamworks_Download( wsid, uncompress, function( filePath )
            if is_string( filePath ) then
                ---@cast filePath string
                f:setResult( filePath )
            else
                f:setError( "failed to download icon file for '" .. wsid .. "', unknown error." )
            end
        end )

        timer_simple( timeout or 30, function()
            if f:isPending() then
                f:setError( "failed to download icon file for '" .. wsid .. "', timed out." )
            end
        end )

        return f:await()
    end

    ---@async
    function Addon:downloadIcon( uncompress )
        return downloadIcon( self.wsid, uncompress )
    end

    AddonClass.downloadIcon = downloadIcon

end

do

    local steamworks_DownloadUGC = steamworks.DownloadUGC
    local file_write = std.file.write

    --- Downloads the addon and returns the absolute path to the addon folder.
    ---@param wsid string: The workshop ID of the addon.
    ---@param timeout number | nil | false: The timeout in seconds. Set to `false` to disable the timeout.
    ---@return string: The absolute path to the addon folder.
    ---@async
    local function download( wsid, timeout )
        local f = Future()

        steamworks_DownloadUGC( wsid, function( filePath, file )
            if is_string( filePath ) then
                f:setResult( filePath )
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
            timer_simple( timeout or 30, function()
                if f:isPending() then
                    f:setError( "failed to download addon '" .. wsid .. "', timed out." )
                end
            end )
        end

        return f:await()
    end

    --- Downloads the addon from Steam Workshop and returns the absolute path to the `.gma` file.
    ---@param timeout number | nil | false: The timeout in seconds. Set to `false` to disable the timeout.
    ---@return string: The absolute path to the `.gma` file.
    ---@async
    function Addon:download( timeout )
        return download( self.wsid, timeout )
    end

    AddonClass.download = download

end

do

    local steamworks_FileInfo = steamworks.FileInfo
    local is_table = is.table

    --- Fetches the info of the addon from Steam Workshop.
    ---@param wsid string: The workshop ID of the addon.
    ---@param timeout number | nil | false: The timeout in seconds. Set to `false` to disable the timeout.
    ---@return UGCFileInfo
    ---@async
    local function fetchInfo( wsid, timeout )
        local f = Future()

        steamworks_FileInfo( wsid, function( info )
            if is_table( info ) then
                ---@cast info UGCFileInfo
                f:setResult( info )
            else
                f:setError( "failed to fetch info for addon '" .. wsid .. "', unknown error." )
            end
        end )

        if timeout ~= false then
            timer_simple( timeout or 30, function()
                if f:isPending() then
                    f:setError( "failed to fetch info for addon '" .. wsid .. "', timed out." )
                end
            end )
        end

        return f:await()
    end

    --- Fetches the info of the addon from Steam Workshop.
    ---@return UGCFileInfo
    ---@async
    function Addon:fetchInfo()
        return fetchInfo( self.wsid )
    end

    AddonClass.fetchInfo = fetchInfo

end

-- Addon presets stuff, I think an additional library/package will be needed in the future..
if std.MENU then

    local json_deserialize = std.crypto.json.deserialize
    local LoadAddonPresets = _G.LoadAddonPresets
    local hook_run = std.hook.run

    local function listAddonPresets()
        local json = LoadAddonPresets()
        if not json then return end

        local tbl = json_deserialize( json, true, true )
        if not tbl then return end

        -- GM:AddonPresetsLoaded( tbl )
        hook_run( "AddonPresetsLoaded", tbl )
    end

    local ListAddonPresets = _G.ListAddonPresets
    if is.fn( ListAddonPresets ) then
        _G.ListAddonPresets = gpm.detour.attach( _G.ListAddonPresets, function( fn )
            listAddonPresets()
            return fn()
        end )
    else
        _G.ListAddonPresets = listAddonPresets
    end

    AddonClass.getPresets = LoadAddonPresets
    AddonClass.setPresets = _G.SaveAddonPresets

end

do

    -- TODO: https://wiki.facepunch.com/gmod/steamworks.GetList
    -- https://github.com/search?q=repo%3AFacepunch%2Fgarrysmod+steamworks.GetList&type=code
    local steamworks_GetList = steamworks.GetList

    -- steamworks_GetList( "mine", {"addon"}, 0, 25, 0, "1", function( data )
    --     for i = 1, #data do
    --         print( i, AddonClass( data[ i ].wsid ) )
    --     end
    -- end )

    -- -- steamworks_GetList( "latest", {}, 0, 10, 365, "0", function( data )
    -- --     for i = 1, #data do

    -- --     end
    -- -- end )

    ---@async
    function AddonClass.getPopular()
        local f = Future()

        -- steamworks_GetList(
        --     "popular",
        --     {},
        -- )

        return f:await()
    end

    ---@async
    function AddonClass.getTrending()
        local f = Future()

        -- steamworks_GetList( "trending",  )


        return f:await()

    end

    ---@async
    function AddonClass.getRecent()
        local f = Future()

        -- steamworks_GetList( "latest",  )


        return f:await()
    end

    ---@async
    function AddonClass.getFavorite()
        local f = Future()

        -- steamworks_GetList( "favorite",  )


        return f:await()
    end

    ---@async
    function AddonClass.getFriends()
        local f = Future()

        -- steamworks_GetList( "friends", )


        return f:await()
    end

    ---@async
    function AddonClass.getFriendFavorite()

        -- steamworks_GetList( "friend_favs",  )


    end

    ---@async
    function AddonClass.getSubscribed()
        local f = Future()

        -- steamworks_GetList( "followed",  )


        return f:await()
    end

end

return AddonClass
