local _G = _G

---@class gpm
local gpm = _G.gpm
local std = gpm.std

local os_time = std.os.time
local error = std.error

local sqlite = std.sqlite
local sqlite_queryOne, sqlite_queryValue, sqlite_rawQuery, sqlite_query, sqlite_transaction = sqlite.queryOne, sqlite.queryValue, sqlite.rawQuery, sqlite.query, sqlite.transaction

local is_string, is_number, is_table
do
    local is = std.is
    is_string, is_number, is_table = is.string, is.number, is.table
end

-- http_cache table, used for etag caching in http library
do

    local string_len, string_find
    do
        local string = std.string
        string_len, string_find = string.len, string.find
    end

    ---@class gpm.http_cache
    ---@field MAX_SIZE number: The maximum size of cached content.
    local http_cache = {}

    --- Gets the cached content for the specified URL.
    ---@param url string
    ---@return table?
    function http_cache.get( url )
        return sqlite_queryOne( "select etag, content from 'gpm.http_cache' where url=? limit 1", url )
    end

    local MAX_SIZE = 50 * 1024
    http_cache.MAX_SIZE = MAX_SIZE

    function http_cache.set( url, etag, content )
        -- do not cache content that are larger than MAX_SIZE
        if string_len( content ) > MAX_SIZE then
            return
        end

        -- we are unable to store null bytes in sqlite
        if string_find( content, "\x00", 1, true ) then
            return
        end

        sqlite_query( "insert or replace into 'gpm.http_cache' (url, etag, timestamp, content) values (?, ?, ?, ?)", url, etag, os_time(), content )
    end

    gpm.http_cache = http_cache

end

-- key-value store for gpm
do

    ---@class gpm.store
    local store = {}

    --- Returns the value for the specified key.
    ---@param key string
    ---@return string
    function store.get( key )
        return sqlite_queryValue( "select value from 'gpm.store' where key=?", key )
    end

    --- Sets the value for the specified key.
    ---@param key string
    ---@param value string
    function store.set( key, value )
        sqlite_query( "insert or replace into 'gpm.store' values (?, ?)", key, value )
    end

    gpm.store = store

end

--- repositories
if std.SERVER then

    ---@class gpm.repositories
    local repositories = {}

    ---@return table: all saved repositories
    function repositories.getRepositories()
        return sqlite_query( "select * from 'gpm.repositories'" ) or {}
    end

    function repositories.addRepository( url )
        -- sadly gmod's sqlite does not support returning clause :(
        return sqlite_queryOne( "insert or ignore into 'gpm.repositories' (url) values (?); select * from 'gpm.repositories' where url=?", url, url )
    end

    ---@param value table | number | string
    ---@return number?
    local function getRepositoryId( value )
        if is_table( value ) then
            ---@cast value table
            return value.id or getRepositoryId( value.url )
        elseif is_number( value ) then
            ---@cast value number
            return value
        elseif is_string( value ) then
            ---@cast value string
            return sqlite_queryValue( "select id from 'gpm.repositories' where url=?", value )
        end
    end

    function repositories.removeRepository( repository )
        local repositoryId = getRepositoryId( repository )
        if repositoryId == nil then
            error( "invalid repository '" .. tostring( repository ) .. "' was given as #1 argument" )
        end

        local repositoryIdStr = tostring( repositoryId )
        repositoryId = nil
        repository = nil

        sqlite_transaction( function()
            -- delete all versions, packages and repository
            local packages = sqlite_query( "select id from 'gpm.packages' where repositoryId=?", repositoryIdStr )
            if packages == nil then return end

            for i = 1, #packages do
                local packageId = packages[ i ].id
                sqlite_query( "delete from 'gpm.package_versions' where packageId=?; delete from 'gpm.packages' where id=?", packageId, packageId )
            end

            sqlite_query( "delete from 'gpm.repositories' where id=?", repositoryIdStr )
        end )
    end

    function repositories.getPackage( repository, name )
        local repositoryId = getRepositoryId( repository )
        if repositoryId == nil then
            error( "invalid repository '" .. tostring( repository ) .. "' was given as #1 argument" )
        end

        repository = nil

        local pkg = sqlite_queryOne( "select * from 'gpm.packages' where name=? and repositoryId=?", name, tostring( repositoryId ) )
        if pkg == nil then return end
        repositoryId = nil

        pkg.versions = sqlite_query( "select version, metadata from 'gpm.package_versions' where packageId=?", pkg.id )
        return pkg
    end

    function repositories.getPackages( repository )
        local repositoryId = getRepositoryId( repository )
        if repositoryId == nil then
            error( "invalid repository '" .. tostring( repository ) .. "' was given as #1 argument" )
        end

        repository = nil

        local packages = sqlite_query( "select * from 'gpm.packages' where repositoryId=?", tostring( repositoryId ) )
        repositoryId = nil

        if packages == nil then
            return {}
        end

        -- fetch versions for each package
        for i = 1, #packages do
            local pkg = packages[ i ]
            pkg.versions = sqlite_query( "select version, metadata from 'gpm.package_versions' where packageId=?", pkg.id )
        end

        return packages
    end

    function repositories.updateRepository( repository, packages )
        local repositoryId = getRepositoryId( repository )
        if repositoryId == nil then
            error( "invalid repository '" .. tostring( repository ) .. "' was given as #1 argument" )
        end

        local repositoryIdStr = tostring( repositoryId )
        repositoryId = nil
        repository = nil

        local oldPackages = sqlite_query( "select id, name from 'gpm.packages' where repositoryId=?", repositoryIdStr ) or {}
        for i = 1, #oldPackages do
            local package = oldPackages[ i ]
            oldPackages[ package.name ] = package.id
        end

        return sqlite_transaction( function()
            for name, pkg in pairs( packages ) do
                sqlite_query( "insert or replace into 'gpm.packages' (name, url, type, repositoryId) values (?, ?, ?, ?)", pkg.name, pkg.url, pkg.type, repositoryIdStr )

                local packageId = sqlite_queryValue( "select id from 'gpm.packages' where name=? and repositoryId=?", pkg.name, repositoryIdStr )
                sqlite_query( "delete from 'gpm.package_versions' where packageId=?", packageId )

                local versions = pkg.versions
                for i = 1, #versions do
                    local package = versions[ i ]
                    sqlite_query( "insert into 'gpm.package_versions' (version, metadata, packageId) values (?, ?, ?)", package.version, package.metadata, packageId )
                end

                oldPackages[ name ] = nil
            end

            -- remove old packages
            for _, id in pairs( oldPackages ) do
                sqlite_query( "delete from 'gpm.package_versions' where packageId=?; delete from 'gpm.packages' where id=?", id, id )
            end
        end )
    end

    gpm.repositories = repositories

end

-- files
do

    local tonumber = std.tonumber

    ---@class gpm.files
    local files = {}

    function files.save( path, size, seconds, hash )
        sqlite_query( "insert or replace into 'gpm.files' (path, size, os_time, hash) values (?, ?, ?, ?)", path, size, seconds, hash )
    end

    function files.get( path )
        local result = sqlite_queryOne( "select * from 'gpm.files' where path=?", path )
        if result == nil then return end

        result.size = tonumber( result.size, 10 ) or -1
        result.os_time = tonumber( result.os_time, 10 )
        return result
    end

    gpm.files = files

end

-- optimize sqlite database
---@private
if _G.sql.__patched == nil then
    _G.sql.__patched = true

    local pragma_values = sqlite_rawQuery( "pragma foreign_keys; pragma journal_mode; pragma synchronous; pragma wal_autocheckpoint" )
    if pragma_values ~= nil then
        if pragma_values[ 1 ]["foreign_keys"] == "0" then
            sqlite_rawQuery( "pragma foreign_keys = 1" )
        end

        if pragma_values[ 2 ]["journal_mode"] == "delete" then
            sqlite_rawQuery( "pragma journal_mode = wal" )
        end

        if pragma_values[ 3 ]["synchronous"] == "0" then
            sqlite_rawQuery( "pragma synchronous = normal" )
        end

        if pragma_values[ 4 ]["wal_autocheckpoint"] == "1000" then
            sqlite_rawQuery( "pragma wal_autocheckpoint = 100" )
        end
    end
end

-- truncate WAL journal on shutdown
_G.hook.Add( "ShutDown", gpm.PREFIX .. "::SQLite", function()
    if sqlite.query( "pragma wal_checkpoint(TRUNCATE)" ) == false then
        gpm.Logger:Error( "Failed to truncate WAL journal: %s", sqlite.getLastError() )
    end
end )

local migrations = {
    {
        name = "initial",
        execute = function() end
    },
    {
        name = "http_cache add primary key",
        execute = function()
            sqlite_rawQuery("drop table if exists 'gpm.http_cache'")
            sqlite_rawQuery([[create table 'gpm.http_cache' (
                url text primary key,
                etag text,
                timestamp int,
                content blob
            )]])
            return nil
        end
    },
    {
        name = "added key-value store",
        execute = function()
            sqlite_rawQuery("create table 'gpm.store' ( key text unique, value text )")
            return nil
        end
    },
    {
        name = "initial repositories and packages",
        execute = function()
            sqlite_rawQuery( "drop table if exists 'gpm.table_version'" )
            sqlite_rawQuery( "drop table if exists 'gpm.repository'" )
            sqlite_rawQuery( "drop table if exists 'gpm.packages'" )

            if std.SERVER then
                sqlite_rawQuery( "create table 'gpm.repositories' ( id integer primary key autoincrement, url text unique not null )" )
                sqlite_rawQuery( [[
                    create table 'gpm.packages' (
                        id integer primary key autoincrement,
                        name text not null,
                        url text not null,
                        type int not null,
                        repositoryId integer,

                        foreign key(repositoryId) references 'gpm.repositories' (id)
                        unique(name, repositoryId) on conflict replace
                    )
                ]] )

                sqlite_rawQuery( [[
                    create table 'gpm.package_versions' (
                        version text not null,
                        metadata text,
                        packageId integer not null,

                        foreign key(packageId) references 'gpm.packages' (id)
                        unique(version, packageId) on conflict replace
                    )
                ]] )
            end
        end
    },
    {
        name = "initial file table",
        execute = function()
            sqlite_rawQuery( [[
                create table 'gpm.files' (
                    id integer primary key autoincrement,
                    path text not null unique,
                    size integer not null,
                    os_time number,
                    hash text
                )
            ]] )
        end
    }
}

do

    ---@class gpm.db
    local db = {}

    sqlite_rawQuery( "create table if not exists 'gpm.migration_history' (name text, timestamp integer)" )

    --- Checks if a migration exists and returns `true` or `false`.
    ---@param name string: The name of the migration.
    ---@return boolean: `true` if migration exists, `false` otherwise.
    local function migrationExists( name )
        for i = 1, #migrations do
            if migrations[ i ].name == name then
                return true
            end
        end

        return false
    end

    db.migrationExists = migrationExists

    -- TODO: ls desc
    local function runMigration( migration )
        -- if not isfunction( migration.execute ) then
        --     error( "Migration '" .. tostring( migration.name ) .. "' does not have an execute function" )
        -- end

        gpm.Logger:Info( "Running migration '" .. tostring( migration.name ) .. "'...")

        if xpcall( sqlite_transaction, _G.ErrorNoHaltWithStack, migration.execute ) then
            sqlite_query( "insert into 'gpm.migration_history' (name, timestamp) values (?, ?)", migration.name, os_time() )
            return true
        else
            return false
        end
    end

    db.runMigration = runMigration

    ---
    ---@param name string
    function db.migrate( name )
        local history = sqlite_rawQuery( "select name from 'gpm.migration_history'" ) or {}
        for i = 1, #history do
            history[ history[ i ].name ] = true
        end

        -- find if given migration name exists
        if not migrationExists( name ) then
            error( "Migration '" .. name .. "' not found", 2 )
        end

        -- first execute migrations
        for i = 1, #migrations do
            local migration = migrations[ i ]
            if ( not history[ migration.name ] and runMigration( migration ) == false ) or ( migration.name == name ) then
                break
            end
        end
    end

    gpm.db = db

end
