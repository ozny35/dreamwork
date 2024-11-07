---@class math
---@field pi number A variable containing the mathematical constant pi. (3.1415926535898)
---@field e number A variable containing the mathematical constant Euler's number. (2.7182818284590)
---@field ln2 number A variable containing the mathematical constant natural logarithm of 2. (0.69314718055995)
---@field inf number A variable containing positive infinity. (inf)
---@field neg_inf number A variable containing negative infinity. (-inf)
---@field nan number A variable containing number "not a number". (nan)
---@field huge number The float value HUGE_VAL, a value larger than any other numeric value. (inf)
---@field ln10 number A variable containing the mathematical constant natural logarithm of 10. (2.3025850929940)
---@field log10e number A variable containing the mathematical constant logarithm of 10 to the base e. (0.43429448190325)
---@field log2e number A variable containing the mathematical constant logarithm of 2 to the base e. (1.4426950408889)
---@field sqrt2 number A variable containing the mathematical constant square root of 2. (1.4142135623731)
---@field sqrt1_2 number A variable containing the mathematical constant square root of 1/2. (0.70710678118655)
---@field maxinteger number A variable containing the maximum 32bit integer. (2147483647)
---@field mininteger number A variable containing the minimum 32bit integer. (-2147483648)
---@field geometry table Geometry functions and constants.
math = {}

---Returns the absolute value of x. (integer/float)
---@param x number The number to get the absolute value of.
---@return number
function math.abs( x ) return 0 end

---Returns the arc cosine of x (in radians).
---@param x number The number to get the arc cosine of.
---@return number
function math.acos( x ) return 0 end

---Returns the arc sine of x (in radians).
---@param x number The number to get the arc sine of.
---@return number
function math.asin( x ) return 0 end

---Returns the arc tangent of y/x (in radians), but uses the signs of both arguments to find the quadrant of the result. (It also handles correctly the case of x being zero.)
---
---The default value for x is 1, so that the call math.atan(y) returns the arc tangent of y.
---@param y number The number to get the arc tangent of.
---@param x number The number to get the arc tangent of.
---@return number
function math.atan( y, x ) return 0 end

---Returns the arc tangent of y/x (in radians), but uses the signs of both arguments to find the quadrant of the result. (It also handles correctly the case of x being zero.)
---
---The default value for x is 1, so that the call math.atan2(y) returns the arc tangent of y.
---@param y number The number to get the arc tangent of.
---@param x number The number to get the arc tangent of.
---@return number
---@see math.atan
---@deprecated
function math.atan2( y, x ) return 0 end

---Returns the smallest integral value larger than or equal to x.
---@param x number The number to get the ceiling of.
---@return number
function math.ceil( x ) return 0 end

---Returns the cosine of x (in radians).
---@param x number The number to get the cosine of.
---@return number
function math.cos( x ) return 0 end

---Converts the angle x from radians to degrees.
---@param x number The number to convert to degrees.
---@return number
function math.deg( x ) return 0 end

---Returns the value ex (where e is the base of natural logarithms).
---@param x number The number to get the exponential of.
---@return number
function math.exp( x ) return 0 end

---Returns the largest integral value smaller than or equal to x.
---@param x number The number to get the floor of.
---@return number
function math.floor( x ) return 0 end

---Returns the remainder of the division of x by y that rounds the quotient towards zero. (integer/float)
---@param x number The number to get the remainder of.
---@param y number The number to get the remainder of.
---@return number
function math.fmod( x, y ) return 0 end

---Returns the logarithm of x in the given base. The default for base is e (so that the function returns the natural logarithm of x).
---@param number number The number to get the logarithm of.
---@param base number The base to get the logarithm of.
---@return number
function math.log( number, base ) return 0 end

---Returns the argument with the maximum value, according to the Lua operator <. (integer/float)
---@param x number The first number to compare.
---@param y number The second number to compare.
---@return number
function math.max( x, y ) return 0 end

---Returns the argument with the minimum value, according to the Lua operator <. (integer/float)
---@param x number The first number to compare.
---@param y number The second number to compare.
---@return number
function math.min( x, y ) return 0 end

---Returns the integral part of x and the fractional part of x. Its second result is always a float.
---@param x number The number to get the integer and fractional parts of.
---@return number, number
function math.modf( x ) return 0, 0 end

---Converts the angle x from degrees to radians.
---@param x number The number to convert to radians.
---@return number
function math.rad( x ) return 0 end

---When called without arguments, returns a pseudo-random float with uniform distribution in the range [0,1). When called with two integers m and n, math.random returns a pseudo-random integer with uniform distribution in the range [m, n]. (The value n-m cannot be negative and must fit in a Lua integer.) The call math.random(n) is equivalent to math.random(1,n).
---
---This function is an interface to the underling pseudo-random generator function provided by C.
---@param m? number The minimum value.
---@param n? number The maximum value.
---@return number
---@diagnostic disable-next-line: redundant-parameter
function math.random( m, n ) return 0 end

---Sets x as the "seed" for the pseudo-random generator: equal seeds produce equal sequences of numbers.
---@param x number The seed to set.
function math.randomseed( x ) end

---Returns the sine of x (assumed to be in radians).
---@param x number The number to get the sine of.
---@return number
function math.sin( x ) return 0 end

---Returns the square root of x. (You can also use the expression x^0.5 to compute this value.)
---@param x number The number to get the square root of.
---@return number
function math.sqrt( x ) return 0 end

---Returns the tangent of x (assumed to be in radians).
---@param x number The number to get the tangent of.
---@return number
function math.tan( x ) return 0 end

---Returns "integer" if x is an integer, "float" if it is a float, or nil if x is not a number.
---@param x number The number to get the type of.
---@return "integer" | "float" | nil
function math.type( x ) return nil end

---Checks if a number is positive or negative infinity.
---@param x number The number to check.
---@return boolean
function math.isinf( x ) return false end

---Checks if a number is NaN.
---@param x number The number to check.
---@return boolean
function math.isnan( x ) return false end

---Checks if a number is finite.
---@param x number The number to check.
---@return boolean
function math.isfinite( x ) return false end

---Checks if a number is an unsigned integer.
---@param x number The number to check.
---@return boolean
function math.isuint( x ) return false end

---Checks if a number is an signed integer.
---@param x number The number to check.
---@return boolean
function math.isint( x ) return false end

---Checks if a number is a float.
---@param x number The number to check.
---@return boolean
function math.isfloat( x ) return false end

---Checks if two numbers are equal with a given tolerance.
---@param a number The first number to check.
---@param b number The second number to check.
---@param tolerance number The maximum difference between the numbers.
---@return boolean
function math.isequalwith( a, b, tolerance ) return false end

---Checks if a number is divisible by another number without remainder.
---@param a number The first number to check.
---@param b number The second number to check.
---@return boolean
function math.isdivideable( a, b ) return false end

---Checks if a number is a boolean.
---@param x number The number to check.
---@return boolean
function math.isbool( x ) return false end

---Checks if a number is even.
---@param x number The number to check.
---@return boolean
function math.iseven( x ) return false end

---Checks if a number is odd.
---@param x number The number to check.
---@return boolean
function math.isodd( x ) return false end

---Checks if a number is positive.
---@param x number The number to check.
---@return boolean
function math.ispositive( x ) return false end

---Checks if a number is negative.
---@param x number The number to check.
---@return boolean
function math.isnegative( x ) return false end

---Returns the sign of a number as 1 or -1.
---@param x number The number to check.
---@return number
function math.sign( x ) return 0 end

---Rounds the given value to the nearest whole number or to the given decimal places.
---@param number number The number to round.
---@param decimals? number The number of decimal places to round to.
---@return number
function math.round( number, decimals ) return 0 end

---Returns the smallest integer greater than or equal to the given number.
---@param number number The number to round.
---@param step number The step size to round to.
---@return number
function math.snap( number, step ) return 0 end

---Returns number without fractional part, ignoring the argument sign.
---@param number number The number to round.
---@param decimals? number The number of decimal places to round to.
---@return number
function math.trunc( number, decimals ) return 0 end

---Returns the natural logarithm of the given number.
---@param x number The number to calculate the logarithm of.
---@return number
function math.log1p( x ) return 0 end

---Returns the base 2 logarithm of the given number.
---@param x number The number to calculate the logarithm of.
---@return number
function math.log2( x ) return 0 end

---Returns a random floating point number in the range [a, b).
---@param a number The minimum value.
---@param b number The maximum value.
---@return number
function math.randomf( a, b ) return 0 end

---Returns floor division of two numbers. ( // from Lua 5.3 )
---@param a number The dividend.
---@param b number The divisor.
---@return number
function math.fdiv( a, b ) return 0 end

---Returns the square root of the sum of squares of its arguments.
---@vararg number The numbers to calculate the square root of.
---@return number
function math.hypot( ... ) return 0 end

---Returns the cube root of the given number.
---@param x number The number to calculate the cube root of.
---@return number
function math.cbrt( x ) return 0 end

---Returns the root of a given number with a given base.
---@param a number The number to calculate the root of.
---@param b number The base of the root.
---@return number
function math.root( a, b ) return 0 end

---Returns the fraction of where the current time is relative to the start and end times
---@param from number The start time.
---@param to number The end time.
---@param time number The current time.
---@return number
function math.timef( from, to, time ) return 0 end

---Gradually approaches the target value by the specified amount.
---@param current number The current value.
---@param target number The target value.
---@param change number The amount that the current value is allowed to change by to approach the target.
function math.approach( current, target, change ) return 0 end

---Splits a number into its integer and fractional parts.
---@param x number The number to split.
---@return number
function math.split( x ) return 0 end

---Clamps a number between a minimum and maximum value.
---@param number number The number to clamp.
---@param min number The minimum value.
---@param max number The maximum value.
---@return number
function math.clamp( number, min, max ) return 0 end

---Performs a linear interpolation from the start number to the end number.
---@param fraction number The fraction of the way between the start and end numbers.
---@param from number The start number.
---@param to number The end number.
---@return number
function math.lerp( fraction, from, to ) return 0 end

---Performs an inverse linear interpolation from the start number to the end number.
---@param fraction number The fraction of the way between the start and end numbers.
---@param from number The start number.
---@param to number The end number.
---@return number
function math.ilerp( fraction, from, to ) return 0 end

---Remaps a number from one range to another.
---@param number number The number to remap.
---@param inMin number The minimum value of the input range.
---@param inMax number The maximum value of the input range.
---@param outMin number The minimum value of the output range.
---@param outMax number The maximum value of the output range.
---@return number
function math.remap( number, inMin, inMax, outMin, outMax ) return 0 end

---Checks if a number is in a range.
---@param number number The number to check.
---@param from number The minimum value of the range.
---@param to number The maximum value of the range.
---@return boolean
function math.inrage( number, from, to ) return false end

---Calculates the angle between two points.
---@param x1 number The x coordinate of the first point.
---@param y1 number The y coordinate of the first point.
---@param x2 number The x coordinate of the second point.
---@param y2 number The y coordinate of the second point.
---@return number
function math.geometry.Angle( x1, y1, x2, y2 ) return 0 end

---Returns the normalised angle between two points.
---@param angle number The angle to normalise.
---@return number
function math.geometry.AngleNormal( angle ) return 0 end

---Returns the difference between two angles.
---@param a number The first angle.
---@param b number The second angle.
---@return number
function math.geometry.AngleDifference( a, b ) return 0 end

---Calculates the magnitude (distance) between two points.
---@param x1 number The x coordinate of the first point.
---@param y1 number The y coordinate of the first point.
---@param x2 number The x coordinate of the second point.
---@param y2 number The y coordinate of the second point.
---@return number
function math.geometry.Magnitude( x1, y1, x2, y2 ) return 0 end

---Calculates the direction between two points.
---@param x1 number The x coordinate of the first point.
---@param y1 number The y coordinate of the first point.
---@param x2 number The x coordinate of the second point.
---@param y2 number The y coordinate of the second point.
---@return number
function math.geometry.Direction( x1, y1, x2, y2 ) return 0 end

---Calculates the dot product between two points.
---@param x1 number The x coordinate of the first point.
---@param y1 number The y coordinate of the first point.
---@param x2 number The x coordinate of the second point.
---@param y2 number The y coordinate of the second point.
---@return number
function math.geometry.Dot( x1, y1, x2, y2 ) return 0 end

---Checks if a point is within a triangle.
---@param x1 number The x coordinate of the first point of the triangle.
---@param y1 number The y coordinate of the first point of the triangle.
---@param x2 number The x coordinate of the second point of the triangle.
---@param y2 number The y coordinate of the second point of the triangle.
---@param x3 number The x coordinate of the third point of the triangle.
---@param y3 number The y coordinate of the third point of the triangle.
---@return boolean
function math.geometry.TriangleSign( x1, y1, x2, y2, x3, y3 ) return false end

---Checks if a point is within a rectangle.
---@param x number The x coordinate of the first point of the rectangle.
---@param y number The y coordinate of the first point of the rectangle.
---@param x1 number The x coordinate of the second point of the rectangle.
---@param y1 number The y coordinate of the second point of the rectangle.
---@param x2 number The x coordinate of the third point of the rectangle.
---@param y2 number The y coordinate of the third point of the rectangle.
---@return boolean
function math.geometry.InRect( x, y, x1, y1, x2, y2 ) return false end

---Checks if a point is within a circle.
---@param x number The x coordinate of the point.
---@param y number The y coordinate of the point.
---@param cx number The x coordinate of the center of the circle.
---@param cy number The y coordinate of the center of the circle.
---@param r number The radius of the circle.
---@return boolean
function math.geometry.InCircle( x, y, cx, cy, r ) return false end

---Checks if the point is on the tangent.
---@param x number The x coordinate of the point to check.
---@param y number The y coordinate of the point to check.
---@param x1 number The x coordinate of the first point of the line.
---@param y1 number The y coordinate of the first point of the line.
---@param x2 number The x coordinate of the second point of the line.
---@param y2 number The y coordinate of the second point of the line.
---@return boolean
function math.geometry.OnTangent( x, y, x1, y1, x2, y2 ) return false end

---Checks if the point is in the triangle.
---@param x number The x coordinate of the point to check.
---@param y number The y coordinate of the point to check.
---@param x1 number The x coordinate of the first point of the triangle.
---@param y1 number The y coordinate of the first point of the triangle.
---@param x2 number The x coordinate of the second point of the triangle.
---@param y2 number The y coordinate of the second point of the triangle.
---@param x3 number The x coordinate of the third point of the triangle.
---@param y3 number The y coordinate of the third point of the triangle.
---@return boolean
function math.geometry.InTriangle( x, y, x1, y1, x2, y2, x3, y3 ) return false end

---Checks if the point is in the polygon.
---@param x number The x coordinate of the point to check.
---@param y number The y coordinate of the point to check.
---@param poly table The array of points of the polygon. [ [ x1, y1 ], [ x2, y2 ], [ x3, y3 ], ... ]
---@return boolean
function math.geometry.InPoly( x, y, poly ) return false end

---@class string
strint = {}

