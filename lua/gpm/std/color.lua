local _G = _G
local Vector, ColorToHSL, HSLToColor, HSVToColor = _G.Vector, _G.ColorToHSL, _G.HSLToColor, _G.HSVToColor
local std = _G.gpm.std

local is_number, setmetatable = std.is.number, std.setmetatable

local bit_band, bit_rshift
do
    local bit = std.bit
    bit_band, bit_rshift = bit.band, bit.rshift
end

local math_abs, math_clamp, math_lerp, math_min, math_max
do
    local math = std.math
    math_abs, math_clamp, math_lerp, math_min, math_max = math.abs, math.clamp, math.lerp, math.min, math.max
end

local string_char, string_byte, string_format, string_len, string_sub
do
    local string = std.string
    string_char, string_byte, string_format, string_len, string_sub = string.char, string.byte, string.format, string.len, string.sub
end

local vconst = 1 / 255

-- https://github.com/Facepunch/garrysmod/blob/master/garrysmod/lua/includes/util/color.lua
---@diagnostic disable-next-line: duplicate-doc-alias
---@alias Color gpm.std.Color
---@class gpm.std.Color : gpm.std.Object
---@field __class gpm.std.ColorClass
---@field r number
---@field g number
---@field b number
---@field a number
---@operator add(Color): Color
---@operator sub(Color): Color
---@operator mul(Color | number): Color
---@operator div(Color | number): Color
---@operator unm(): Color
local Color = std.class.base( "Color" )

---@protected
---@param r number?: The red color channel.
---@param g number?: The green color channel.
---@param b number?: The blue color channel.
---@param a number?: The alpha color channel.
function Color:__init( r, g, b, a )
    r = math_clamp( r or 0, 0, 255 )

    self.r = r
    self.g = math_clamp( g or r, 0, 255 )
    self.b = math_clamp( b or r, 0, 255 )
    self.a = math_clamp( a or 255, 0, 255 )
end


---@private
---@protected
function Color:__tostring()
    return string_format( "Color: %p [%d, %d, %d, %d]", self, self.r, self.g, self.b, self.a )
end

---@private
---@protected
---@param other Color
function Color:__eq( other )
    return self.r == other.r and self.g == other.g and self.b == other.b and self.a == other.a
end

---@private
---@protected
function Color:__unm()
    return setmetatable(
        {
            r = math_clamp( math_abs( 255 - self.r ), 0, 255 ),
            g = math_clamp( math_abs( 255 - self.g ), 0, 255 ),
            b = math_clamp( math_abs( 255 - self.b ), 0, 255 ),
            a = self.a
        },
        Color
    )
end

---@private
---@protected
---@param color Color
function Color:__add( color )
    return setmetatable(
        {
            r = math_clamp( self.r + color.r, 0, 255 ),
            g = math_clamp( self.g + color.g, 0, 255 ),
            b = math_clamp( self.b + color.b, 0, 255 ),
            a = self.a
        },
        Color
    )
end

---@private
---@protected
---@param color Color
function Color:__sub( color )
    return setmetatable(
        {
            r = math_clamp( self.r - color.r, 0, 255 ),
            g = math_clamp( self.g - color.g, 0, 255 ),
            b = math_clamp( self.b - color.b, 0, 255 ),
            a = self.a
        },
        Color
    )
end

---@private
---@protected
---@param other Color | number
function Color:__mul( other )
    if is_number( other ) then
        ---@cast other number
        return setmetatable(
            {
                r = math_clamp( self.r * other, 0, 255 ),
                g = math_clamp( self.g * other, 0, 255 ),
                b = math_clamp( self.b * other, 0, 255 ),
                a = self.a
            },
            Color
        )
    else
        return setmetatable(
            {
                r = math_clamp( self.r * other.r, 0, 255 ),
                g = math_clamp( self.g * other.g, 0, 255 ),
                b = math_clamp( self.b * other.b, 0, 255 ),
                a = self.a
            },
            Color
        )
    end
end

---@private
---@protected
---@param other Color | number
function Color:__div( other )
    if is_number( other ) then
        ---@cast other number
        return setmetatable(
            {
                r = math_clamp( self.r / other, 0, 255 ),
                g = math_clamp( self.g / other, 0, 255 ),
                b = math_clamp( self.b / other, 0, 255 ),
                a = self.a
            },
            Color
        )
    else
        return setmetatable(
            {
                r = math_clamp( self.r / other.r, 0, 255 ),
                g = math_clamp( self.g / other.g, 0, 255 ),
                b = math_clamp( self.b / other.b, 0, 255 ),
                a = self.a
            },
            Color
        )
    end
end

---@private
---@protected
---@param other Color
function Color:__lt( other )
    return ( self.r + self.g + self.b + self.a ) < ( other.r + other.g + other.b + other.a )
end

---@private
---@protected
---@param other Color
function Color:__le( other )
    return ( self.r + self.g + self.b + self.a ) <= ( other.r + other.g + other.b + other.a )
end

---@private
---@protected
---@param value Color
function Color:__concat( value )
    return self:toHex() .. tostring( value )
end

--- Unpacks the color as r, g, b, a values.
---@return number
---@return number
---@return number
---@return number
function Color:unpack()
    return self.r, self.g, self.b, self.a
end

--- Set the color as r, g, b, a values.
---@param r number
---@param g number
---@param b number
---@param a number
function Color:setUnpacked( r, g, b, a )
    r = math_clamp( r or 0, 0, 255 )

    self.r = r
    self.g = math_clamp( g or r, 0, 255 )
    self.b = math_clamp( b or r, 0, 255 )
    self.a = math_clamp( a or 255, 0, 255 )
end

--- Makes a copy of the color.
---@return gpm.std.Color
function Color:copy()
    return self.__class( self.r, self.g, self.b, self.a )
end

--- Returns the color as { r, g, b, a } table.
---@return table
function Color:toTable()
    return { self.r, self.g, self.b, self.a }
end

--- Returns the color as hex string.
---@return string
function Color:toHex()
    return string_format( "#%02x%02x%02x", self.r, self.g, self.b )
end

--- Returns the color as binary string.
---@param withOutAlpha boolean
---@return string
function Color:toBinary( withOutAlpha )
    if withOutAlpha then
        return string_char( self.r, self.g, self.b )
    else
        return string_char( self.r, self.g, self.b, self.a )
    end
end

--- Returns the color as vector.
---@return Vector
function Color:toVector()
    return Vector( self.r * vconst, self.g * vconst, self.b * vconst )
end

--- Returns the color as HSL values (hue, saturation, lightness).
---@return number hue: The hue in degrees [0, 360].
---@return number saturation: The saturation as fraction [0, 1].
---@return number lightness: The lightness as fraction [0, 1].
function Color:toHSL()
    return ColorToHSL( self )
end

--- Returns the color as HSV values (hue, saturation, value).
---@return number hue: The hue in degrees [0, 360].
---@return number saturation: The saturation as fraction [0, 1].
---@return number value: The value as fraction [0, 1].
function Color:toHSV()
    return ColorToHSV( self )
end

--- Returns the color as HWB values (hue, whiteness, blackness).
---@return number hue: The hue in degrees [0, 360].
---@return number whiteness: The whiteness as fraction [0, 1].
---@return number blackness: The blackness as fraction [0, 1].
function Color:toHWB()
    local hue, saturation, brightness = self:toHSL()
    return hue, ( 1 - saturation ) * brightness, 1 - brightness
end

--- Returns the color as CMYK values (cyan, magenta, yellow, black).
---@return number cyan: The cyan as fraction [0, 1].
---@return number magenta: The magenta as fraction [0, 1].
---@return number yellow: The yellow as fraction [0, 1].
---@return number black: The black as fraction [0, 1].
function Color:toCMYK()
    local m = math_max( self.r, self.g, self.b )
    return ( m - self.r ) / m, ( m - self.g ) / m, ( m - self.b ) / m, math_min( self.r, self.g, self.b ) / 255
end

--- Smoothing a color object to another color object.
---@param color Color: The color to lerp.
---@param frac number: The fraction to lerp [0, 1].
---@param withAlpha boolean?: Whether to lerp alpha channel.
---@return Color
function Color:lerp( color, frac, withAlpha )
    frac = math_clamp( frac, 0, 1 )

    self.r = math_lerp( frac, self.r, color.r )
    self.g = math_lerp( frac, self.g, color.g )
    self.b = math_lerp( frac, self.b, color.b )

    if withAlpha then
        self.a = math_lerp( frac, self.a, color.a )
    end

    return self
end

--- Inverts current color.
---@return Color
function Color:invert()
    self.r, self.g, self.b = math_clamp( math_abs( 255 - self.r ), 0, 255 ), math_clamp( math_abs( 255 - self.g ), 0, 255 ), math_clamp( math_abs( 255 - self.b ), 0, 255 )
    return self
end


---@class gpm.std.ColorClass : gpm.std.Color
---@field __base Color
---@overload fun(r: number?, g: number?, b: number?, a: number?): gpm.std.Color
local ColorClass = std.class.create( Color )

--- Creates a color object from hex string.
---
--- Supports hex strings from `0` to `8` characters.
---@param hex string: The hex string. If the first character is `#`, it will be ignored.
---@return Color: The color object.
function ColorClass.fromHex( hex )
    if is_number( hex ) then
        return setmetatable(
            {
                r = bit_rshift( bit_band( hex, 0xFF0000 ), 16 ),
                g = bit_rshift( bit_band( hex, 0xFF00 ), 8 ),
                b = bit_band( hex, 0xFF ),
                a = 255
            },
            Color
        )
    end

    if string_byte( hex, 1 ) == 0x23 --[[ # ]] then
        hex = string_sub( hex, 2 )
    end

    local length = string_len( hex )
    if length == 1 then
        local r = string_byte( hex, 1 )
        return setmetatable(
            {
                r = tonumber( string_char( r, r ), 16 ),
                g = 0,
                b = 0,
                a = 255
            },
            Color
        )
    elseif length == 2 then
        local r, g = string_byte( hex, 1, 2 )
        return setmetatable(
            {
                r = tonumber( string_char( r, r ), 16 ),
                g = tonumber( string_char( g, g ), 16 ),
                b = 0,
                a = 255
            },
            Color
        )
    elseif length == 3 then
        local r, g, b = string_byte( hex, 1, 3 )
        return setmetatable(
            {
                r = tonumber( string_char( r, r ), 16 ),
                g = tonumber( string_char( g, g ), 16 ),
                b = tonumber( string_char( b, b ), 16 ),
                a = 255
            },
            Color
        )
    elseif length == 4 then
        local r, g, b, a = string_byte( hex, 1, 4 )
        return setmetatable(
            {
                r = tonumber( string_char( r, r ), 16 ),
                g = tonumber( string_char( g, g ), 16 ),
                b = tonumber( string_char( b, b ), 16 ),
                a = tonumber( string_char( a, a ), 16 )
            },
            Color
        )
    elseif length == 6 then
        return setmetatable(
            {
                r = tonumber( string_sub( hex, 1, 2 ), 16 ),
                g = tonumber( string_sub( hex, 3, 4 ), 16 ),
                b = tonumber( string_sub( hex, 5, 6 ), 16 ),
                a = 255
            },
            Color
        )
    elseif length == 8 then
        return setmetatable(
            {
                r = tonumber( string_sub( hex, 1, 2 ), 16 ),
                g = tonumber( string_sub( hex, 3, 4 ), 16 ),
                b = tonumber( string_sub( hex, 5, 6 ), 16 ),
                a = tonumber( string_sub( hex, 7, 8 ), 16 )
            },
            Color
        )
    else
        return setmetatable( { r = 0, g = 0, b = 0, a = 255 }, Color )
    end
end

--- Creates a color object from binary string.
---@param binary string: The binary string.
---@return Color: The color object.
function ColorClass.fromBinary( binary )
    local length = string_len( binary )
    if length == 1 then
        return setmetatable(
            {
                r = string_byte( binary, 1 ),
                g = 0,
                b = 0,
                a = 255
            },
            Color
        )
    elseif length == 2 then
        return setmetatable(
            {
                r = string_byte( binary, 1 ),
                g = string_byte( binary, 2 ),
                b = 0,
                a = 255
            },
            Color
        )
    elseif length == 3 then
        return setmetatable(
            {
                r = string_byte( binary, 1 ),
                g = string_byte( binary, 2 ),
                b = string_byte( binary, 3 ),
                a = 255
            },
            Color
        )
    else
        return setmetatable(
            {
                r = string_byte( binary, 1 ),
                g = string_byte( binary, 2 ),
                b = string_byte( binary, 3 ),
                a = string_byte( binary, 4 )
            },
            Color
        )
    end
end

--- Creates a color object from vector.
---@param vector Vector: The vector.
---@return Color: The color object.
function ColorClass.fromVector( vector )
    return setmetatable(
        {
            r = vector[ 1 ] * 255,
            g = vector[ 2 ] * 255,
            b = vector[ 3 ] * 255,
            a = 255
        },
        Color
    )
end

--- Creates a color object from HSL values.
---@param hue number: The hue in degrees [0, 360].
---@param saturation number: The saturation [0, 1].
---@param lightness number: The lightness [0, 1].
---@return Color: The color object.
function ColorClass.fromHSL( hue, saturation, lightness )
    return setmetatable( HSLToColor( hue, saturation, lightness ), Color )
end

--- Creates a color object from HSV values.
---@param hue number: The hue in degrees [0, 360].
---@param saturation number: The saturation [0, 1].
---@param brightness number: The brightness [0, 1].
---@return Color: The color object.
function ColorClass.fromHSV( hue, saturation, brightness )
    return setmetatable( HSVToColor( hue, saturation, brightness ), Color )
end

--- Creates a color object from HWB values.
---@param hue number: The hue in degrees [0, 360].
---@param saturation number: The saturation [0, 1].
---@param brightness number: The brightness [0, 1].
---@return Color: The color object.
function ColorClass.fromHWB( hue, saturation, brightness )
    return setmetatable( HSVToColor( hue, 1 - saturation / ( 1 - brightness ), 1 - brightness ), Color )
end

--- Creates a color object from CMYK values.
---@param cyan number: The cyan as fraction [0, 1].
---@param magenta number: The magenta as fraction [0, 1].
---@param yellow number: The yellow as fraction [0, 1].
---@param black number: The black as fraction [0, 1].
---@return Color: The color object.
function ColorClass.fromCMYK( cyan, magenta, yellow, black )
    cyan, magenta, yellow, black = cyan * 0.01, magenta * 0.01, yellow * 0.01, black * 0.01

    local mk = 1 - black
    return ColorClass(
        ( 1 - cyan ) * mk * 255,
        ( 1 - magenta ) * mk * 255,
        ( 1 - yellow ) * mk * 255
    )
end

--- Creates a color object from table.
---@param tbl number[] | table: The table.
---@return Color: The color object.
function ColorClass.fromTable( tbl )
    return ColorClass( tbl[ 1 ] or tbl.r, tbl[ 2 ] or tbl.g, tbl[ 3 ] or tbl.b, tbl[ 4 ] or tbl.a )
end

--- Creates a color object from lerp.
---@param frac number: The fraction [0, 1].
---@param a Color: The "from" color.
---@param b Color: The "to" color.
---@param withAlpha boolean: Whether to lerp alpha channel.
---@return Color: The color object.
function ColorClass.lerp( frac, a, b, withAlpha )
    frac = math_clamp( frac, 0, 1 )
    return ColorClass(
        math_lerp( frac, a.r, b.r ),
        math_lerp( frac, a.g, b.g ),
        math_lerp( frac, a.b, b.b ),
        withAlpha and math_lerp( frac, a.a, b.a ) or 255
    )
end

if std.CLIENT then
    do

        local render_ReadPixel = _G.render.ReadPixel

        --- Creates a color object from screen coordinates by reading a pixel.
        ---
        --- Requires `render.CapturePixels` call before using.
        ---
        ---@see https://wiki.facepunch.com/gmod/render.ReadPixel
        ---@param x integer: The x coordinate.
        ---@param y integer: The y coordinate.
        ---@param alpha number? The alpha channel.
        ---@return Color
        function ColorClass.fromScreen( x, y, alpha )
            local r, g, b, a = render_ReadPixel( x, y )
            return ColorClass( r, g, b, alpha or a )
        end

    end

    do

        local NamedColor = _G.NamedColor

        --- Creates a color object from `resource/ClientScheme.res`.
        ---@param name string
        ---@return Color?
        function ColorClass.fromScheme( name )
            local tbl = NamedColor( name )
            if tbl == nil then return end
            return setmetatable( tbl, Color )
        end

    end

end

return ColorClass
