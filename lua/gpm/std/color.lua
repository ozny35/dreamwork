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

-- TODO: Find original author
local colorCorrection = {
    [ 0 ] = 0, 5, 8, 10, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22,
    22, -- lost 15
    23, 24, 25, 26, 27, 28,
    28, -- lost 22
    29, 30, 31, 32, 33, 34, 35,
    35, -- lost 30
    36, 37, 38, 39, 40, 41, 42,
    42, -- lost 38
    43, 44, 45, 46, 47, 48, 49, 50, 51,
    51, -- lost 48
    52, 53, 54, 55, 56, 57, 58, 59, 60,
    60, -- lost 58
    61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 73,
    73, -- lost 72
    74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88,
    88, -- lost 88
    89, 90, 91, 92, 93, 94, 95, 96, 97, 98, 99, 100, 101, 102, 103, 104, 105, 106, 107, 108, 109,
    109, -- lost 110
    111,
    111, -- lost 112
    113,
    113, -- lost 114
    114, 115, 116, 117, 118, 119, 120, 121, 122, 123, 124, 125, 126, 127, 128, 129, 130, 131, 132,
    133, 134, 135, 136, 137, 138, 139, 140, 141, 142, 143, 144, 145, 146, 147, 148, 149, 150, 151,
    152, 153, 154, 155, 156, 157,
    157, -- lost 159
    158, 159, 160, 162, 163, 164, 165,
    165, -- lost 167
    167, 168,
    168, -- lost 170
    170,
    170, -- lost 172
    172,
    172, -- lost 174
    174,
    174, -- lost 176
    176, 177,
    177, -- lost 179
    178, 180, 181, 182, 183, 184, 185, 186, 187, 188, 189, 190, 191, 192, 193, 194, 195, 196, 197,
    198, 199, 200, 201, 202, 203, 204, 205, 206, 207, 208, 209, 210, 211, 212, 213, 214, 215, 216,
    217, 218, 219, 220, 221, 222, 223, 224, 225, 226, 227, 228, 229, 230, 231, 232, 233, 234, 236, 237,
    237, -- lost 238
    238, 239, 241, 242, 243, 244, 245, 246, 247, 248, 249, 250, 251, 252, 253, 254, 255
}

local vconst = 1 / 255

-- TODO: write proper documentation

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
---@param r number?
---@param g number?
---@param b number?
---@param a number?
function Color:__init( r, g, b, a )
    r = math_clamp( r or 0, 0, 255 )

    self.r = r
    self.g = math_clamp( g or r, 0, 255 )
    self.b = math_clamp( b or r, 0, 255 )
    self.a = math_clamp( a or 255, 0, 255 )
end


---@private
function Color:__tostring()
    return string_format( "Color: %p [%d, %d, %d, %d]", self, self.r, self.g, self.b, self.a )
end

---@private
---@param other Color
function Color:__eq( other )
    return self.r == other.r and self.g == other.g and self.b == other.b and self.a == other.a
end

---@private
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
---@param other Color
function Color:__lt( other )
    return ( self.r + self.g + self.b + self.a ) < ( other.r + other.g + other.b + other.a )
end

---@private
---@param other Color
function Color:__le( other )
    return ( self.r + self.g + self.b + self.a ) <= ( other.r + other.g + other.b + other.a )
end

---@private
---@param value Color
function Color:__concat( value )
    return self:ToHex() .. tostring( value )
end

function Color:Unpack()
    return self.r, self.g, self.b, self.a
end

function Color:SetUnpacked(r, g, b, a)
    r = math_clamp( r or 0, 0, 255 )

    self.r = r
    self.g = math_clamp( g or r, 0, 255 )
    self.b = math_clamp( b or r, 0, 255 )
    self.a = math_clamp( a or 255, 0, 255 )
end

function Color:DoCorrection()
    self.r = colorCorrection[ self.r ]
    self.g = colorCorrection[ self.g ]
    self.b = colorCorrection[ self.b ]
    return self
end

function Color:Copy()
    return self.__class( self.r, self.g, self.b, self.a )
end

function Color:ToTable()
    return { self.r, self.g, self.b, self.a }
end

function Color:ToHex()
    return string_format( "#%02x%02x%02x", self.r, self.g, self.b )
end

function Color:ToBinary( withOutAlpha )
    if withOutAlpha then
        return string_char( self.r, self.g, self.b )
    else
        return string_char( self.r, self.g, self.b, self.a )
    end
end

function Color:ToVector()
    return Vector( self.r * vconst, self.g * vconst, self.b * vconst )
end

function Color:ToHSL()
    return ColorToHSL( self )
end

function Color:ToHSV()
    return ColorToHSV( self )
end

function Color:ToHWB()
    local hue, saturation, brightness = self:ToHSL()
    return hue, ( 100 - saturation ) * brightness, 100 - brightness
end

function Color:ToCMYK()
    local m = math_max( self.r, self.g, self.b )
    return ( m - self.r ) / m * 100, ( m - self.g ) / m * 100, ( m - self.b ) / m * 100, math_min( self.r, self.g, self.b ) / 2.55
end

function Color:Lerp( color, frac, withOutAlpha )
    frac = math_clamp( frac, 0, 1 )

    self.r = math_lerp( frac, self.r, color.r )
    self.g = math_lerp( frac, self.g, color.g )
    self.b = math_lerp( frac, self.b, color.b )

    if not withOutAlpha then
        self.a = math_lerp( frac, self.a, color.a )
    end

    return self
end

function Color:Invert()
    self.r, self.g, self.b = math_clamp( math_abs( 255 - self.r ), 0, 255 ), math_clamp( math_abs( 255 - self.g ), 0, 255 ), math_clamp( math_abs( 255 - self.b ), 0, 255 )
    return self
end


---@class gpm.std.ColorClass : gpm.std.Color
---@field __base Color
---@overload fun(r: number?, g: number?, b: number?, a: number?): gpm.std.Color
local ColorClass = std.class.create( Color )

function ColorClass.FromHex( hex )
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
    if length == 3 then
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

function ColorClass.FromBinary( binary )
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

function ColorClass.FromVector( vector )
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

function ColorClass.FromHSL( hue, saturation, lightness )
    return setmetatable( HSLToColor( hue, saturation, lightness ), Color )
end

function ColorClass.FromHSV( hue, saturation, brightness )
    return setmetatable( HSVToColor( hue, saturation, brightness ), Color )
end

function ColorClass.FromHWB( hue, saturation, brightness )
    return setmetatable( HSVToColor( hue, 1 - saturation / ( 1 - brightness ), 1 - brightness ), Color )
end

function ColorClass.FromCMYK( cyan, magenta, yellow, black )
    cyan, magenta, yellow, black = cyan * 0.01, magenta * 0.01, yellow * 0.01, black * 0.01

    local mk = 1 - black
    return ColorClass(
        ( 1 - cyan ) * mk * 255,
        ( 1 - magenta ) * mk * 255,
        ( 1 - yellow ) * mk * 255
    )
end

function ColorClass.FromTable( tbl )
    return ColorClass( tbl[ 1 ] or tbl.r, tbl[ 2 ] or tbl.g, tbl[ 3 ] or tbl.b, tbl[ 4 ] or tbl.a )
end

---@param frac number
function ColorClass.Lerp(frac, a, b, withOutAlpha)
    frac = math_clamp( frac, 0, 1 )
    return ColorClass(
        math_lerp( frac, a.r, b.r ),
        math_lerp( frac, a.g, b.g ),
        math_lerp( frac, a.b, b.b ),
        withOutAlpha and 255 or math_lerp( frac, a.a, b.a )
    )
end

if std.CLIENT then
    local render_ReadPixel = _G.render.ReadPixel

    -- TODO: ReadPixel needs CapturePixels called before
    function ColorClass.FromScreen(x, y, alpha)
        local r, g, b, a = render_ReadPixel(x, y)
        return ColorClass(r, g, b, alpha or a)
    end
end

-- TODO: https://wiki.facepunch.com/gmod/Global.NamedColor

return ColorClass
