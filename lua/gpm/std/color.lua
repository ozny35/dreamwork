local _G = _G

---@class gpm.std
local std = _G.gpm.std

local math, string, bit = std.math, std.string, std.bit
local isnumber, setmetatable = std.isnumber, std.setmetatable
local math_abs, math_min, math_max, math_floor = math.abs, math.min, math.max, math.floor
local string_char, string_byte, string_format, string_len = string.char, string.byte, string.format, string.len

local DIV255_CONST = 1 / 255

--- [SHARED AND MENU] The color class.
---@diagnostic disable-next-line: duplicate-doc-alias
---@alias Color gpm.std.Color
---@class gpm.std.Color : gpm.std.Object
---@field __class gpm.std.ColorClass
---@field r integer
---@field g integer
---@field b integer
---@field a integer
---@operator add(Color): Color
---@operator sub(Color): Color
---@operator mul(Color | integer): Color
---@operator div(Color | integer): Color
---@operator unm(): Color
local Color = std.class.base( "Color" )

do

    local debug_getmetatable = std.debug.getmetatable

    function std.iscolor( value )
        return debug_getmetatable( value ) == Color
    end

end

---@class gpm.std.ColorClass : gpm.std.Color
---@field __base Color
---@overload fun(r: integer?, g: integer?, b: integer?, a: integer?): gpm.std.Color
local ColorClass = std.class.create( Color )

do

    local rawget, rawset = std.rawget, std.rawset

    local key2index = {
        r = 1,
        red = 1,
        g = 2,
        green = 2,
        b = 3,
        blue = 3,
        a = 4,
        alpha = 4
    }

    ---@param key integer | string
    ---@return integer | function | nil
    function Color:__index( key )
        local index = key2index[ key ]
        if index == nil then
            return rawget( Color, key )
        else
            return rawget( self, index ) or 0
        end
    end

    ---@param key integer | string
    ---@param value integer
    function Color:__newindex( key, value )
        local index = key2index[ key ]
        if index ~= nil then
            rawset( self, index, value )
        end
    end

end

--- [SHARED AND MENU] Creates a color object from RGBA values.
---@param r integer?: The 8-bit red channel.
---@param g integer?: The 8-bit green channel.
---@param b integer?: The 8-bit blue channel.
---@param a integer?: The 8-bit alpha channel.
---@return Color: The color object.
local function from_rgba( r, g, b, a )
    r = r and math_min( math_max( r, 0 ), 255 ) or 0
    return setmetatable( {
        r,
        g and math_min( math_max( g, 0 ), 255 ) or r,
        b and math_min( math_max( b, 0 ), 255 ) or r,
        a and math_min( math_max( a, 0 ), 255 ) or 255
    }, Color )
end

ColorClass.fromRGBA = from_rgba

---@protected
---@param r integer?: The 8-bit red channel.
---@param g integer?: The 8-bit green channel.
---@param b integer?: The 8-bit blue channel.
---@param a integer?: The 8-bit alpha channel.
---@return Color: The color object.
function Color:__new( r, g, b, a )
    return from_rgba( r, g, b, a )
end

---@protected
function Color:__tostring()
    return string_format( "Color: %p [%d, %d, %d, %d]", self, self[ 1 ], self[ 2 ], self[ 3 ], self[ 4 ] )
end

---@param other Color
---@protected
function Color:__eq( other )
    return self[ 1 ] == other[ 1 ] and self[ 2 ] == other[ 2 ] and self[ 3 ] == other[ 3 ] and self[ 4 ] == other[ 4 ]
end

---@protected
function Color:__unm()
    return from_rgba(
        math_abs( 255 - self[ 1 ] ),
        math_abs( 255 - self[ 2 ] ),
        math_abs( 255 - self[ 3 ] ),
        self[ 4 ]
    )
end

--- [SHARED AND MENU] Inverts current color.
---@return Color: The color object.
function Color:invert()
    self[ 1 ] = math_min( math_max( math_abs( 255 - self[ 1 ] ), 0 ), 255 )
    self[ 2 ] = math_min( math_max( math_abs( 255 - self[ 2 ] ), 0 ), 255 )
    self[ 3 ] = math_min( math_max( math_abs( 255 - self[ 3 ] ), 0 ), 255 )
    return self
end

---@param color Color
---@protected
function Color:__add( color )
    return from_rgba(
        self[ 1 ] + color[ 1 ],
        self[ 2 ] + color[ 2 ],
        self[ 3 ] + color[ 3 ],
        self[ 4 ]
    )
end

---@param color Color
---@protected
function Color:__sub( color )
    return from_rgba(
        self[ 1 ] - color[ 1 ],
        self[ 2 ] - color[ 2 ],
        self[ 3 ] - color[ 3 ],
        self[ 4 ]
    )
end

---@param other Color | integer
---@protected
function Color:__mul( other )
    if isnumber( other ) then
        ---@cast other integer
        return from_rgba(
            self[ 1 ] * other,
            self[ 2 ] * other,
            self[ 3 ] * other,
            self[ 4 ]
        )
    end

    ---@cast other Color
    return from_rgba(
        self[ 1 ] * other[ 1 ],
        self[ 2 ] * other[ 2 ],
        self[ 3 ] * other[ 3 ],
        self[ 4 ]
    )
end

---@param other Color | integer
---@protected
function Color:__div( other )
    if isnumber( other ) then
        ---@cast other integer
        local multiplier = 1 / other
        return from_rgba(
            self[ 1 ] * multiplier,
            self[ 2 ] * multiplier,
            self[ 3 ] * multiplier,
            self[ 4 ]
        )
    end

    ---@cast other Color
    return from_rgba(
        self[ 1 ] / other[ 1 ],
        self[ 2 ] / other[ 2 ],
        self[ 3 ] / other[ 3 ],
        self[ 4 ]
    )
end

---@param other Color
---@protected
function Color:__lt( other )
    return ( self[ 1 ] + self[ 2 ] + self[ 3 ] + self[ 4 ] ) < ( other[ 1 ] + other[ 2 ] + other[ 3 ] + other[ 4 ] )
end

---@param other Color
---@protected
function Color:__le( other )
    return ( self[ 1 ] + self[ 2 ] + self[ 3 ] + self[ 4 ] ) <= ( other[ 1 ] + other[ 2 ] + other[ 3 ] + other[ 4 ] )
end

---@param value Color
---@protected
function Color:__concat( value )
    return self:toHex() .. tostring( value )
end

--- [SHARED AND MENU] Unpacks the color as r, g, b, a values.
---@return integer r: The 8-bit red channel.
---@return integer g: The 8-bit green channel.
---@return integer b: The 8-bit blue channel.
---@return integer a: The 8-bit alpha channel.
function Color:unpack()
    return self[ 1 ], self[ 2 ], self[ 3 ], self[ 4 ]
end

--- [SHARED AND MENU] Makes a copy of the color.
---@return Color: The copy of the color.
function Color:copy()
    return setmetatable( { self[ 1 ], self[ 2 ], self[ 3 ], self[ 4 ] }, Color )
end

--- [SHARED AND MENU] Makes color a copy of the another color.
---@param color Color: The color to copy.
---@return Color: The copy of the color.
function Color:copyFrom( color )
    self[ 1 ] = color[ 1 ]
    self[ 2 ] = color[ 2 ]
    self[ 3 ] = color[ 3 ]
    self[ 4 ] = color[ 4 ] or 255
    return self
end

--- [SHARED AND MENU] Set the color as r, g, b, a values.
---@param r integer: The 8-bit red channel.
---@param g integer: The 8-bit green channel.
---@param b integer: The 8-bit blue channel.
---@param a integer: The 8-bit alpha channel.
---@return Color: The color object.
function Color:setUnpacked( r, g, b, a )
    r = r and math_min( math_max( r, 0 ), 255 ) or 0

    self[ 1 ] = r
    self[ 2 ] = g and math_min( math_max( g, 0 ), 255 ) or r
    self[ 3 ] = b and math_min( math_max( b, 0 ), 255 ) or r
    self[ 4 ] = a and math_min( math_max( a, 0 ), 255 ) or 255
    return self
end

--- [SHARED AND MENU] Returns the color as hex string.
---@param withAlpha boolean?: Whether to include alpha.
---@return string: The hex string.
function Color:toHex( withAlpha )
    if withAlpha then
        return string_format( "#%02x%02x%02x%02x", self[ 1 ], self[ 2 ], self[ 3 ], self[ 4 ] )
    else
        return string_format( "#%02x%02x%02x", self[ 1 ], self[ 2 ], self[ 3 ] )
    end
end

do

    local bit_bor, bit_lshift = bit.bor, bit.lshift

    --- [SHARED AND MENU] Returns the color as 32-bit integer.
    ---@param withAlpha boolean?: Whether to include alpha.
    ---@return integer: The 32-bit integer.
    function Color:toUInt32( withAlpha )
        if withAlpha then
            return bit_bor( self[ 1 ], bit_lshift( self[ 2 ], 8 ), bit_lshift( self[ 3 ], 16 ), bit_lshift( self[ 4 ], 24 ) )
        else
            return bit_bor( self[ 1 ], bit_lshift( self[ 2 ], 8 ), bit_lshift( self[ 3 ], 16 ) )
        end
    end

end

--- [SHARED AND MENU] Returns the color as binary string.
---@param withAlpha boolean?: Whether to include alpha.
---@return string: The binary string.
function Color:toBinary( withAlpha )
    return withAlpha and string_char( self[ 1 ], self[ 2 ], self[ 3 ], self[ 4 ] ) or string_char( self[ 1 ], self[ 2 ], self[ 3 ] )
end

--- [SHARED AND MENU] Returns the color as HSL values (hue, saturation, lightness).
---@return integer hue: The hue in degrees [0, 360].
---@return number saturation: The saturation as fraction [0, 1].
---@return number lightness: The lightness as fraction [0, 1].
function Color:toHSL()
    local red, green, blue = self[ 1 ] * DIV255_CONST, self[ 2 ] * DIV255_CONST, self[ 3 ] * DIV255_CONST
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

--- [SHARED AND MENU] Returns the color as HSV values (hue, saturation, value).
---@return integer hue: The hue in degrees [0, 360].
---@return number saturation: The saturation as fraction [0, 1].
---@return number value: The value as fraction [0, 1].
function Color:toHSV()
    local red, green, blue = self[ 1 ] * DIV255_CONST, self[ 2 ] * DIV255_CONST, self[ 3 ] * DIV255_CONST
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

--- [SHARED AND MENU] Returns the color as HWB values (hue, whiteness, blackness).
---@return integer hue: The hue in degrees [0, 360].
---@return number whiteness: The whiteness as fraction [0, 1].
---@return number blackness: The blackness as fraction [0, 1].
function Color:toHWB()
    local hue, saturation, brightness = self:toHSL()
    return hue, ( 1 - saturation ) * brightness, 1 - brightness
end

--- [SHARED AND MENU] Returns the color as CMYK values (cyan, magenta, yellow, black).
---@return number cyan: The cyan as fraction [0, 1].
---@return number magenta: The magenta as fraction [0, 1].
---@return number yellow: The yellow as fraction [0, 1].
---@return number black: The black as fraction [0, 1].
function Color:toCMYK()
    local m = math_max( self[ 1 ], self[ 2 ], self[ 3 ] )
    return ( m - self[ 1 ] ) / m, ( m - self[ 2 ] ) / m, ( m - self[ 3 ] ) / m, math_min( self[ 1 ], self[ 2 ], self[ 3 ] ) * DIV255_CONST
end

do

    local math_lerp = math.lerp

    --- [SHARED AND MENU] Smoothing a color object to another color object.
    ---@param color Color: The color to lerp.
    ---@param frac number?: The fraction to lerp [0, 1].
    ---@param withAlpha boolean?: Whether to lerp alpha channel.
    ---@return Color
    function Color:lerp( color, frac, withAlpha )
        frac = frac and math_min( math_max( frac, 0 ), 1 ) or 0.5

        self[ 1 ] = math_lerp( frac, self[ 1 ], color[ 1 ] )
        self[ 2 ] = math_lerp( frac, self[ 2 ], color[ 2 ] )
        self[ 3 ] = math_lerp( frac, self[ 3 ], color[ 3 ] )

        if withAlpha then
            self[ 4 ] = math_lerp( frac, self[ 4 ], color[ 4 ] )
        end

        return self
    end

end

--- [SHARED AND MENU] Creates a color object from lerp.
---@param color Color: The "from" color.
---@param frac number?: The fraction [0, 1].
---@param withAlpha boolean?: Whether to lerp alpha channel.
---@return Color: The color object.
function Color:getLerped( color, frac, withAlpha )
    return self:copy():lerp( color, frac, withAlpha )
end

--- [SHARED AND MENU] Returns the color's hue.
---@return integer: The hue in degrees [0, 360].
function Color:getHue()
    local red, green, blue = self[ 1 ] * DIV255_CONST, self[ 2 ] * DIV255_CONST, self[ 3 ] * DIV255_CONST
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

--- [SHARED AND MENU] Sets the color's hue.
---@param hue integer: The hue in degrees [0, 360].
---@return Color: The color object.
function Color:setHue( hue )
    local _, saturation, lightness = self:toHSL()
    return self:fromHSL( hue, saturation, lightness )
end

--- [SHARED AND MENU] Returns the color's saturation.
---@return number: The saturation as fraction [0, 1].
function Color:getSaturation()
    local red, green, blue = self[ 1 ] * DIV255_CONST, self[ 2 ] * DIV255_CONST, self[ 3 ] * DIV255_CONST
    local max_value = math_max( red, green, blue )
    return max_value == 0 and 0 or ( max_value - math_min( red, green, blue ) ) / max_value
end

--- [SHARED AND MENU] Sets the color's saturation.
---@param saturation number: The saturation as fraction [0, 1].
---@return Color: The color object.
function Color:setSaturation( saturation )
    local hue, _, lightness = self:toHSL()
    return self:fromHSL( hue, saturation, lightness )
end

--- [SHARED AND MENU] Returns the color's brightness.
---@return number: The brightness as fraction [0, 1].
function Color:getBrightness()
    return math_max( self[ 1 ], self[ 2 ], self[ 3 ] ) * DIV255_CONST
end

--- [SHARED AND MENU] Sets the color's brightness.
---@param brightness number: The brightness as fraction [0, 1].
---@return Color: The color object.
function Color:setBrightness( brightness )
    local hue, saturation, _ = self:toHSV()
    return self:fromHSV( hue, saturation, brightness )
end

--- [SHARED AND MENU] Returns the color's lightness.
---@return number: The lightness as fraction [0, 1].
function Color:getLightness()
    local red, green, blue = self[ 1 ] * DIV255_CONST, self[ 2 ] * DIV255_CONST, self[ 3 ] * DIV255_CONST
    return ( math_max( red, green, blue ) + math_min( red, green, blue ) ) * 0.5
end

--- [SHARED AND MENU] Sets the color's lightness.
---@param lightness number: The lightness as fraction [0, 1].
---@return Color: The color object.
function Color:setLightness( lightness )
    local hue, saturation, _ = self:toHSL()
    return self:fromHSL( hue, saturation, lightness )
end

--- [SHARED AND MENU] Returns the color's whiteness.
---@return number: The whiteness as fraction [0, 1].
function Color:getWhiteness()
    local _, saturation, brightness = self:toHSL()
    return ( 1 - saturation ) * brightness
end

--- [SHARED AND MENU] Sets the color's whiteness.
---@param whiteness number: The whiteness as fraction [0, 1].
---@return Color: The color object.
function Color:setWhiteness( whiteness )
    local hue, _, blackness = self:toHWB()
    return self:fromHWB( hue, whiteness, blackness )
end

--- [SHARED AND MENU] Returns the color's blackness.
---@return number: The blackness as fraction [0, 1].
function Color:getBlackness()
    local _, __, brightness = self:toHSL()
    return 1 - brightness
end

--- [SHARED AND MENU] Sets the color's blackness.
---@param blackness number: The blackness as fraction [0, 1].
---@return Color: The color object.
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

    --- [SHARED AND MENU] Changes the color to hex string.
    ---
    --- Supports hex strings from `0` to `8` characters.
    ---@param hex string: The hex string. If the first character is `#`, it will be ignored.
    ---@return Color: The color object.
    function Color:fromHex( hex )
        if string_byte( hex, 1 ) == 0x23 --[[ # ]] then
            hex = string_sub( hex, 2 )
        end

        local length = string_len( hex )
        if length == 1 then
            local b1 = byte2number[ string_byte( hex, 1 ) ]
            self[ 1 ] = b1 * 0x10 + b1
            self[ 2 ] = 0
            self[ 3 ] = 0
            self[ 4 ] = 255
        elseif length == 2 then
            local b1, b2 = string_byte( hex, 1, 2 )
            b1, b2 = byte2number[ b1 ], byte2number[ b2 ]
            self[ 1 ] = b1 * 0x10 + b1
            self[ 2 ] = b2 * 0x10 + b2
            self[ 3 ] = 0
            self[ 4 ] = 255
        elseif length == 3 then
            local b1, b2, b3 = string_byte( hex, 1, 3 )
            b1, b2, b3 = byte2number[ b1 ], byte2number[ b2 ], byte2number[ b3 ]
            self[ 1 ] = b1 * 0x10 + b1
            self[ 2 ] = b2 * 0x10 + b2
            self[ 3 ] = b3 * 0x10 + b3
            self[ 4 ] = 255
        elseif length == 4 then
            local b1, b2, b3, b4 = string_byte( hex, 1, 4 )
            b1, b2, b3, b4 = byte2number[ b1 ], byte2number[ b2 ], byte2number[ b3 ], byte2number[ b4 ]
            self[ 1 ] = b1 * 0x10 + b1
            self[ 2 ] = b2 * 0x10 + b2
            self[ 3 ] = b3 * 0x10 + b3
            self[ 4 ] = b4 * 0x10 + b4
        elseif length == 6 then
            local b1, b2, b3, b4, b5, b6 = string_byte( hex, 1, 6 )
            self[ 1 ] = byte2number[ b1 ] * 0x10 + byte2number[ b2 ]
            self[ 2 ] = byte2number[ b3 ] * 0x10 + byte2number[ b4 ]
            self[ 3 ] = byte2number[ b5 ] * 0x10 + byte2number[ b6 ]
            self[ 4 ] = 255
        elseif length == 8 then
            local b1, b2, b3, b4, b5, b6, b7, b8 = string_byte( hex, 1, 8 )
            self[ 1 ] = byte2number[ b1 ] * 0x10 + byte2number[ b2 ]
            self[ 2 ] = byte2number[ b3 ] * 0x10 + byte2number[ b4 ]
            self[ 3 ] = byte2number[ b5 ] * 0x10 + byte2number[ b6 ]
            self[ 4 ] = byte2number[ b7 ] * 0x10 + byte2number[ b8 ]
        end

        return self
    end

    --- [SHARED AND MENU] Creates a color object from hex string.
    ---@param hex string: The hex string. If the first character is `#`, it will be ignored.
    ---@return Color: The color object.
    function ColorClass.fromHex( hex )
        return from_rgba( 0, 0, 0, 255 ):fromHex( hex )
    end

end

do

    local bit_band, bit_rshift = bit.band, bit.rshift

    --- [SHARED AND MENU] Changes the color to 32-bit uint.
    ---@param uint32 integer: The 32-bit uint.
    ---@param withAlpha boolean?: Whether to include alpha.
    ---@return Color: The color object.
    function Color:fromUInt32( uint32, withAlpha )
        withAlpha = withAlpha == true

        self[ 1 ] = bit_rshift( bit_band( uint32, 0xFF000000 ), withAlpha and 24 or 16 )
        self[ 2 ] = bit_rshift( bit_band( uint32, 0x00FF0000 ), withAlpha and 16 or 8 )

        if withAlpha then
            self[ 3 ] = bit_rshift( bit_band( uint32, 0x0000FF00 ), 8 )
        else
            self[ 3 ] = bit_band( uint32, 0x0000FF00 )
        end

        if withAlpha then
            self[ 4 ] = bit_band( uint32, 0x000000FF )
        else
            self[ 4 ] = 255
        end

        return self
    end

    --- [SHARED AND MENU] Creates a color object from 32-bit uint.
    ---@param uint32 integer: The 32-bit uint.
    ---@param withAlpha boolean?: Whether to include alpha.
    ---@return Color: The color object.
    function ColorClass.fromUInt32( uint32, withAlpha )
        return from_rgba( 0, 0, 0, 255 ):fromUInt32( uint32, withAlpha )
    end

end

--- [SHARED AND MENU] Changes the color to binary string.
---@param binary string: The binary string.
---@return Color: The color object.
function Color:fromBinary( binary )
    local length = string_len( binary )
    if length == 1 then
        self[ 1 ] = string_byte( binary, 1 )
        self[ 2 ] = 0
        self[ 3 ] = 0
        self[ 4 ] = 255
    elseif length == 2 then
        self[ 1 ] = string_byte( binary, 1 )
        self[ 3 ] = string_byte( binary, 2 )
        self[ 2 ] = 0
        self[ 4 ] = 255
    elseif length == 3 then
        self[ 1 ] = string_byte( binary, 1 )
        self[ 2 ] = string_byte( binary, 2 )
        self[ 3 ] = string_byte( binary, 3 )
        self[ 4 ] = 255
    else
        self[ 1 ] = string_byte( binary, 1 )
        self[ 2 ] = string_byte( binary, 2 )
        self[ 3 ] = string_byte( binary, 3 )
        self[ 4 ] = string_byte( binary, 4 )
    end

    return self
end

--- [SHARED AND MENU] Creates a color object from binary string.
---@param binary string: The binary string.
---@return Color: The color object.
function ColorClass.fromBinary( binary )
    return from_rgba( 0, 0, 0, 255 ):fromBinary( binary )
end

--- [SHARED AND MENU] Changes the color to HSL.
---@param hue integer: The hue in degrees [0, 360].
---@param saturation number: The saturation [0, 1].
---@param lightness number: The lightness [0, 1].
---@return Color: The color object.
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

    self[ 1 ] = math_floor( ( r + m ) * 255 )
    self[ 2 ] = math_floor( ( g + m ) * 255 )
    self[ 3 ] = math_floor( ( b + m ) * 255 )
    return self
end

--- [SHARED AND MENU] Creates a color object from HSL values.
---@param hue integer: The hue in degrees [0, 360].
---@param saturation number: The saturation [0, 1].
---@param lightness number: The lightness [0, 1].
---@return Color: The color object.
function ColorClass.fromHSL( hue, saturation, lightness )
    return from_rgba( 0, 0, 0, 255 ):fromHSL( hue, saturation, lightness )
end

--- [SHARED AND MENU] Changes the color to HSV values.
---@param hue integer: The hue in degrees [0, 360].
---@param saturation number: The saturation [0, 1].
---@param brightness number: The brightness [0, 1].
---@return Color: The color object.
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

    self[ 1 ] = math_floor( ( r + m ) * 255 )
    self[ 2 ] = math_floor( ( g + m ) * 255 )
    self[ 3 ] = math_floor( ( b + m ) * 255 )
    return self
end

--- [SHARED AND MENU] Creates a color object from HSV values.
---@param hue integer: The hue in degrees [0, 360].
---@param saturation number: The saturation [0, 1].
---@param brightness number: The brightness [0, 1].
---@return Color: The color object.
function ColorClass.fromHSV( hue, saturation, brightness )
    return from_rgba( 0, 0, 0, 255 ):fromHSV( hue, saturation, brightness )
end

--- [SHARED AND MENU] Changes the color to HWB values.
---@param hue integer: The hue in degrees [0, 360].
---@param saturation number: The saturation [0, 1].
---@param brightness number: The brightness [0, 1].
---@return Color: The color object.
function Color:fromHWB( hue, saturation, brightness )
    brightness = 1 - brightness
    return self:fromHSV( hue, ( brightness > 0 ) and ( 1 - ( saturation / brightness ) ) or 0, brightness )
end

--- [SHARED AND MENU] Creates a color object from HWB values.
---@param hue integer: The hue in degrees [0, 360].
---@param saturation number: The saturation [0, 1].
---@param brightness number: The brightness [0, 1].
---@return Color: The color object.
function ColorClass.fromHWB( hue, saturation, brightness )
    return from_rgba( 0, 0, 0, 255 ):fromHWB( hue, saturation, brightness )
end

--- [SHARED AND MENU] Changes the color to CMYK values.
---@param cyan number: The cyan as fraction [0, 1].
---@param magenta number: The magenta as fraction [0, 1].
---@param yellow number: The yellow as fraction [0, 1].
---@param black number: The black as fraction [0, 1].
---@return Color: The color object.
function Color:fromCMYK( cyan, magenta, yellow, black )
    cyan, magenta, yellow, black = cyan * 0.01, magenta * 0.01, yellow * 0.01, black * 0.01

    local mk = 1 - black

    self[ 1 ] = math_floor( ( ( 1 - cyan ) * mk ) * 255 )
    self[ 2 ] = math_floor( ( ( 1 - magenta ) * mk ) * 255 )
    self[ 3 ] = math_floor( ( ( 1 - yellow ) * mk ) * 255 )
    return self
end

--- [SHARED AND MENU] Creates a color object from CMYK values.
---@param cyan number: The cyan as fraction [0, 1].
---@param magenta number: The magenta as fraction [0, 1].
---@param yellow number: The yellow as fraction [0, 1].
---@param black number: The black as fraction [0, 1].
---@return Color: The color object.
function ColorClass.fromCMYK( cyan, magenta, yellow, black )
    return from_rgba( 0, 0, 0, 255 ):fromCMYK( cyan, magenta, yellow, black )
end

if std.CLIENT then

    local render_ReadPixel = _G.render.ReadPixel
    local NamedColor = _G.NamedColor

    --- [CLIENT] Creates a color object from screen coordinates by reading a pixel.
    ---
    --- Requires `render.CapturePixels` call before using.
    ---
    ---@see https://wiki.facepunch.com/gmod/render.ReadPixel
    ---@param x integer: The x coordinate.
    ---@param y integer: The y coordinate.
    ---@param alpha integer? The alpha channel.
    ---@return Color
    function ColorClass.fromScreen( x, y, alpha )
        local r, g, b, a = render_ReadPixel( x, y )
        return from_rgba( r, g, b, alpha or a )
    end

    --- [CLIENT] Creates a color object from `resource/ClientScheme.res`.
    ---@param name string: The color name in `resource/ClientScheme.res`.
    ---@return Color?: The color object.
    function ColorClass.fromScheme( name )
        local tbl = NamedColor( name )
        if tbl == nil then return end
        return from_rgba( tbl.r, tbl.g, tbl.b, tbl.a )
    end

end

return ColorClass
