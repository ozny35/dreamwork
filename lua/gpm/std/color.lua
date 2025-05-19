local _G = _G

---@class gpm.std
local std = _G.gpm.std

local math, string, bit = std.math, std.string, std.bit
local isnumber, setmetatable = std.isnumber, std.setmetatable
local math_abs, math_min, math_max, math_floor = math.abs, math.min, math.max, math.floor
local string_char, string_byte, string_format, string_len = string.char, string.byte, string.format, string.len

local DIV255_CONST = 1 / 255

--- [SHARED AND MENU]
---
--- The color object.
---
---@class gpm.std.Color : gpm.std.Object
---@field __class gpm.std.ColorClass
---@field r integer A red channel of the color. [0, 255].
---@field g integer A green channel of the color. [0, 255].
---@field b integer A blue channel of the color. [0, 255].
---@field a integer An alpha channel of the color. [0, 255].
---@operator add(gpm.std.Color): gpm.std.Color
---@operator sub(gpm.std.Color): gpm.std.Color
---@operator mul(gpm.std.Color | integer): gpm.std.Color
---@operator div(gpm.std.Color | integer): gpm.std.Color
---@operator unm(): gpm.std.Color
local Color = std.Color and std.Color.__base or std.class.base( "Color" )

---@diagnostic disable-next-line: duplicate-doc-alias
---@alias Color gpm.std.Color

--- [SHARED AND MENU]
---
--- The color class.
---
---@class gpm.std.ColorClass : gpm.std.Color
---@field __base gpm.std.Color
---@overload fun( r: integer?, g: integer?, b: integer?, a: integer? ): gpm.std.Color
local ColorClass = std.Color or std.class.create( Color )
std.Color = ColorClass

--- [SHARED AND MENU]
---
--- Creates a color object from RGBA values.
---
---@param r integer? The 8-bit red channel.
---@param g integer? The 8-bit green channel.
---@param b integer? The 8-bit blue channel.
---@param a integer? The 8-bit alpha channel.
---@return gpm.std.Color color The color object.
local function from_rgba( r, g, b, a )
    r = r and math_min( math_max( r, 0 ), 255 ) or 0

    return setmetatable( {
        r = r,
        g = g and math_min( math_max( g, 0 ), 255 ) or r,
        b = b and math_min( math_max( b, 0 ), 255 ) or r,
        a = a and math_min( math_max( a, 0 ), 255 ) or 255
    }, Color )
end

ColorClass.fromRGBA = from_rgba

---@protected
---@param r integer? The 8-bit red channel.
---@param g integer? The 8-bit green channel.
---@param b integer? The 8-bit blue channel.
---@param a integer? The 8-bit alpha channel.
---@return gpm.std.Color color The color object.
function Color:__new( r, g, b, a )
    return from_rgba( r, g, b, a )
end

---@protected
function Color:__tostring()
    return string_format( "Color: %p [%d, %d, %d, %d]", self, self.r, self.g, self.b, self.a )
end

---@param other gpm.std.Color
---@protected
function Color:__eq( other )
    return self.r == other.r and self.g == other.g and self.b == other.b and self.a == other.a
end

---@protected
function Color:__unm()
    return from_rgba(
        math_abs( 255 - self.r ),
        math_abs( 255 - self.g ),
        math_abs( 255 - self.b ),
        self.a
    )
end

--- [SHARED AND MENU]
---
--- Inverts current color.
---
---@return gpm.std.Color color The color object.
function Color:invert()
    self.r = math_min( math_max( math_abs( 255 - self.r ), 0 ), 255 )
    self.g = math_min( math_max( math_abs( 255 - self.g ), 0 ), 255 )
    self.b = math_min( math_max( math_abs( 255 - self.b ), 0 ), 255 )
    return self
end

---@param color gpm.std.Color
---@protected
function Color:__add( color )
    return from_rgba(
        self.r + color.r,
        self.g + color.g,
        self.b + color.b,
        self.a
    )
end

---@param color gpm.std.Color
---@protected
function Color:__sub( color )
    return from_rgba(
        self.r - color.r,
        self.g - color.g,
        self.b - color.b,
        self.a
    )
end

---@param other gpm.std.Color | integer
---@protected
function Color:__mul( other )
    if isnumber( other ) then
        ---@cast other integer
        return from_rgba(
            self.r * other,
            self.g * other,
            self.b * other,
            self.a
        )
    end

    ---@cast other gpm.std.Color
    return from_rgba(
        self.r * other.r,
        self.g * other.g,
        self.b * other.b,
        self.a
    )
end

---@param other gpm.std.Color | integer
---@protected
function Color:__div( other )
    if isnumber( other ) then
        ---@cast other integer
        local multiplier = 1 / other
        return from_rgba(
            self.r * multiplier,
            self.g * multiplier,
            self.b * multiplier,
            self.a
        )
    end

    ---@cast other gpm.std.Color
    return from_rgba(
        self.r / other.r,
        self.g / other.g,
        self.b / other.b,
        self.a
    )
end

---@param other gpm.std.Color
---@protected
function Color:__lt( other )
    return ( self.r + self.g + self.b + self.a ) < ( other.r + other.g + other.b + other.a )
end

---@param other gpm.std.Color
---@protected
function Color:__le( other )
    return ( self.r + self.g + self.b + self.a ) <= ( other.r + other.g + other.b + other.a )
end

---@param value gpm.std.Color
---@protected
function Color:__concat( value )
    return self:toHex() .. tostring( value )
end

--- [SHARED AND MENU]
---
--- Unpacks the color as r, g, b, a values.
---
---@return integer r The 8-bit red channel.
---@return integer g The 8-bit green channel.
---@return integer b The 8-bit blue channel.
---@return integer a The 8-bit alpha channel.
function Color:unpack()
    return self.r, self.g, self.b, self.a
end

--- [SHARED AND MENU]
---
--- Makes a copy of the color.
---
---@return gpm.std.Color color The copy of the color.
function Color:copy()
    return setmetatable( {
        r = self.r,
        g = self.g,
        b = self.b,
        a = self.a
    }, Color )
end

--- [SHARED AND MENU]
---
--- Makes color a copy of the another color.
---
---@param color gpm.std.Color The color to copy.
---@return gpm.std.Color color The copy of the color.
function Color:copyFrom( color )
    self.r = color.r
    self.g = color.g
    self.b = color.b
    self.a = color.a or 255
    return self
end

--- [SHARED AND MENU]
---
--- Set the color as r, g, b, a values.
---
---@param r integer The 8-bit red channel.
---@param g integer The 8-bit green channel.
---@param b integer The 8-bit blue channel.
---@param a integer The 8-bit alpha channel.
---@return gpm.std.Color color The color object.
function Color:setUnpacked( r, g, b, a )
    r = r and math_min( math_max( r, 0 ), 255 ) or 0

    self.r = r
    self.g = g and math_min( math_max( g, 0 ), 255 ) or r
    self.b = b and math_min( math_max( b, 0 ), 255 ) or r
    self.a = a and math_min( math_max( a, 0 ), 255 ) or 255
    return self
end

--- [SHARED AND MENU]
---
--- Returns the color as hex string.
---
---@param withAlpha boolean? Whether to include alpha.
---@return string hex_str The hex string.
function Color:toHex( withAlpha )
    if withAlpha then
        return string_format( "#%02x%02x%02x%02x", self.r, self.g, self.b, self.a )
    else
        return string_format( "#%02x%02x%02x", self.r, self.g, self.b )
    end
end

do

    local bit_bor, bit_lshift = bit.bor, bit.lshift

    --- [SHARED AND MENU]
    ---
    --- Returns the color as 32-bit integer.
    ---
    ---@param withAlpha boolean? Whether to include alpha.
    ---@return integer uint32 The 32-bit integer.
    function Color:toUInt32( withAlpha )
        if withAlpha then
            return bit_bor( self.r, bit_lshift( self.g, 8 ), bit_lshift( self.b, 16 ), bit_lshift( self.a, 24 ) )
        else
            return bit_bor( self.r, bit_lshift( self.g, 8 ), bit_lshift( self.b, 16 ) )
        end
    end

end

--- [SHARED AND MENU]
---
--- Returns the color as binary string.
---
---@param withAlpha boolean? Whether to include alpha.
---@return string bin_str The binary string.
function Color:toBinary( withAlpha )
    return withAlpha and string_char( self.r, self.g, self.b, self.a ) or string_char( self.r, self.g, self.b )
end

--- [SHARED AND MENU]
---
--- Returns the color as HSL values (hue, saturation, lightness).
---
---@return integer hue The hue in degrees [0, 360].
---@return number saturation The saturation as fraction [0, 1].
---@return number lightness The lightness as fraction [0, 1].
function Color:toHSL()
    local red, green, blue = self.r * DIV255_CONST, self.g * DIV255_CONST, self.b * DIV255_CONST
    local min_value, max_value = math_min( red, green, blue ), math_max( red, green, blue )

    local lightness = ( max_value + min_value ) * 0.5

    local delta = max_value - min_value
    if delta ~= 0 then
        local saturation
        if lightness > 0.5 then
            saturation = delta / ( 2.0 - ( max_value - min_value ) )
        else
            saturation = delta / ( max_value + min_value )
        end

        local hue
        if max_value == red then
            hue = ( ( green - blue ) / delta ) % 6
        elseif max_value == green then
            hue = ( ( blue - red ) / delta ) + 2
        else
            hue = ( ( red - green ) / delta ) + 4
        end

        hue = hue * 60

        return hue < 0 and hue + 360 or hue, saturation, lightness
    end

    return 0, 0, lightness
end

--- [SHARED AND MENU]
---
--- Returns the color as HSV values (hue, saturation, value).
---
---@return integer hue The hue in degrees [0, 360].
---@return number saturation The saturation as fraction [0, 1].
---@return number value The value as fraction [0, 1].
function Color:toHSV()
    local red, green, blue = self.r * DIV255_CONST, self.g * DIV255_CONST, self.b * DIV255_CONST
    local min_value, max_value = math_min( red, green, blue ), math_max( red, green, blue )
    local delta = max_value - min_value

    local saturation
    if max_value == 0 then
        saturation = 0
    else
        saturation = delta / max_value
    end

    local hue
    if delta == 0 then
        hue = 0
    elseif max_value == red then
        hue = ( ( green - blue ) / delta ) % 6
    elseif max_value == green then
        hue = ( ( blue - red ) / delta ) + 2
    else
        hue = ( ( red - green ) / delta ) + 4
    end

    hue = hue * 60

    return hue < 0 and hue + 360 or hue, saturation, max_value
end

--- [SHARED AND MENU]
---
--- Returns the color as HWB values (hue, whiteness, blackness).
---
---@return integer hue The hue in degrees [0, 360].
---@return number whiteness The whiteness as fraction [0, 1].
---@return number blackness The blackness as fraction [0, 1].
function Color:toHWB()
    local hue, saturation, brightness = self:toHSL()
    return hue, ( 1 - saturation ) * brightness, 1 - brightness
end

--- [SHARED AND MENU]
---
--- Returns the color as CMYK values (cyan, magenta, yellow, black).
---
---@return number cyan The cyan as fraction [0, 1].
---@return number magenta The magenta as fraction [0, 1].
---@return number yellow The yellow as fraction [0, 1].
---@return number black The black as fraction [0, 1].
function Color:toCMYK()
    local m = math_max( self.r, self.g, self.b )
    return ( m - self.r ) / m, ( m - self.g ) / m, ( m - self.b ) / m, math_min( self.r, self.g, self.b ) * DIV255_CONST
end

do

    local math_lerp = math.lerp

    --- [SHARED AND MENU]
    ---
    --- Smoothing a color object to another color object.
    ---
    ---@param color gpm.std.Color The color to lerp.
    ---@param frac number? The fraction to lerp [0, 1].
    ---@param withAlpha boolean? Whether to lerp alpha channel.
    ---@return gpm.std.Color
    function Color:lerp( color, frac, withAlpha )
        frac = frac and math_min( math_max( frac, 0 ), 1 ) or 0.5

        self.r = math_lerp( frac, self.r, color.r )
        self.g = math_lerp( frac, self.g, color.g )
        self.b = math_lerp( frac, self.b, color.b )

        if withAlpha then
            self.a = math_lerp( frac, self.a, color.a )
        end

        return self
    end

end

--- [SHARED AND MENU]
---
--- Creates a color object from lerp.
---
---@param color gpm.std.Color The "from" color.
---@param frac number? The fraction [0, 1].
---@param withAlpha boolean? Whether to lerp alpha channel.
---@return gpm.std.Color color The color object.
function Color:getLerped( color, frac, withAlpha )
    return self:copy():lerp( color, frac, withAlpha )
end

--- [SHARED AND MENU]
---
--- Returns the color's hue.
---
---@return integer hue The hue in degrees [0, 360].
function Color:getHue()
    local red, green, blue = self.r * DIV255_CONST, self.g * DIV255_CONST, self.b * DIV255_CONST
    local max_value = math_max( red, green, blue )

    local delta = max_value - math_min( red, green, blue )
    if delta == 0 then
        return 0
    end

    local hue
    if max_value == red then
        hue = ( ( green - blue ) / delta ) % 6
    elseif max_value == green then
        hue = ( ( blue - red ) / delta ) + 2
    else
        hue = ( ( red - green ) / delta ) + 4
    end

    hue = hue * 60

    return hue < 0 and hue + 360 or hue
end

--- [SHARED AND MENU]
---
--- Sets the color's hue.
---
---@param hue integer The hue in degrees [0, 360].
---@return gpm.std.Color color The color object.
function Color:setHue( hue )
    local _, saturation, lightness = self:toHSL()
    return self:fromHSL( hue, saturation, lightness )
end

--- [SHARED AND MENU]
---
--- Returns the color's saturation.
---
---@return number saturation The saturation as fraction [0, 1].
function Color:getSaturation()
    local red, green, blue = self.r * DIV255_CONST, self.g * DIV255_CONST, self.b * DIV255_CONST
    local max_value = math_max( red, green, blue )
    return max_value == 0 and 0 or ( max_value - math_min( red, green, blue ) ) / max_value
end

--- [SHARED AND MENU]
---
--- Sets the color's saturation.
---
---@param saturation number The saturation as fraction [0, 1].
---@return gpm.std.Color color The color object.
function Color:setSaturation( saturation )
    local hue, _, lightness = self:toHSL()
    return self:fromHSL( hue, saturation, lightness )
end

--- [SHARED AND MENU]
---
--- Returns the color's brightness.
---
---@return number brightness The brightness as fraction [0, 1].
function Color:getBrightness()
    return math_max( self.r, self.g, self.b ) * DIV255_CONST
end

--- [SHARED AND MENU]
---
--- Sets the color's brightness.
---
---@param brightness number The brightness as fraction [0, 1].
---@return gpm.std.Color color The color object.
function Color:setBrightness( brightness )
    local hue, saturation, _ = self:toHSV()
    return self:fromHSV( hue, saturation, brightness )
end

--- [SHARED AND MENU]
---
--- Returns the color's lightness.
---
---@return number lightness The lightness as fraction [0, 1].
function Color:getLightness()
    local red, green, blue = self.r * DIV255_CONST, self.g * DIV255_CONST, self.b * DIV255_CONST
    return ( math_max( red, green, blue ) + math_min( red, green, blue ) ) * 0.5
end

--- [SHARED AND MENU]
---
--- Sets the color's lightness.
---
---@param lightness number The lightness as fraction [0, 1].
---@return gpm.std.Color color The color object.
function Color:setLightness( lightness )
    local hue, saturation, _ = self:toHSL()
    return self:fromHSL( hue, saturation, lightness )
end

--- [SHARED AND MENU]
---
--- Returns the color's whiteness.
---
---@return number whiteness The whiteness as fraction [0, 1].
function Color:getWhiteness()
    local _, saturation, brightness = self:toHSL()
    return ( 1 - saturation ) * brightness
end

--- [SHARED AND MENU]
---
--- Sets the color's whiteness.
---
---@param whiteness number The whiteness as fraction [0, 1].
---@return gpm.std.Color color The color object.
function Color:setWhiteness( whiteness )
    local hue, _, blackness = self:toHWB()
    return self:fromHWB( hue, whiteness, blackness )
end

--- [SHARED AND MENU]
---
--- Returns the color's blackness.
---
---@return number blackness The blackness as fraction [0, 1].
function Color:getBlackness()
    local _, __, brightness = self:toHSL()
    return 1 - brightness
end

--- [SHARED AND MENU]
---
--- Sets the color's blackness.
---
---@param blackness number The blackness as fraction [0, 1].
---@return gpm.std.Color color The color object.
function Color:setBlackness( blackness )
    local hue, saturation, _ = self:toHSL()
    return self:fromHSL( hue, saturation, blackness )
end

do

    local string_sub = string.sub

    local byte2number = {}

    setmetatable( byte2number, {
        __index = function()
            return 0
        end
    } )

    -- 0-9
    for i = 48, 57, 1 do
        byte2number[ i ] = i - 48
    end

    -- A-F
    for i = 65, 70, 1 do
        byte2number[ i ] = i - 55
    end

    -- a-f
    for i = 97, 102, 1 do
        byte2number[ i ] = i - 87
    end

    --- [SHARED AND MENU]
    ---
    --- Changes the color to hex string.
    ---
    --- Supports hex strings from `0` to `8` characters.
    ---
    ---@param hex string The hex string. If the first character is `#`, it will be ignored.
    ---@return gpm.std.Color color The color object.
    function Color:fromHex( hex )
        if string_byte( hex, 1 ) == 0x23 --[[ # ]] then
            hex = string_sub( hex, 2 )
        end

        local length = string_len( hex )
        if length == 1 then
            local b1 = byte2number[ string_byte( hex, 1 ) ]
            self.r = b1 * 0x10 + b1
            self.g = 0
            self.b = 0
            self.a = 255
        elseif length == 2 then
            local b1, b2 = string_byte( hex, 1, 2 )
            b1, b2 = byte2number[ b1 ], byte2number[ b2 ]
            self.r = b1 * 0x10 + b1
            self.g = b2 * 0x10 + b2
            self.b = 0
            self.a = 255
        elseif length == 3 then
            local b1, b2, b3 = string_byte( hex, 1, 3 )
            b1, b2, b3 = byte2number[ b1 ], byte2number[ b2 ], byte2number[ b3 ]
            self.r = b1 * 0x10 + b1
            self.g = b2 * 0x10 + b2
            self.b = b3 * 0x10 + b3
            self.a = 255
        elseif length == 4 then
            local b1, b2, b3, b4 = string_byte( hex, 1, 4 )
            b1, b2, b3, b4 = byte2number[ b1 ], byte2number[ b2 ], byte2number[ b3 ], byte2number[ b4 ]
            self.r = b1 * 0x10 + b1
            self.g = b2 * 0x10 + b2
            self.b = b3 * 0x10 + b3
            self.a = b4 * 0x10 + b4
        elseif length == 6 then
            local b1, b2, b3, b4, b5, b6 = string_byte( hex, 1, 6 )
            self.r = byte2number[ b1 ] * 0x10 + byte2number[ b2 ]
            self.g = byte2number[ b3 ] * 0x10 + byte2number[ b4 ]
            self.b = byte2number[ b5 ] * 0x10 + byte2number[ b6 ]
            self.a = 255
        elseif length == 8 then
            local b1, b2, b3, b4, b5, b6, b7, b8 = string_byte( hex, 1, 8 )
            self.r = byte2number[ b1 ] * 0x10 + byte2number[ b2 ]
            self.g = byte2number[ b3 ] * 0x10 + byte2number[ b4 ]
            self.b = byte2number[ b5 ] * 0x10 + byte2number[ b6 ]
            self.a = byte2number[ b7 ] * 0x10 + byte2number[ b8 ]
        end

        return self
    end

    --- [SHARED AND MENU]
    ---
    --- Creates a color object from hex string.
    ---
    ---@param hex string The hex string. If the first character is `#`, it will be ignored.
    ---@return gpm.std.Color color The color object.
    function ColorClass.fromHex( hex )
        return from_rgba( 0, 0, 0, 255 ):fromHex( hex )
    end

end

do

    local bit_band, bit_rshift = bit.band, bit.rshift

    --- [SHARED AND MENU]
    ---
    --- Changes the color to 32-bit uint.
    ---
    ---@param uint32 integer The 32-bit uint.
    ---@param withAlpha boolean? Whether to include alpha.
    ---@return gpm.std.Color color The color object.
    function Color:fromUInt32( uint32, withAlpha )
        withAlpha = withAlpha == true

        self.r = bit_rshift( bit_band( uint32, 0xFF000000 ), withAlpha and 24 or 16 )
        self.g = bit_rshift( bit_band( uint32, 0x00FF0000 ), withAlpha and 16 or 8 )

        if withAlpha then
            self.b = bit_rshift( bit_band( uint32, 0x0000FF00 ), 8 )
        else
            self.b = bit_band( uint32, 0x0000FF00 )
        end

        if withAlpha then
            self.a = bit_band( uint32, 0x000000FF )
        else
            self.a = 255
        end

        return self
    end

    --- [SHARED AND MENU]
    ---
    --- Creates a color object from 32-bit uint.
    ---
    ---@param uint32 integer The 32-bit uint.
    ---@param withAlpha boolean? Whether to include alpha.
    ---@return gpm.std.Color color The color object.
    function ColorClass.fromUInt32( uint32, withAlpha )
        return from_rgba( 0, 0, 0, 255 ):fromUInt32( uint32, withAlpha )
    end

end

--- [SHARED AND MENU]
---
--- Changes the color to binary string.
---
---@param binary string The binary string.
---@return gpm.std.Color color The color object.
function Color:fromBinary( binary )
    local length = string_len( binary )
    if length == 1 then
        self.r = string_byte( binary, 1 )
        self.g = 0
        self.b = 0
        self.a = 255
    elseif length == 2 then
        self.r = string_byte( binary, 1 )
        self.b = string_byte( binary, 2 )
        self.g = 0
        self.a = 255
    elseif length == 3 then
        self.r = string_byte( binary, 1 )
        self.g = string_byte( binary, 2 )
        self.b = string_byte( binary, 3 )
        self.a = 255
    else
        self.r = string_byte( binary, 1 )
        self.g = string_byte( binary, 2 )
        self.b = string_byte( binary, 3 )
        self.a = string_byte( binary, 4 )
    end

    return self
end

--- [SHARED AND MENU]
---
--- Creates a color object from binary string.
---
---@param binary string The binary string.
---@return gpm.std.Color color The color object.
function ColorClass.fromBinary( binary )
    return from_rgba( 0, 0, 0, 255 ):fromBinary( binary )
end

--- [SHARED AND MENU]
---
--- Changes the color to HSL.
---
---@param hue integer The hue in degrees [0, 360].
---@param saturation number The saturation [0, 1].
---@param lightness number The lightness [0, 1].
---@return gpm.std.Color color The color object.
function Color:fromHSL( hue, saturation, lightness )
    hue = hue % 360

    local c = ( 1 - math_abs( 2 * lightness - 1 ) ) * saturation
    local x = c * ( 1 - math_abs( ( hue / 60 ) % 2 - 1 ) )
    local m = lightness - ( c * 0.5 )

    local r, g, b
    if hue < 60 then
        r, g, b = c, x, 0
    elseif hue < 120 then
        r, g, b = x, c, 0
    elseif hue < 180 then
        r, g, b = 0, c, x
    elseif hue < 240 then
        r, g, b = 0, x, c
    elseif hue < 300 then
        r, g, b = x, 0, c
    else
        r, g, b = c, 0, x
    end

    self.r = math_floor( ( r + m ) * 255 )
    self.g = math_floor( ( g + m ) * 255 )
    self.b = math_floor( ( b + m ) * 255 )
    return self
end

--- [SHARED AND MENU]
---
--- Creates a color object from HSL values.
---
---@param hue integer The hue in degrees [0, 360].
---@param saturation number The saturation [0, 1].
---@param lightness number The lightness [0, 1].
---@return gpm.std.Color color The color object.
function ColorClass.fromHSL( hue, saturation, lightness )
    return from_rgba( 0, 0, 0, 255 ):fromHSL( hue, saturation, lightness )
end

--- [SHARED AND MENU]
---
--- Changes the color to HSV values.
---
---@param hue integer The hue in degrees [0, 360].
---@param saturation number The saturation [0, 1].
---@param brightness number The brightness [0, 1].
---@return gpm.std.Color color The color object.
function Color:fromHSV( hue, saturation, brightness )
    hue = hue % 360

    local c = brightness * saturation
    local x = c * ( 1 - math_abs( ( hue / 60 ) % 2 - 1 ) )
    local m = brightness - c

    local r, g, b
    if hue < 60 then
        r, g, b = c, x, 0
    elseif hue < 120 then
        r, g, b = x, c, 0
    elseif hue < 180 then
        r, g, b = 0, c, x
    elseif hue < 240 then
        r, g, b = 0, x, c
    elseif hue < 300 then
        r, g, b = x, 0, c
    else
        r, g, b = c, 0, x
    end

    self.r = math_floor( ( r + m ) * 255 )
    self.g = math_floor( ( g + m ) * 255 )
    self.b = math_floor( ( b + m ) * 255 )
    return self
end

--- [SHARED AND MENU]
---
--- Creates a color object from HSV values.
---
---@param hue integer The hue in degrees [0, 360].
---@param saturation number The saturation [0, 1].
---@param brightness number The brightness [0, 1].
---@return gpm.std.Color color The color object.
function ColorClass.fromHSV( hue, saturation, brightness )
    return from_rgba( 0, 0, 0, 255 ):fromHSV( hue, saturation, brightness )
end

--- [SHARED AND MENU]
---
--- Changes the color to HWB values.
---
---@param hue integer The hue in degrees [0, 360].
---@param saturation number The saturation [0, 1].
---@param brightness number The brightness [0, 1].
---@return gpm.std.Color color The color object.
function Color:fromHWB( hue, saturation, brightness )
    brightness = 1 - brightness
    return self:fromHSV( hue, ( brightness > 0 ) and ( 1 - ( saturation / brightness ) ) or 0, brightness )
end

--- [SHARED AND MENU]
---
--- Creates a color object from HWB values.
---
---@param hue integer The hue in degrees [0, 360].
---@param saturation number The saturation [0, 1].
---@param brightness number The brightness [0, 1].
---@return gpm.std.Color color The color object.
function ColorClass.fromHWB( hue, saturation, brightness )
    return from_rgba( 0, 0, 0, 255 ):fromHWB( hue, saturation, brightness )
end

--- [SHARED AND MENU]
---
--- Changes the color to CMYK values.
---
---@param cyan number The cyan as fraction [0, 1].
---@param magenta number The magenta as fraction [0, 1].
---@param yellow number The yellow as fraction [0, 1].
---@param black number The black as fraction [0, 1].
---@return gpm.std.Color color The color object.
function Color:fromCMYK( cyan, magenta, yellow, black )
    cyan, magenta, yellow, black = cyan * 0.01, magenta * 0.01, yellow * 0.01, black * 0.01

    local mk = 1 - black

    self.r = math_floor( ( ( 1 - cyan ) * mk ) * 255 )
    self.g = math_floor( ( ( 1 - magenta ) * mk ) * 255 )
    self.b = math_floor( ( ( 1 - yellow ) * mk ) * 255 )
    return self
end

--- [SHARED AND MENU]
---
--- Creates a color object from CMYK values.
---
---@param cyan number The cyan as fraction [0, 1].
---@param magenta number The magenta as fraction [0, 1].
---@param yellow number The yellow as fraction [0, 1].
---@param black number The black as fraction [0, 1].
---@return gpm.std.Color color The color object.
function ColorClass.fromCMYK( cyan, magenta, yellow, black )
    return from_rgba( 0, 0, 0, 255 ):fromCMYK( cyan, magenta, yellow, black )
end

if std.CLIENT then

    local render_ReadPixel

    local glua_render = _G.render
    if glua_render ~= nil then
        render_ReadPixel = glua_render.ReadPixel
    end

    if render_ReadPixel == nil then

        function render_ReadPixel( x, y )
            return 0, 0, 0, 255
        end

    end

    --- [CLIENT]
    ---
    --- Creates a color object from screen coordinates by reading a pixel.
    ---
    --- Requires `render.CapturePixels` call before using.
    ---
    ---@see https://wiki.facepunch.com/gmod/render.ReadPixel
    ---@param x integer The x coordinate.
    ---@param y integer The y coordinate.
    ---@param alpha integer? The alpha channel.
    ---@return gpm.std.Color
    function ColorClass.fromScreen( x, y, alpha )
        local r, g, b, a = render_ReadPixel( x, y )
        return from_rgba( r, g, b, alpha or a )
    end

end

do

    local debug_getmetatable = std.debug.getmetatable
    local isstring = std.isstring

    --- [SHARED AND MENU]
    ---
    --- Checks if the value is a color object.
    ---@param value any The value to check.
    ---@return boolean
    function std.iscolor( value )
        return debug_getmetatable( value ) == Color
    end

    --- [SHARED AND MENU]
    ---
    --- A table containing named colors.
    ---
    --- Also takes colors from `resource/ClientScheme.res` if available. [CLIENT/MENU?]
    ---
    --- If no color is found, a new empty color will be created and assigned to specified name.
    ---
    --- Table key must be string or integer.
    ---
    ---@type table<string | integer, gpm.std.Color>
    local scheme = ColorClass.scheme or {}
    ColorClass.scheme = scheme

    local metatable = debug_getmetatable( scheme ) or {}

    ---@protected
    function metatable:__tostring()
        return string_format( "Color Scheme: %p", self )
    end

    setmetatable( scheme, metatable )

    ---@diagnostic disable-next-line: undefined-field
    local NamedColor = _G.NamedColor or std.debug.fempty

    ---@protected
    function metatable:__index( name )
        local color
        if isstring( name ) then
            color = NamedColor( name )
            if color == nil then
                color = from_rgba( 255, 255, 255, 255 )
            else
                setmetatable( color, Color )
            end
        elseif isnumber( name ) then
            color = from_rgba( name, name, name, 255 )
        else
            error( "wrong color name", 3 )
        end

        scheme[ name ] = color
        return color
    end

end
