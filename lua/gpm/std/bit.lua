local bit = ...
local bit_lshift, bit_rshift = bit.lshift, bit.rshift
-- https://github.com/Nak2/NikNaks/blob/c6b7d2ea5fade5a59b05801efb654e27f8dd25f2/lua/niknaks/modules/sh_bitbuffer.lua#L28-L39

return {
    ["arshift"] = bit.arshift,
    ["band"] = bit.band,
    ["bnot"] = bit.bnot,
    ["bor"] = bit.bor,
    ["bswap"] = bit.bswap,
    ["bxor"] = bit.bxor,
    ["lshift"] = function( number, shift ) return shift > 31 and 0x0 or bit_lshift( number, shift ) end,
    ["rol"] = bit.rol,
    ["ror"] = bit.ror,
    ["rshift"] = function( number, shift ) return shift > 31 and 0x0 or bit_rshift( number, shift ) end,
    ["tobit"] = bit.tobit,
    ["tohex"] = bit.tohex
}
