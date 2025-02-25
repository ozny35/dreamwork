local _G = _G
local std = _G.gpm.std
local glua_input, glua_gui, glua_vgui = _G.input, _G.gui, _G.vgui

---@class gpm.std.input
local input = {}

-- TODO: https://wiki.facepunch.com/gmod/input
-- TODO: https://wiki.facepunch.com/gmod/motionsensor
-- TODO: https://wiki.facepunch.com/gmod/gui
-- TODO: https://wiki.facepunch.com/gmod/input.SelectWeapon

do

    ---@clas gpm.std.input.cursor
    local cursor = {
        isVisible = glua_vgui.CursorVisible,
        setVisible = glua_gui.EnableScreenClicker or std.debug.fempty,
        isHoveringWorld = glua_vgui.IsHoveringWorld,
        getPosition = glua_input.GetCursorPos,
        setPosition = glua_input.SetCursorPos
    }

    input.cursor = cursor

end

do

    ---@clas gpm.std.input.keyboard
    local keyboard = {
        KEY_COUNT = 106
    }

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
        --- Get the name of a key.
        ---@param key integer The key code.
        ---@return string: The name of the key.
        function keyboard.getKeyName( key )
            return key2name[ key ] or "unknown"
        end

        local name2key = std.table.flip( key2name )

        --- [CLIENT AND MENU]
        --- Get the key code of a name.
        ---@param name string The name of the key.
        ---@return integer: The key code.
        ---@see keyboard.getKeyName
        function keyboard.getKeyCode( name )
            return name2key[ name ] or 0
        end

    end

    input.keyboard = keyboard

end

do

    ---@class gpm.std.input.controller
    local controller = {

    }

    input.controller = controller

end

return input
