local _G = _G
local ColorToHSL, HSLToColor, HSVToColor = _G.ColorToHSL, _G.HSLToColor, _G.HSVToColor
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

--- [SHARED AND MENU] The color class.
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
    ---@return number | function | nil
    function Color:__index( key )
        local index = key2index[ key ]
        if index == nil then
            return rawget( Color, key )
        else
            return rawget( self, index ) or 0
        end
    end

    ---@param key integer | string
    ---@param value number
    function Color:__newindex( key, value )
        local index = key2index[ key ]
        if index ~= nil then
            rawset( self, index, value )
        end
    end

end

---@protected
---@param r number?: The red color channel.
---@param g number?: The green color channel.
---@param b number?: The blue color channel.
---@param a number?: The alpha color channel.
function Color.__new( r, g, b, a )
    r = math_clamp( r or 0, 0, 255 )
    return setmetatable( {
        r,
        math_clamp( g or r, 0, 255 ),
        math_clamp( b or r, 0, 255 ),
        math_clamp( a or 255, 0, 255 )
    }, Color )
end

---@private
---@protected
function Color:__tostring()
    return string_format( "Color: %p [%d, %d, %d, %d]", self, self[ 1 ], self[ 2 ], self[ 3 ], self[ 4 ] )
end

---@private
---@protected
---@param other Color
function Color:__eq( other )
    return self[ 1 ] == other[ 1 ] and self[ 2 ] == other[ 2 ] and self[ 3 ] == other[ 3 ] and self[ 4 ] == other[ 4 ]
end

---@private
---@protected
function Color:__unm()
    return setmetatable(
        {
            math_clamp( math_abs( 255 - self[ 1 ] ), 0, 255 ),
            math_clamp( math_abs( 255 - self[ 2 ] ), 0, 255 ),
            math_clamp( math_abs( 255 - self[ 3 ] ), 0, 255 ),
            self[ 4 ]
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
            math_clamp( self[ 1 ] + color[ 1 ], 0, 255 ),
            math_clamp( self[ 2 ] + color[ 2 ], 0, 255 ),
            math_clamp( self[ 3 ] + color[ 3 ], 0, 255 ),
            self[ 4 ]
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
            math_clamp( self[ 1 ] - color[ 1 ], 0, 255 ),
            math_clamp( self[ 2 ] - color[ 2 ], 0, 255 ),
            math_clamp( self[ 3 ] - color[ 3 ], 0, 255 ),
            self[ 4 ]
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
                math_clamp( self[ 1 ] * other, 0, 255 ),
                math_clamp( self[ 2 ] * other, 0, 255 ),
                math_clamp( self[ 3 ] * other, 0, 255 ),
                self[ 4 ]
            },
            Color
        )
    else
        return setmetatable(
            {
                math_clamp( self[ 1 ] * other[ 1 ], 0, 255 ),
                math_clamp( self[ 2 ] * other[ 2 ], 0, 255 ),
                math_clamp( self[ 3 ] * other[ 3 ], 0, 255 ),
                self[ 4 ]
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
                math_clamp( self[ 1 ] / other, 0, 255 ),
                math_clamp( self[ 2 ] / other, 0, 255 ),
                math_clamp( self[ 3 ] / other, 0, 255 ),
                self[ 4 ]
            },
            Color
        )
    else
        return setmetatable(
            {
                math_clamp( self[ 1 ] / other[ 1 ], 0, 255 ),
                math_clamp( self[ 2 ] / other[ 2 ], 0, 255 ),
                math_clamp( self[ 3 ] / other[ 3 ], 0, 255 ),
                self[ 4 ]
            },
            Color
        )
    end
end

---@private
---@protected
---@param other Color
function Color:__lt( other )
    return ( self[ 1 ] + self[ 2 ] + self[ 3 ] + self[ 4 ] ) < ( other[ 1 ] + other[ 2 ] + other[ 3 ] + other[ 4 ] )
end

---@private
---@protected
---@param other Color
function Color:__le( other )
    return ( self[ 1 ] + self[ 2 ] + self[ 3 ] + self[ 4 ] ) <= ( other[ 1 ] + other[ 2 ] + other[ 3 ] + other[ 4 ] )
end

---@private
---@protected
---@param value Color
function Color:__concat( value )
    return self:toHex() .. tostring( value )
end

--- [SHARED AND MENU] Unpacks the color as r, g, b, a values.
---@return number
---@return number
---@return number
---@return number
function Color:unpack()
    return self[ 1 ], self[ 2 ], self[ 3 ], self[ 4 ]
end

--- [SHARED AND MENU] Set the color as r, g, b, a values.
---@param r number
---@param g number
---@param b number
---@param a number
function Color:setUnpacked( r, g, b, a )
    r = math_clamp( r or 0, 0, 255 )

    self[ 1 ] = r
    self[ 2 ] = math_clamp( g or r, 0, 255 )
    self[ 3 ] = math_clamp( b or r, 0, 255 )
    self[ 4 ] = math_clamp( a or 255, 0, 255 )
end

--- [SHARED AND MENU] Makes a copy of the color.
---@return gpm.std.Color
function Color:copy()
    return self.__class( self[ 1 ], self[ 2 ], self[ 3 ], self[ 4 ] )
end

--- [SHARED AND MENU] Returns the color as { r, g, b, a } table.
---@return table
function Color:toTable()
    return { self[ 1 ], self[ 2 ], self[ 3 ], self[ 4 ] }
end

--- [SHARED AND MENU] Returns the color as hex string.
---@return string
function Color:toHex()
    return string_format( "#%02x%02x%02x", self[ 1 ], self[ 2 ], self[ 3 ] )
end

--- [SHARED AND MENU] Returns the color as binary string.
---@param withOutAlpha boolean
---@return string
function Color:toBinary( withOutAlpha )
    if withOutAlpha then
        return string_char( self[ 1 ], self[ 2 ], self[ 3 ] )
    else
        return string_char( self[ 1 ], self[ 2 ], self[ 3 ], self[ 4 ] )
    end
end

--- [SHARED AND MENU] Returns the color as HSL values (hue, saturation, lightness).
---@return number hue: The hue in degrees [0, 360].
---@return number saturation: The saturation as fraction [0, 1].
---@return number lightness: The lightness as fraction [0, 1].
function Color:toHSL()
    return ColorToHSL( self )
end

--- [SHARED AND MENU] Returns the color as HSV values (hue, saturation, value).
---@return number hue: The hue in degrees [0, 360].
---@return number saturation: The saturation as fraction [0, 1].
---@return number value: The value as fraction [0, 1].
function Color:toHSV()
    return ColorToHSV( self )
end

--- [SHARED AND MENU] Returns the color as HWB values (hue, whiteness, blackness).
---@return number hue: The hue in degrees [0, 360].
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
    return ( m - self[ 1 ] ) / m, ( m - self[ 2 ] ) / m, ( m - self[ 3 ] ) / m, math_min( self[ 1 ], self[ 2 ], self[ 3 ] ) / 255
end

--- [SHARED AND MENU] Smoothing a color object to another color object.
---@param color Color: The color to lerp.
---@param frac number: The fraction to lerp [0, 1].
---@param withAlpha boolean?: Whether to lerp alpha channel.
---@return Color
function Color:lerp( color, frac, withAlpha )
    frac = math_clamp( frac, 0, 1 )

    self[ 1 ] = math_lerp( frac, self[ 1 ], color[ 1 ] )
    self[ 2 ] = math_lerp( frac, self[ 2 ], color[ 2 ] )
    self[ 3 ] = math_lerp( frac, self[ 3 ], color[ 3 ] )

    if withAlpha then
        self[ 4 ] = math_lerp( frac, self[ 4 ], color[ 4 ] )
    end

    return self
end

--- [SHARED AND MENU] Inverts current color.
---@return Color
function Color:invert()
    self[ 1 ], self[ 2 ], self[ 3 ] = math_clamp( math_abs( 255 - self[ 1 ] ), 0, 255 ), math_clamp( math_abs( 255 - self[ 2 ] ), 0, 255 ), math_clamp( math_abs( 255 - self[ 3 ] ), 0, 255 )
    return self
end


---@class gpm.std.ColorClass : gpm.std.Color
---@field __base Color
---@overload fun(r: number?, g: number?, b: number?, a: number?): gpm.std.Color
local ColorClass = std.class.create( Color )

--- [SHARED AND MENU] Creates a color object from hex string.
---
--- Supports hex strings from `0` to `8` characters.
---@param hex string: The hex string. If the first character is `#`, it will be ignored.
---@return Color: The color object.
function ColorClass.fromHex( hex )
    if is_number( hex ) then
        return setmetatable(
            {
                bit_rshift( bit_band( hex, 0xFF0000 ), 16 ),
                bit_rshift( bit_band( hex, 0xFF00 ), 8 ),
                bit_band( hex, 0xFF ),
                255
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
                tonumber( string_char( r, r ), 16 ),
                0,
                0,
                255
            },
            Color
        )
    elseif length == 2 then
        local r, g = string_byte( hex, 1, 2 )
        return setmetatable(
            {
                tonumber( string_char( r, r ), 16 ),
                tonumber( string_char( g, g ), 16 ),
                0,
                255
            },
            Color
        )
    elseif length == 3 then
        local r, g, b = string_byte( hex, 1, 3 )
        return setmetatable(
            {
                tonumber( string_char( r, r ), 16 ),
                tonumber( string_char( g, g ), 16 ),
                tonumber( string_char( b, b ), 16 ),
                255
            },
            Color
        )
    elseif length == 4 then
        local r, g, b, a = string_byte( hex, 1, 4 )
        return setmetatable(
            {
                tonumber( string_char( r, r ), 16 ),
                tonumber( string_char( g, g ), 16 ),
                tonumber( string_char( b, b ), 16 ),
                tonumber( string_char( a, a ), 16 )
            },
            Color
        )
    elseif length == 6 then
        return setmetatable(
            {
                tonumber( string_sub( hex, 1, 2 ), 16 ),
                tonumber( string_sub( hex, 3, 4 ), 16 ),
                tonumber( string_sub( hex, 5, 6 ), 16 ),
                255
            },
            Color
        )
    elseif length == 8 then
        return setmetatable(
            {
                tonumber( string_sub( hex, 1, 2 ), 16 ),
                tonumber( string_sub( hex, 3, 4 ), 16 ),
                tonumber( string_sub( hex, 5, 6 ), 16 ),
                tonumber( string_sub( hex, 7, 8 ), 16 )
            },
            Color
        )
    else
        return setmetatable( { 0, 0, 0, 255 }, Color )
    end
end

--- [SHARED AND MENU] Creates a color object from binary string.
---@param binary string: The binary string.
---@return Color: The color object.
function ColorClass.fromBinary( binary )
    local length = string_len( binary )
    if length == 1 then
        return setmetatable(
            {
                string_byte( binary, 1 ),
                0,
                0,
                255
            },
            Color
        )
    elseif length == 2 then
        return setmetatable(
            {
                string_byte( binary, 1 ),
                string_byte( binary, 2 ),
                0,
                255
            },
            Color
        )
    elseif length == 3 then
        return setmetatable(
            {
                string_byte( binary, 1 ),
                string_byte( binary, 2 ),
                string_byte( binary, 3 ),
                255
            },
            Color
        )
    else
        return setmetatable(
            {
                string_byte( binary, 1 ),
                string_byte( binary, 2 ),
                string_byte( binary, 3 ),
                string_byte( binary, 4 )
            },
            Color
        )
    end
end

--- [SHARED AND MENU] Creates a color object from HSL values.
---@param hue number: The hue in degrees [0, 360].
---@param saturation number: The saturation [0, 1].
---@param lightness number: The lightness [0, 1].
---@return Color: The color object.
function ColorClass.fromHSL( hue, saturation, lightness )
    return setmetatable( HSLToColor( hue, saturation, lightness ), Color )
end

--- [SHARED AND MENU] Creates a color object from HSV values.
---@param hue number: The hue in degrees [0, 360].
---@param saturation number: The saturation [0, 1].
---@param brightness number: The brightness [0, 1].
---@return Color: The color object.
function ColorClass.fromHSV( hue, saturation, brightness )
    return setmetatable( HSVToColor( hue, saturation, brightness ), Color )
end

--- [SHARED AND MENU] Creates a color object from HWB values.
---@param hue number: The hue in degrees [0, 360].
---@param saturation number: The saturation [0, 1].
---@param brightness number: The brightness [0, 1].
---@return Color: The color object.
function ColorClass.fromHWB( hue, saturation, brightness )
    return setmetatable( HSVToColor( hue, 1 - saturation / ( 1 - brightness ), 1 - brightness ), Color )
end

--- [SHARED AND MENU] Creates a color object from CMYK values.
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

--- [SHARED AND MENU] Creates a color object from table.
---@param tbl number[] | table: The table.
---@return Color: The color object.
function ColorClass.fromTable( tbl )
    return ColorClass( tbl[ 1 ] or tbl[ 1 ], tbl[ 2 ] or tbl[ 2 ], tbl[ 3 ] or tbl[ 3 ], tbl[ 4 ] or tbl[ 4 ] )
end

--- [SHARED AND MENU] Creates a color object from lerp.
---@param frac number: The fraction [0, 1].
---@param a Color: The "from" color.
---@param b Color: The "to" color.
---@param alpha number?: The alpha channel override [0, 255].
---@return Color: The color object.
function ColorClass.lerp( frac, a, b, alpha )
    frac = math_clamp( frac, 0, 1 )
    return ColorClass(
        math_lerp( frac, a[ 1 ], b[ 1 ] ),
        math_lerp( frac, a[ 2 ], b[ 2 ] ),
        math_lerp( frac, a[ 3 ], b[ 3 ] ),
        alpha or math_lerp( frac, a[ 4 ], b[ 4 ] )
    )
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
    ---@param alpha number? The alpha channel.
    ---@return Color
    function ColorClass.fromScreen( x, y, alpha )
        local r, g, b, a = render_ReadPixel( x, y )
        return ColorClass( r, g, b, alpha or a )
    end

    --- [CLIENT] Creates a color object from `resource/ClientScheme.res`.
    ---@param name string
    ---@return Color?
    function ColorClass.fromScheme( name )
        local tbl = NamedColor( name )
        if tbl == nil then return end
        return setmetatable( tbl, Color )
    end

end

return ColorClass
