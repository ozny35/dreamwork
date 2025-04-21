local _G = _G

local glua_gui = _G.gui
local glua_vgui = _G.vgui
local glua_input = _G.input

---@class gpm.std
local std = _G.gpm.std

--- [SHARED AND MENU]
---
--- The input library allows you to manipulate the client's input devices (mouse & keyboard), such as the cursor position and whether a key is pressed or not.
---@class gpm.std.input
local input = std.input or {}
std.input = input

if std.CLIENT_MENU then

    --- [CLIENT AND MENU]
    ---
    --- The cursor module allows you to manipulate the client's cursor.
    ---@clas gpm.std.input.cursor
    local cursor = input.cursor or {
        isVisible = glua_vgui.CursorVisible,
        setVisible = glua_gui.EnableScreenClicker or std.debug.fempty,
        isHoveringWorld = glua_vgui.IsHoveringWorld,
        getPosition = glua_input.GetCursorPos,
        setPosition = glua_input.SetCursorPos
    }

    input.cursor = cursor

end

if std.CLIENT_MENU then

    --- [CLIENT AND MENU]
    ---
    --- The clipboard module allows you to manipulate the client's clipboard.
    ---@class gpm.std.input.clipboard
    local clipboard = input.clipboard or {}
    input.clipboard = clipboard

    local clipboard_text = clipboard.getText and clipboard.getText() or ""

    --- [CLIENT AND MENU]
    ---
    --- Returns the contents of the clipboard.
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
    ---@param text string
    function clipboard.setText( text )
        ---@diagnostic disable-next-line: redundant-parameter
        SetClipboardText( text )
        clipboard_text = text
    end

    --- [CLIENT AND MENU]
    ---
    --- Adds text to the clipboard.
    ---@param text string
    function clipboard.addText( text )
        clipboard_text = clipboard_text .. text
        ---@diagnostic disable-next-line: redundant-parameter
        SetClipboardText( text )
    end

    --- [CLIENT AND MENU]
    ---
    --- Clears the clipboard.
    function clipboard.clear()
        clipboard_text = ""
        ---@diagnostic disable-next-line: redundant-parameter
        SetClipboardText( clipboard_text )
    end

end

if std.CLIENT_MENU then

    --- [CLIENT AND MENU]
    ---
    --- The key module allows you to manipulate the client's keys.
    ---@class gpm.std.input.key
    local key = input.key or {
        KEY_COUNT = 106
    }

    input.key = key

    do

        local input_StartKeyTrapping = glua_input.StartKeyTrapping
        local input_CheckKeyTrapping = glua_input.CheckKeyTrapping
        local input_IsKeyTrapping = glua_input.IsKeyTrapping
        local futures_yield = std.futures.yield

        --- [CLIENT AND MENU]
        ---
        --- Starts a key capture and returns the key code of the key that was pressed.
        ---
        --- The captured key will not be pressed and committed to the game engine.
        ---@return integer key_code The key code of the key that was pressed.
        ---@async
        function key.capture()
            input_StartKeyTrapping()

            while input_IsKeyTrapping() do
                futures_yield( input_CheckKeyTrapping() )
            end

            return -1
        end

    end

    do

        local key2name = {
            [ 0 ] = "KEY_NONE",
            [ 1 ] = "KEY_ZERO",
            [ 2 ] = "KEY_ONE",
            [ 3 ] = "KEY_TWO",
            [ 4 ] = "KEY_THREE",
            [ 5 ] = "KEY_FOUR",
            [ 6 ] = "KEY_FIVE",
            [ 7 ] = "KEY_SIX",
            [ 8 ] = "KEY_SEVEN",
            [ 9 ] = "KEY_EIGHT",
            [ 10 ] = "KEY_NINE",
            [ 11 ] = "KEY_A",
            [ 12 ] = "KEY_B",
            [ 13 ] = "KEY_C",
            [ 14 ] = "KEY_D",
            [ 15 ] = "KEY_E",
            [ 16 ] = "KEY_F",
            [ 17 ] = "KEY_G",
            [ 18 ] = "KEY_H",
            [ 19 ] = "KEY_I",
            [ 20 ] = "KEY_J",
            [ 21 ] = "KEY_K",
            [ 22 ] = "KEY_L",
            [ 23 ] = "KEY_M",
            [ 24 ] = "KEY_N",
            [ 25 ] = "KEY_O",
            [ 26 ] = "KEY_P",
            [ 27 ] = "KEY_Q",
            [ 28 ] = "KEY_R",
            [ 29 ] = "KEY_S",
            [ 30 ] = "KEY_T",
            [ 31 ] = "KEY_U",
            [ 32 ] = "KEY_V",
            [ 33 ] = "KEY_W",
            [ 34 ] = "KEY_X",
            [ 35 ] = "KEY_Y",
            [ 36 ] = "KEY_Z",
            [ 37 ] = "KEY_PAD_0",
            [ 38 ] = "KEY_PAD_1",
            [ 39 ] = "KEY_PAD_2",
            [ 40 ] = "KEY_PAD_3",
            [ 41 ] = "KEY_PAD_4",
            [ 42 ] = "KEY_PAD_5",
            [ 43 ] = "KEY_PAD_6",
            [ 44 ] = "KEY_PAD_7",
            [ 45 ] = "KEY_PAD_8",
            [ 46 ] = "KEY_PAD_9",
            [ 47 ] = "KEY_PAD_DIVIDE",
            [ 48 ] = "KEY_PAD_MULTIPLY",
            [ 49 ] = "KEY_PAD_MINUS",
            [ 50 ] = "KEY_PAD_PLUS",
            [ 51 ] = "KEY_PAD_ENTER",
            [ 52 ] = "KEY_PAD_DECIMAL",
            [ 53 ] = "KEY_LEFT_BRACKET",
            [ 54 ] = "KEY_RIGHT_BRACKET",
            [ 55 ] = "KEY_SEMICOLON",
            [ 56 ] = "KEY_APOSTROPHE",
            [ 57 ] = "KEY_BACKQUOTE",
            [ 58 ] = "KEY_COMMA",
            [ 59 ] = "KEY_PERIOD",
            [ 60 ] = "KEY_SLASH",
            [ 61 ] = "KEY_BACKSLASH",
            [ 62 ] = "KEY_MINUS",
            [ 63 ] = "KEY_EQUAL",
            [ 64 ] = "KEY_ENTER",
            [ 65 ] = "KEY_SPACE",
            [ 66 ] = "KEY_BACKSPACE",
            [ 67 ] = "KEY_TAB",
            [ 68 ] = "KEY_CAPS_LOCK",
            [ 69 ] = "KEY_NUM_LOCK",
            [ 70 ] = "KEY_ESCAPE",
            [ 71 ] = "KEY_SCROLL_LOCK",
            [ 72 ] = "KEY_INSERT",
            [ 73 ] = "KEY_DELETE",
            [ 74 ] = "KEY_HOME",
            [ 75 ] = "KEY_END",
            [ 76 ] = "KEY_PAGEUP",
            [ 77 ] = "KEY_PAGEDOWN",
            [ 78 ] = "KEY_BREAK",
            [ 79 ] = "KEY_LEFT_SHIFT",
            [ 80 ] = "KEY_RIGHT_SHIFT",
            [ 81 ] = "KEY_LEFT_ALT",
            [ 82 ] = "KEY_RIGHT_ALT",
            [ 83 ] = "KEY_LEFT_CTRL",
            [ 84 ] = "KEY_RIGHT_CTRL",
            [ 85 ] = "KEY_LEFT_COMMAND",
            [ 86 ] = "KEY_RIGHT_COMMAND",
            [ 87 ] = "KEY_APP",
            [ 88 ] = "KEY_UP",
            [ 89 ] = "KEY_LEFT",
            [ 90 ] = "KEY_DOWN",
            [ 91 ] = "KEY_RIGHT",
            [ 92 ] = "KEY_F1",
            [ 93 ] = "KEY_F2",
            [ 94 ] = "KEY_F3",
            [ 95 ] = "KEY_F4",
            [ 96 ] = "KEY_F5",
            [ 97 ] = "KEY_F6",
            [ 98 ] = "KEY_F7",
            [ 99 ] = "KEY_F8",
            [ 100 ] = "KEY_F9",
            [ 101 ] = "KEY_F10",
            [ 102 ] = "KEY_F11",
            [ 103 ] = "KEY_F12",
            [ 104 ] = "KEY_CAPS_LOCK_TOGGLE",
            [ 105 ] = "KEY_NUM_LOCK_TOGGLE",
            [ 106 ] = "KEY_SCROLL_LOCK_TOGGLE"
        }

        --- [CLIENT AND MENU]
        ---
        --- Get the name of a key.
        ---@param key_code integer The key code of the key.
        ---@return string: The name of the key.
        function key.getName( key_code )
            return key2name[ key_code ] or "unknown"
        end

        local name2key = std.table.flipped( key2name )

        --- [CLIENT AND MENU]
        ---
        --- Get the key code of a name.
        ---@param name string The name of the key.
        ---@return integer key_code The key code of the key.
        ---@see key.getName as a reverse lookup
        function key.getCode( name )
            return name2key[ name ] or 0
        end

    end

end

if std.CLIENT_MENU then

    --- [CLIENT AND MENU]
    ---
    --- The controller module allows you to manipulate the client's controllers.
    ---@class gpm.std.input.controller
    local controller = input.controller or {

    }

    input.controller = controller

end

if std.CLIENT then

    local console = std.console
    local Command_run = console.Command.run

    --- [CLIENT]
    ---
    --- The weapon module allows you to manipulate the client's weapons.
    ---@class gpm.std.input.weapon
    local weapon = input.weapon or {
        select = glua_input.SelectWeapon
    }

    input.weapon = weapon

    --- [CLIENT]
    ---
    --- Selects the previously selected weapon.
    ---
    --- Instantly sets the player's past weapons as active.
    function weapon.last()
        return Command_run( "lastinv" )
    end

    --- [CLIENT]
    ---
    --- Selects the next weapon in the inventory.
    ---
    --- Weapons will most likely not be selected immediately because often players do not use `hud_fastswitch`, so they will just have their inventory with the selected weapon displayed in the next slot.
    function weapon.next()
        return Command_run( "invnext" )
    end

    --- [CLIENT]
    ---
    --- Selects the previous weapon in the inventory.
    ---
    --- Weapons will most likely not be selected immediately because often players do not use `hud_fastswitch`, so they will just have their inventory with the selected weapon displayed in the next slot.
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
    ---@class gpm.std.input.kinect
    local kinect = input.kinect or {}
    input.kinect = kinect

    -- TODO: gmcl_rekinect support ( net library required )

    if std.CLIENT and std.loadbinary( "rekinect" ) then
    end

end

-- TODO: https://wiki.facepunch.com/gmod/input
-- TODO: https://wiki.facepunch.com/gmod/motionsensor
-- TODO: https://wiki.facepunch.com/gmod/gui
