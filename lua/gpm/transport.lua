---@class gpm
local gpm = _G.gpm
local std = gpm.std

-- TODO: add docs and think about async support/compatibility
-- TODO: add hooks

---@class gpm.transport
local transport = gpm.transport or {}
gpm.transport = transport

local console_Variable = std.console.Variable
local path = std.file.path
local table = std.table

local selected_transport = console_Variable( {
    name = "gpm.transport",
    description = "The name of the internal transport that will be used to send lua files to the client.",
    default = "legacy",
    replicated = true,
    archive = true,
    type = "string"
} )

local files = transport.files or {}
transport.files = files

local table_remove = table.remove
local path_equals = path.equals

local function transport_delFile( file_path )
    for i = #files, 1, -1 do
        if path_equals( files[ i ][ 1 ], file_path ) then
            table_remove( files, i )
            break
        end
    end
end

transport.delFile = transport_delFile

function transport.addFile( file_path, content )
    transport_delFile( file_path )
    files[ #files + 1 ] = { file_path, content }
end

local senders = {}

function transport.register( name, fn )
    senders[ name ] = fn
end

function transport.startup()
    local name = selected_transport.value
    local fn = senders[ name ]

    if fn == nil then
        local default_name = selected_transport.default
        if name == default_name then
            gpm.Logger:error( "Transport '" .. name .. "' failed to start." )
            return
        end

        gpm.Logger:warn( "Could not find transport named '" .. name .. "', falling back to '" .. default_name .. "'." )
        selected_transport:revert()
        transport.startup()
        return
    end

    local success, err_msg = std.pcall( fn )
    if success then
        gpm.Logger:info( "Transport '" .. name .. "' started, ready to send files to the client." )
        return
    end

    if name == selected_transport.default then
        gpm.Logger:error( "Transport '" .. name .. "' failed to start." )
        return
    end

    gpm.Logger:warn( "Transport '" .. name .. "' failed to start: " .. err_msg )
    selected_transport:revert()
    transport.startup()
end
