local _G = _G

local gpm = _G.gpm
local glua_gui = _G.gui
local glua_vgui = _G.vgui
local glua_input = _G.input

---@class gpm.std
local std = gpm.std
local Command_run = std.console.Command.run

--- [SHARED AND MENU]
---
--- The input library allows you to
--- manipulate the client's input devices
--- (mouse & keyboard), such as the cursor
--- position and whether a key is pressed or not.
---
---@class gpm.std.input
local input = std.input or {}
std.input = input

if std.CLIENT_MENU then

    -- TODO: use ANALOG somewhere

    -- -- https://wiki.facepunch.com/gmod/Enums/ANALOG
    -- std.ANALOG = {
    --     MOUSE_X = 0,
    --     MOUSE_Y = 1,
    --     MOUSE_WHEEL = 3,
    --     JOY_X = 4,
    --     JOY_Y = 5,
    --     JOY_Z = 6,
    --     JOY_R = 7,
    --     JOY_U = 8,
    --     JOY_V = 9
    -- }

    do

        --- [CLIENT AND MENU]
        ---
        --- The cursor module allows you to manipulate the client's cursor.
        ---
        ---@clas gpm.std.input.cursor
        local cursor = input.cursor or {}
        input.cursor = cursor

        cursor.isVisible = cursor.isVisible or glua_vgui.CursorVisible
        cursor.setVisible = cursor.setVisible or glua_gui.EnableScreenClicker or std.debug.fempty

        cursor.isHoveringWorld = cursor.isHoveringWorld or glua_vgui.IsHoveringWorld

        cursor.getPosition = cursor.getPosition or glua_input.GetCursorPos
        cursor.setPosition = cursor.setPosition or glua_input.SetCursorPos

    end

    do

        --- [CLIENT AND MENU]
        ---
        --- The clipboard module allows you to manipulate the client's clipboard.
        ---
        ---@class gpm.std.input.clipboard
        local clipboard = input.clipboard or {}
        input.clipboard = clipboard

        local clipboard_text = clipboard.getText and clipboard.getText() or ""

        --- [CLIENT AND MENU]
        ---
        --- Returns the contents of the clipboard.
        ---
        ---@return string
        function clipboard.getText()
            return clipboard_text
        end

        local SetClipboardText = _G.SetClipboardText
        if SetClipboardText == nil then
            SetClipboardText = std.debug.fempty
        end

        --- [CLIENT AND MENU]
        ---
        --- Sets the contents of the clipboard.
        ---
        ---@param text string
        function clipboard.setText( text )
            ---@diagnostic disable-next-line: redundant-parameter
            SetClipboardText( text )
            clipboard_text = text
        end

        --- [CLIENT AND MENU]
        ---
        --- Adds text to the clipboard.
        ---
        ---@param text string
        function clipboard.addText( text )
            clipboard_text = clipboard_text .. text
            ---@diagnostic disable-next-line: redundant-parameter
            SetClipboardText( text )
        end

        --- [CLIENT AND MENU]
        ---
        --- Clears the clipboard.
        ---
        function clipboard.clear()
            clipboard_text = ""
            ---@diagnostic disable-next-line: redundant-parameter
            SetClipboardText( clipboard_text )
        end

    end

    do

        --- [CLIENT AND MENU]
        ---
        --- The key module allows you to manipulate the client's keys.
        ---
        ---@class gpm.std.input.key
        ---@field count integer The number of keys.
        local key = input.key or { count = 106 }
        input.key = key

        -- https://wiki.facepunch.com/gmod/input.IsKeyDown ?? whats a difference
        key.isDown = key.isDown or glua_input.IsButtonDown

        do

            local input_StartKeyTrapping = glua_input.StartKeyTrapping
            local input_CheckKeyTrapping = glua_input.CheckKeyTrapping
            local input_IsKeyTrapping = glua_input.IsKeyTrapping
            local Future = std.Future

            local captures = std.Stack()

            gpm.engine.hookCatch( "Tick", function()
                if captures:isEmpty() then return end

                if not input_IsKeyTrapping() then
                    input_StartKeyTrapping()
                end

                local key_code = input_CheckKeyTrapping()
                if key_code == nil then return end

                captures:pop():setResult( key_code )
            end )

            --- [CLIENT AND MENU]
            ---
            --- Starts a key capture and returns the key code of the key that was pressed.
            ---
            --- The captured key will not be pressed and committed to the game engine.
            ---
            ---@return integer key_code The key code of the key that was pressed.
            ---@async
            function key.capture()
                local f = Future()
                captures:push( f )
                return f:await()
            end

        end

        do

            local key2name = {}

            do

                local input_GetKeyName = glua_input.GetKeyName

                std.setmetatable( key2name, {
                    __index = function( _, key_code )
                        local key_name = input_GetKeyName( key_code )
                        if key_name == nil then return "unknown" end
                        key2name[ key_code ] = key_name
                        return key_name
                    end
                } )

            end

            --- [CLIENT AND MENU]
            ---
            --- Get the name of a key.
            ---
            ---@param key_code integer The key code of the key.
            ---@return string: The name of the key.
            function key.getName( key_code )
                return key2name[ key_code ]
            end

            local name2key = {}

            do

                local input_GetKeyCode = glua_input.GetKeyCode

                std.setmetatable( name2key, {
                    __index = function( _, key_name )
                        local key_code = input_GetKeyCode( key_name )
                        if key_code == nil then return 0 end
                        name2key[ key_name ] = key_code
                        return key_code
                    end
                } )

            end

            --- [CLIENT AND MENU]
            ---
            --- Get the key code of a name.
            ---
            ---@param name string The name of the key.
            ---@return integer key_code The key code of the key.
            ---@see key.getName as a reverse lookup
            function key.getCode( name )
                return name2key[ name ]
            end

        end

    end

    do

        --- [CLIENT AND MENU]
        ---
        --- The bind module allows you to manipulate the client's binds.
        ---
        ---@class gpm.std.input.binding
        local binding = input.binding or {}
        input.binding = binding

        binding.key = binding.key or glua_input.LookupBinding
        binding.get = binding.get or glua_input.LookupKeyBinding

        if std.MENU then

            local table_concat = std.table.concat
            local key_getName = input.key.getName

            --- [MENU]
            ---
            --- Sets the bind of a key.
            ---
            ---@param key_code integer
            ---@param ... string
            function binding.set( key_code, ... )
                Command_run( "bind", key_getName( key_code ), "'" .. table_concat( { ... }, ";" ) .. "'" )
            end

        end

    end

    do

        --- [CLIENT AND MENU]
        ---
        --- The controller module allows you to manipulate the client's controllers.
        ---
        ---@class gpm.std.input.controller
        local controller = input.controller or {}
        input.controller = controller

    end

end

if std.CLIENT then

    --- [CLIENT]
    ---
    --- The weapon module allows you to manipulate the client's weapons.
    ---
    ---@class gpm.std.input.weapon
    local weapon = input.weapon or {}
    input.weapon = weapon

    weapon.select = weapon.select or glua_input.SelectWeapon

    --- [CLIENT]
    ---
    --- Selects the previously selected weapon.
    ---
    --- Instantly sets the player's past weapons as active.
    ---
    function weapon.last()
        return Command_run( "lastinv" )
    end

    --- [CLIENT]
    ---
    --- Selects the next weapon in the inventory.
    ---
    --- Weapons will most likely not be selected immediately because often players do not use `hud_fastswitch`, so they will just have their inventory with the selected weapon displayed in the next slot.
    ---
    function weapon.next()
        return Command_run( "invnext" )
    end

    --- [CLIENT]
    ---
    --- Selects the previous weapon in the inventory.
    ---
    --- Weapons will most likely not be selected immediately because often players do not use `hud_fastswitch`, so they will just have their inventory with the selected weapon displayed in the next slot.
    ---
    function weapon.previous()
        return Command_run( "invprev" )
    end

end

if std.CLIENT_SERVER then

    --- [CLIENT AND SERVER]
    ---
    --- The kinect module allows you to manipulate the client's kinect.
    ---
    --- Highly recommended to use with https://github.com/WilliamVenner/gmcl_rekinect
    ---
    ---@class gpm.std.input.kinect
    local kinect = input.kinect or {}
    input.kinect = kinect

    if std.CLIENT then
        local available
        if std.loadbinary( "rekinect" ) then
            gpm.Logger:info( "'rekinect' was connected as KinectAPI." )
            available = true
        elseif motionsensor ~= nil then
            gpm.Logger:info( "'Garry's Mod' was connected as KinectAPI." )
            available = true
        else
            gpm.Logger:warn( "KinectAPI was not connected." )
        end

        if available and motionsensor.IsAvailable() then
            gpm.Logger:info( "Supported Kinect sensor was detected." )
        end
    end

    -- TODO: gmcl_rekinect support ( net library required )

end

-- TODO: https://wiki.facepunch.com/gmod/input
-- TODO: https://wiki.facepunch.com/gmod/motionsensor
-- TODO: https://wiki.facepunch.com/gmod/gui
