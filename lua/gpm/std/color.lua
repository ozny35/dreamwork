local _G, class, bit, string, math, isnumber, setmetatable, COLOR = ...
local string_char, string_byte, string_format, string_len, string_sub = string.char, string.byte, string.format, string.len, string.sub
local error, Vector, ColorToHSL, HSLToColor, HSVToColor = _G.error, _G.Vector, _G.ColorToHSL, _G.HSLToColor, _G.HSVToColor
local math_abs, math_clamp, math_lerp, math_min, math_max = math.abs, math.clamp, math.lerp, math.min, math.max
local bit_band, bit_rshift = bit.band, bit.rshift

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

local internal = setmetatable(
    {
        ["__tostring"] = function( self )
            return string_format( "%d %d %d %d", self.r, self.g, self.b, self.a )
        end,
        ["__eq"] = function( self, other )
            return self.r == other.r and self.g == other.g and self.b == other.b and self.a == other.a
        end,
        ["__unm"] = function( self )
            return setmetatable( {
                ["r"] = math_clamp( math_abs( 255 - self.r ), 0, 255 ),
                ["g"] = math_clamp( math_abs( 255 - self.g ), 0, 255 ),
                ["b"] = math_clamp( math_abs( 255 - self.b ), 0, 255 ),
                ["a"] = self.a
            }, COLOR )
        end,
        ["__add"] = function( self, color )
            return setmetatable( {
                ["r"] = math_clamp( self.r + color.r, 0, 255 ),
                ["g"] = math_clamp( self.g + color.g, 0, 255 ),
                ["b"] = math_clamp( self.b + color.b, 0, 255 ),
                ["a"] = self.a
            }, COLOR )
        end,
        ["__sub"] = function( self, color )
            return setmetatable( {
                ["r"] = math_clamp( self.r - color.r, 0, 255 ),
                ["g"] = math_clamp( self.g - color.g, 0, 255 ),
                ["b"] = math_clamp( self.b - color.b, 0, 255 ),
                ["a"] = self.a
            }, COLOR )
        end,
        ["__mul"] = function( self, other )
            if isnumber( other ) then
                return setmetatable( {
                    ["r"] = math_clamp( self.r * other, 0, 255 ),
                    ["g"] = math_clamp( self.g * other, 0, 255 ),
                    ["b"] = math_clamp( self.b * other, 0, 255 ),
                    ["a"] = self.a
                }, COLOR )
            else
                return setmetatable( {
                    ["r"] = math_clamp( self.r * other.r, 0, 255 ),
                    ["g"] = math_clamp( self.g * other.g, 0, 255 ),
                    ["b"] = math_clamp( self.b * other.b, 0, 255 ),
                    ["a"] = self.a
                }, COLOR )
            end
        end,
        ["__div"] = function( self, other )
            if isnumber( other ) then
                return setmetatable( {
                    ["r"] = math_clamp( self.r / other, 0, 255 ),
                    ["g"] = math_clamp( self.g / other, 0, 255 ),
                    ["b"] = math_clamp( self.b / other, 0, 255 ),
                    ["a"] = self.a
                }, COLOR )
            else
                return setmetatable( {
                    ["r"] = math_clamp( self.r / other.r, 0, 255 ),
                    ["g"] = math_clamp( self.g / other.g, 0, 255 ),
                    ["b"] = math_clamp( self.b / other.b, 0, 255 ),
                    ["a"] = self.a
                }, COLOR )
            end
        end,
        ["__lt"] = function( self, other )
            return ( self.r + self.g + self.b + self.a ) < ( other.r + other.g + other.b + other.a )
        end,
        ["__le"] = function( self, other )
            return ( self.r + self.g + self.b + self.a ) <= ( other.r + other.g + other.b + other.a )
        end,
        ["__concat"] = function( self, value )
            return self:ToHex() .. tostring( value )
        end,
        ["new"] = function( self, r, g, b, a )
            r = math_clamp( r or 0, 0, 255 )

            self.r = r
            self.g = math_clamp( g or r, 0, 255 )
            self.b = math_clamp( b or r, 0, 255 )
            self.a = math_clamp( a or 255, 0, 255 )
        end,
        ["DoCorrection"] = function( self )
            self.r = colorCorrection[ self.r ]
            self.g = colorCorrection[ self.g ]
            self.b = colorCorrection[ self.b ]
            return self
        end,
        ["Copy"] = function( self )
            return setmetatable( { ["r"] = self.r, ["g"] = self.g, ["b"] = self.b, ["a"] = self.a }, COLOR )
        end,
        ["ToTable"] = function( self )
            return { self.r, self.g, self.b, self.a }
        end,
        ["ToHex"] = function( self )
            return string_format("#%02x%02x%02x", self.r, self.g, self.b)
        end,
        ["ToBinary"] = function( self, withOutAlpha )
            if withOutAlpha then
                return string_char( self.r, self.g, self.b )
            else
                return string_char( self.r, self.g, self.b, self.a )
            end
        end,
        ["ToVector"] = function( self )
            return Vector( self.r * vconst, self.g * vconst, self.b * vconst )
        end,
        ["ToHSL"] = ColorToHSL,
        ["ToHSV"] = _G.ColorToHSV,
        ["ToHWB"] = function( self )
            local hue, saturation, brightness = ColorToHSL( self )
            return hue, ( 100 - saturation ) * brightness, 100 - brightness
        end,
        ["ToCMYK"] = function( self )
            local m = math_max( self.r, self.g, self.b )
            return ( m - self.r ) / m * 100, ( m - self.g ) / m * 100, ( m - self.b ) / m * 100, math_min( self.r, self.g, self.b ) / 2.55
        end,
        ["Lerp"] = function( self, color, frac, withOutAlpha )
            frac = math_clamp( frac, 0, 1 )

            self.r = math_lerp( frac, self.r, color.r )
            self.g = math_lerp( frac, self.g, color.g )
            self.b = math_lerp( frac, self.b, color.b )

            if not withOutAlpha then
                self.a = math_lerp( frac, self.a, color.a )
            end

            return self
        end,
        ["Invert"] = function( self )
            self.r, self.g, self.b = math_clamp( math_abs( 255 - self.r ), 0, 255 ), math_clamp( math_abs( 255 - self.g ), 0, 255 ), math_clamp( math_abs( 255 - self.b ), 0, 255 )
            return self
        end
    },
    {
        ["__index"] = COLOR
    }
)

internal.__index = internal

return class( "Color", internal, {
    ["FromHex"] = function( hex )
        if isnumber( hex ) then
            return setmetatable( {
                ["r"] = bit_rshift( bit_band( hex, 0xFF0000 ), 16 ),
                ["g"] = bit_rshift( bit_band( hex, 0xFF00 ), 8 ),
                ["b"] = bit_band( hex, 0xFF ),
                ["a"] = 255
            }, COLOR )
        end

        if string_byte( hex, 1 ) == 0x23 --[[ # ]] then
            hex = string_sub( hex, 2 )
        end

        local length = string_len( hex )
        if length == 3 then
            local r, g, b = string_byte( hex, 1, 3 )
            return setmetatable( {
                ["r"] = tonumber( string_char( r, r ), 16 ),
                ["g"] = tonumber( string_char( g, g ), 16 ),
                ["b"] = tonumber( string_char( b, b ), 16 ),
                ["a"] = 255
            }, COLOR )
        elseif length == 4 then
            local r, g, b, a = string_byte( hex, 1, 4 )
            return setmetatable( {
                ["r"] = tonumber( string_char( r, r ), 16 ),
                ["g"] = tonumber( string_char( g, g ), 16 ),
                ["b"] = tonumber( string_char( b, b ), 16 ),
                ["a"] = tonumber( string_char( a, a ), 16 )
            }, COLOR )
        elseif length == 6 then
            return setmetatable( {
                ["r"] = tonumber( string_sub( hex, 1, 2 ), 16 ),
                ["g"] = tonumber( string_sub( hex, 3, 4 ), 16 ),
                ["b"] = tonumber( string_sub( hex, 5, 6 ), 16 ),
                ["a"] = 255
            }, COLOR )
        elseif length == 8 then
            return setmetatable( {
                ["r"] = tonumber( string_sub( hex, 1, 2 ), 16 ),
                ["g"] = tonumber( string_sub( hex, 3, 4 ), 16 ),
                ["b"] = tonumber( string_sub( hex, 5, 6 ), 16 ),
                ["a"] = tonumber( string_sub( hex, 7, 8 ), 16 )
            }, COLOR )
        else
            error( "Invalid hex", 2 )
        end
    end,
    ["FromBinary"] = function( binary, withOutAlpha )
        local length = string_len( binary )
        if length == 1 then
            return setmetatable( {
                ["r"] = string_byte( binary, 1 ),
                ["g"] = 0,
                ["b"] = 0,
                ["a"] = 255
            }, COLOR )
        elseif length == 2 then
            return setmetatable( {
                ["r"] = string_byte( binary, 1 ),
                ["g"] = string_byte( binary, 2 ),
                ["b"] = 0,
                ["a"] = 255
            }, COLOR )
        elseif length == 3 then
            return setmetatable( {
                ["r"] = string_byte( binary, 1 ),
                ["g"] = string_byte( binary, 2 ),
                ["b"] = string_byte( binary, 3 ),
                ["a"] = 255
            }, COLOR )
        else
            return setmetatable( {
                ["r"] = string_byte( binary, 1 ),
                ["g"] = string_byte( binary, 2 ),
                ["b"] = string_byte( binary, 3 ),
                ["a"] = string_byte( binary, 4 )
            }, COLOR )
        end
    end,
    ["FromVector"] = function( vector )
        return setmetatable( {
            ["r"] = vector[ 1 ] * 255,
            ["g"] = vector[ 2 ] * 255,
            ["b"] = vector[ 3 ] * 255,
            ["a"] = 255
        }, COLOR )
    end,
    ["FromHSL"] = function( hue, saturation, lightness )
        local tbl = HSLToColor( hue, saturation, lightness )
        return setmetatable( { ["r"] = tbl[ 1 ], ["g"] = tbl[ 2 ], ["b"] = tbl[ 3 ], ["a"] = tbl[ 4 ] }, COLOR )
    end,
    ["FromHSV"] = function( hue, saturation, brightness )
        local tbl = HSVToColor( hue, saturation, brightness )
        return setmetatable( { ["r"] = tbl[ 1 ], ["g"] = tbl[ 2 ], ["b"] = tbl[ 3 ], ["a"] = tbl[ 4 ] }, COLOR )
    end,
    ["FromHWB"] = function( hue, saturation, brightness )
        local tbl = HSVToColor( hue, 1 - saturation / ( 1 - brightness ), 1 - brightness )
        return setmetatable( { ["r"] = tbl[ 1 ], ["g"] = tbl[ 2 ], ["b"] = tbl[ 3 ], ["a"] = tbl[ 4 ] }, COLOR )
    end,
    ["FromCMYK"] = function( cyan, magenta, yellow, black )
        cyan, magenta, yellow, black = cyan * 0.01, magenta * 0.01, yellow * 0.01, black * 0.01

        local mk = 1 - black
        return setmetatable( {
            ["r"] = ( 1 - cyan ) * mk * 255,
            ["g"] = ( 1 - magenta ) * mk * 255,
            ["b"] = ( 1 - yellow ) * mk * 255,
            ["a"] = 255
        }, COLOR )
    end,
    ["FromTable"] = function( tbl )
        return setmetatable( {
            ["r"] = tbl[ 1 ] or tbl.r,
            ["g"] = tbl[ 2 ] or tbl.g,
            ["b"] = tbl[ 3 ] or tbl.b,
            ["a"] = tbl[ 4 ] or tbl.a
        }, COLOR )
    end,
    ["Lerp"] = function( frac, a, b, withOutAlpha )
        frac = math_clamp( frac, 0, 1 )
        return setmetatable( {
            ["r"] = math_lerp( frac, a.r, b.r ),
            ["g"] = math_lerp( frac, a.g, b.g ),
            ["b"] = math_lerp( frac, a.b, b.b ),
            ["a"] = withOutAlpha and 255 or math_lerp( frac, a.a, b.a )
        }, COLOR )
    end
} )
