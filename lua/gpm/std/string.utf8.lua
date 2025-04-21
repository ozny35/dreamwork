local std = _G.gpm.std
local select = std.select

local math_min, math_max
do
	local math = std.math
	math_min, math_max = math.min, math.max
end

local bit_band, bit_bor, bit_lshift, bit_rshift
do
	local bit = std.bit
	bit_band, bit_bor, bit_lshift, bit_rshift = bit.band, bit.bor, bit.lshift, bit.rshift
end

-- TODO: Rewrite this library

---@class gpm.std.string
local string = std.string
local string_char, string_byte, string_sub, string_gsub, string_gmatch, string_len = string.char, string.byte, string.sub, string.gsub, string.gmatch, string.len

local table = std.table
local table_concat, table_unpack = table.concat, table.unpack

local charpattern = "[%z\x01-\x7F\xC2-\xF4][\x80-\xBF]*"

--- Converts a UTF-8 byte to a character
---@param byte number
---@return string
local function byte2char( byte )
	if byte < 0x80 then
		return string_char( byte )
	elseif byte < 0x800 then
		return string_char( bit_bor( 0xC0, bit_band( bit_rshift( byte, 6 ), 0x1F ) ), bit_bor( 0x80, bit_band( byte, 0x3F ) ) )
	elseif byte < 0x10000 then
		return string_char( bit_bor( 0xE0, bit_band( bit_rshift( byte, 12 ), 0x0F ) ), bit_bor( 0x80, bit_band( bit_rshift( byte, 6 ), 0x3F ) ), bit_bor( 0x80, bit_band( byte, 0x3F ) ) )
	else
		return string_char( bit_bor( 0xF0, bit_band( bit_rshift( byte, 18 ), 0x07 ) ), bit_bor( 0x80, bit_band( bit_rshift( byte, 12 ), 0x3F ) ), bit_bor( 0x80, bit_band( bit_rshift( byte, 6 ), 0x3F ) ), bit_bor( 0x80, bit_band( byte, 0x3F ) ) )
	end
end

--- Converts a sequence of UTF-8 bytes to a string
---@param ... number: The UTF-8 bytes
---@return string: The resulting string
local function char_fn( ... )
	local length = select( "#", ... )
	if length == 0 then return "" end

	local args = { ... }
	for index = 1, length do
		---@diagnostic disable-next-line: assign-type-mismatch
		args[ index ] = byte2char( args[ index ] )
	end

	return table_concat( args, "", 1, length )
end

--- TODO
---@param index number
---@param stringLength number
---@return number
local function stringPosition( index, stringLength )
	if index > 0 then
		return math_min( index, stringLength )
	else
		if index == 0 then
			return 1
		else
			return math_max( stringLength + index + 1, 1 )
		end
	end
end

--- TODO
---@param str string
---@param stringStart? number
---@param stringLength number
---@return number?, number?, number?
local function decode( str, stringStart, stringLength )
	stringStart = stringPosition( stringStart or 1, stringLength )

	local byte1 = string_byte( str, stringStart )
	if byte1 == nil then return end
	if byte1 < 0x80 then return stringStart, stringStart, byte1 end
	if byte1 > 0xF4 or byte1 < 0xC2 then return end

	local contByteCount = byte1 >= 0xF0 and 3 or byte1 >= 0xE0 and 2 or byte1 >= 0xC0 and 1
	local stringEnd = stringStart + contByteCount
	if stringLength < stringEnd then return end

	local bytes, codePoint = { string_byte( str, stringStart + 1, stringEnd ) }, 0
	for index = 1, #bytes do
		local byte = bytes[ index ]
		if bit_band( byte, 0xC0 ) ~= 0x80 then return end
		codePoint = bit_bor( bit_lshift( codePoint, 6 ), bit_band( byte, 0x3F ) )
		byte1 = bit_lshift( byte1, 1 )
	end

	return stringStart, stringEnd, bit_bor( codePoint, bit_lshift( bit_band( byte1, 0x7F ), contByteCount * 5 ) )
end

--- TODO
---@param str string
---@param stringStart? number
---@param stringEnd? number
---@return string ...: The UTF-8 code points.
local function codepoint( str, stringStart, stringEnd )
	local stringLength = string_len( str )
	stringStart = stringPosition( stringStart or 1, stringLength )
	stringEnd = stringPosition( stringEnd or stringStart, stringLength )
	local buffer, length = {}, 0

	repeat
		local sequenceStart, sequenceEnd, codePoint = decode( str, stringStart, stringLength )
		if sequenceStart == nil then
			std.error( "invalid UTF-8 code", 2 )
		end

		stringStart = sequenceEnd + 1

		length = length + 1
		buffer[ length ] = codePoint
	until sequenceEnd >= stringEnd

	return table_unpack( buffer, 1, length )
end

--- TODO
---@param str string
---@param stringStart number?
---@param stringEnd number?
---@return number
local function len( str, stringStart, stringEnd )
	local stringLength = string_len( str )
	stringStart = stringPosition( stringStart or 1, stringLength )
	stringEnd = stringPosition( stringEnd or -1, stringLength )

	local length = 0

	if stringStart == 1 and stringEnd == stringLength then
		for _ in string_gmatch( str, charpattern ) do
			length = length + 1
		end

		return length
	end

	while stringEnd >= stringStart and stringStart <= stringLength do
		local sequenceStart, sequenceEnd = decode( str, stringStart, stringLength )
		if sequenceStart == nil then return length end
		stringStart = sequenceEnd + 1
		length = length + 1
	end

	return length
end

--- TODO
---@param str string
---@param offset number
---@param stringStart? number
---@return number?
local function offset_fn( str, offset, stringStart )
	local stringLength = string_len( str )
	local position = stringPosition( stringStart or ( ( offset >= 0 ) and 1 or stringLength ), stringLength )

	if offset == 0 then
		while position > 0 and decode( str, position, stringLength ) == nil do
			position = position - 1
		end

		return position
	end

	if decode( str, position, stringLength ) == nil then
		std.error( "initial position is a continuation byte", 2 )
	end

	if offset < 0 then
		for _ = 1, -offset do
			position = position - 1

			while position > 0 and decode( str, position, stringLength ) == nil do
				position = position - 1
			end
		end

		if position < 1 then
			return nil
		else
			return position
		end
	end

	if offset > 0 then
		for _ = 1, offset do
			position = position + 1

			while position <= stringLength and decode( str, position, stringLength ) == nil do
				position = position + 1
			end
		end

		if position > stringLength then
			return nil
		else
			return position
		end
	end
end

local lower2upper = {
	["a"] = "A",
	["b"] = "B",
	["c"] = "C",
	["d"] = "D",
	["e"] = "E",
	["f"] = "F",
	["g"] = "G",
	["h"] = "H",
	["i"] = "I",
	["j"] = "J",
	["k"] = "K",
	["l"] = "L",
	["m"] = "M",
	["n"] = "N",
	["o"] = "O",
	["p"] = "P",
	["q"] = "Q",
	["r"] = "R",
	["s"] = "S",
	["t"] = "T",
	["u"] = "U",
	["v"] = "V",
	["w"] = "W",
	["x"] = "X",
	["y"] = "Y",
	["z"] = "Z",
	["µ"] = "Μ",
	["à"] = "À",
	["á"] = "Á",
	["â"] = "Â",
	["ã"] = "Ã",
	["ä"] = "Ä",
	["å"] = "Å",
	["æ"] = "Æ",
	["ç"] = "Ç",
	["è"] = "È",
	["é"] = "É",
	["ê"] = "Ê",
	["ë"] = "Ë",
	["ì"] = "Ì",
	["í"] = "Í",
	["î"] = "Î",
	["ï"] = "Ï",
	["ð"] = "Ð",
	["ñ"] = "Ñ",
	["ò"] = "Ò",
	["ó"] = "Ó",
	["ô"] = "Ô",
	["õ"] = "Õ",
	["ö"] = "Ö",
	["ø"] = "Ø",
	["ù"] = "Ù",
	["ú"] = "Ú",
	["û"] = "Û",
	["ü"] = "Ü",
	["ý"] = "Ý",
	["þ"] = "Þ",
	["ÿ"] = "Ÿ",
	["ā"] = "Ā",
	["ă"] = "Ă",
	["ą"] = "Ą",
	["ć"] = "Ć",
	["ĉ"] = "Ĉ",
	["ċ"] = "Ċ",
	["č"] = "Č",
	["ď"] = "Ď",
	["đ"] = "Đ",
	["ē"] = "Ē",
	["ĕ"] = "Ĕ",
	["ė"] = "Ė",
	["ę"] = "Ę",
	["ě"] = "Ě",
	["ĝ"] = "Ĝ",
	["ğ"] = "Ğ",
	["ġ"] = "Ġ",
	["ģ"] = "Ģ",
	["ĥ"] = "Ĥ",
	["ħ"] = "Ħ",
	["ĩ"] = "Ĩ",
	["ī"] = "Ī",
	["ĭ"] = "Ĭ",
	["į"] = "Į",
	["ı"] = "I",
	["ĳ"] = "Ĳ",
	["ĵ"] = "Ĵ",
	["ķ"] = "Ķ",
	["ĺ"] = "Ĺ",
	["ļ"] = "Ļ",
	["ľ"] = "Ľ",
	["ŀ"] = "Ŀ",
	["ł"] = "Ł",
	["ń"] = "Ń",
	["ņ"] = "Ņ",
	["ň"] = "Ň",
	["ŋ"] = "Ŋ",
	["ō"] = "Ō",
	["ŏ"] = "Ŏ",
	["ő"] = "Ő",
	["œ"] = "Œ",
	["ŕ"] = "Ŕ",
	["ŗ"] = "Ŗ",
	["ř"] = "Ř",
	["ś"] = "Ś",
	["ŝ"] = "Ŝ",
	["ş"] = "Ş",
	["š"] = "Š",
	["ţ"] = "Ţ",
	["ť"] = "Ť",
	["ŧ"] = "Ŧ",
	["ũ"] = "Ũ",
	["ū"] = "Ū",
	["ŭ"] = "Ŭ",
	["ů"] = "Ů",
	["ű"] = "Ű",
	["ų"] = "Ų",
	["ŵ"] = "Ŵ",
	["ŷ"] = "Ŷ",
	["ź"] = "Ź",
	["ż"] = "Ż",
	["ž"] = "Ž",
	["ſ"] = "S",
	["ƀ"] = "Ƀ",
	["ƃ"] = "Ƃ",
	["ƅ"] = "Ƅ",
	["ƈ"] = "Ƈ",
	["ƌ"] = "Ƌ",
	["ƒ"] = "Ƒ",
	["ƕ"] = "Ƕ",
	["ƙ"] = "Ƙ",
	["ƚ"] = "Ƚ",
	["ƞ"] = "Ƞ",
	["ơ"] = "Ơ",
	["ƣ"] = "Ƣ",
	["ƥ"] = "Ƥ",
	["ƨ"] = "Ƨ",
	["ƭ"] = "Ƭ",
	["ư"] = "Ư",
	["ƴ"] = "Ƴ",
	["ƶ"] = "Ƶ",
	["ƹ"] = "Ƹ",
	["ƽ"] = "Ƽ",
	["ƿ"] = "Ƿ",
	["ǅ"] = "Ǆ",
	["ǆ"] = "Ǆ",
	["ǈ"] = "Ǉ",
	["ǉ"] = "Ǉ",
	["ǋ"] = "Ǌ",
	["ǌ"] = "Ǌ",
	["ǎ"] = "Ǎ",
	["ǐ"] = "Ǐ",
	["ǒ"] = "Ǒ",
	["ǔ"] = "Ǔ",
	["ǖ"] = "Ǖ",
	["ǘ"] = "Ǘ",
	["ǚ"] = "Ǚ",
	["ǜ"] = "Ǜ",
	["ǝ"] = "Ǝ",
	["ǟ"] = "Ǟ",
	["ǡ"] = "Ǡ",
	["ǣ"] = "Ǣ",
	["ǥ"] = "Ǥ",
	["ǧ"] = "Ǧ",
	["ǩ"] = "Ǩ",
	["ǫ"] = "Ǫ",
	["ǭ"] = "Ǭ",
	["ǯ"] = "Ǯ",
	["ǲ"] = "Ǳ",
	["ǳ"] = "Ǳ",
	["ǵ"] = "Ǵ",
	["ǹ"] = "Ǹ",
	["ǻ"] = "Ǻ",
	["ǽ"] = "Ǽ",
	["ǿ"] = "Ǿ",
	["ȁ"] = "Ȁ",
	["ȃ"] = "Ȃ",
	["ȅ"] = "Ȅ",
	["ȇ"] = "Ȇ",
	["ȉ"] = "Ȉ",
	["ȋ"] = "Ȋ",
	["ȍ"] = "Ȍ",
	["ȏ"] = "Ȏ",
	["ȑ"] = "Ȑ",
	["ȓ"] = "Ȓ",
	["ȕ"] = "Ȕ",
	["ȗ"] = "Ȗ",
	["ș"] = "Ș",
	["ț"] = "Ț",
	["ȝ"] = "Ȝ",
	["ȟ"] = "Ȟ",
	["ȣ"] = "Ȣ",
	["ȥ"] = "Ȥ",
	["ȧ"] = "Ȧ",
	["ȩ"] = "Ȩ",
	["ȫ"] = "Ȫ",
	["ȭ"] = "Ȭ",
	["ȯ"] = "Ȯ",
	["ȱ"] = "Ȱ",
	["ȳ"] = "Ȳ",
	["ȼ"] = "Ȼ",
	["ɂ"] = "Ɂ",
	["ɇ"] = "Ɇ",
	["ɉ"] = "Ɉ",
	["ɋ"] = "Ɋ",
	["ɍ"] = "Ɍ",
	["ɏ"] = "Ɏ",
	["ɓ"] = "Ɓ",
	["ɔ"] = "Ɔ",
	["ɖ"] = "Ɖ",
	["ɗ"] = "Ɗ",
	["ə"] = "Ə",
	["ɛ"] = "Ɛ",
	["ɠ"] = "Ɠ",
	["ɣ"] = "Ɣ",
	["ɨ"] = "Ɨ",
	["ɩ"] = "Ɩ",
	["ɫ"] = "Ɫ",
	["ɯ"] = "Ɯ",
	["ɲ"] = "Ɲ",
	["ɵ"] = "Ɵ",
	["ɽ"] = "Ɽ",
	["ʀ"] = "Ʀ",
	["ʃ"] = "Ʃ",
	["ʈ"] = "Ʈ",
	["ʉ"] = "Ʉ",
	["ʊ"] = "Ʊ",
	["ʋ"] = "Ʋ",
	["ʌ"] = "Ʌ",
	["ʒ"] = "Ʒ",
	["ͅ"] = "Ι",
	["ͻ"] = "Ͻ",
	["ͼ"] = "Ͼ",
	["ͽ"] = "Ͽ",
	["ά"] = "Ά",
	["έ"] = "Έ",
	["ή"] = "Ή",
	["ί"] = "Ί",
	["α"] = "Α",
	["β"] = "Β",
	["γ"] = "Γ",
	["δ"] = "Δ",
	["ε"] = "Ε",
	["ζ"] = "Ζ",
	["η"] = "Η",
	["θ"] = "Θ",
	["ι"] = "Ι",
	["κ"] = "Κ",
	["λ"] = "Λ",
	["μ"] = "Μ",
	["ν"] = "Ν",
	["ξ"] = "Ξ",
	["ο"] = "Ο",
	["π"] = "Π",
	["ρ"] = "Ρ",
	["ς"] = "Σ",
	["σ"] = "Σ",
	["τ"] = "Τ",
	["υ"] = "Υ",
	["φ"] = "Φ",
	["χ"] = "Χ",
	["ψ"] = "Ψ",
	["ω"] = "Ω",
	["ϊ"] = "Ϊ",
	["ϋ"] = "Ϋ",
	["ό"] = "Ό",
	["ύ"] = "Ύ",
	["ώ"] = "Ώ",
	["ϐ"] = "Β",
	["ϑ"] = "Θ",
	["ϕ"] = "Φ",
	["ϖ"] = "Π",
	["ϙ"] = "Ϙ",
	["ϛ"] = "Ϛ",
	["ϝ"] = "Ϝ",
	["ϟ"] = "Ϟ",
	["ϡ"] = "Ϡ",
	["ϣ"] = "Ϣ",
	["ϥ"] = "Ϥ",
	["ϧ"] = "Ϧ",
	["ϩ"] = "Ϩ",
	["ϫ"] = "Ϫ",
	["ϭ"] = "Ϭ",
	["ϯ"] = "Ϯ",
	["ϰ"] = "Κ",
	["ϱ"] = "Ρ",
	["ϲ"] = "Ϲ",
	["ϵ"] = "Ε",
	["ϸ"] = "Ϸ",
	["ϻ"] = "Ϻ",
	["а"] = "А",
	["б"] = "Б",
	["в"] = "В",
	["г"] = "Г",
	["д"] = "Д",
	["е"] = "Е",
	["ж"] = "Ж",
	["з"] = "З",
	["и"] = "И",
	["й"] = "Й",
	["к"] = "К",
	["л"] = "Л",
	["м"] = "М",
	["н"] = "Н",
	["о"] = "О",
	["п"] = "П",
	["р"] = "Р",
	["с"] = "С",
	["т"] = "Т",
	["у"] = "У",
	["ф"] = "Ф",
	["х"] = "Х",
	["ц"] = "Ц",
	["ч"] = "Ч",
	["ш"] = "Ш",
	["щ"] = "Щ",
	["ъ"] = "Ъ",
	["ы"] = "Ы",
	["ь"] = "Ь",
	["э"] = "Э",
	["ю"] = "Ю",
	["я"] = "Я",
	["ѐ"] = "Ѐ",
	["ё"] = "Ё",
	["ђ"] = "Ђ",
	["ѓ"] = "Ѓ",
	["є"] = "Є",
	["ѕ"] = "Ѕ",
	["і"] = "І",
	["ї"] = "Ї",
	["ј"] = "Ј",
	["љ"] = "Љ",
	["њ"] = "Њ",
	["ћ"] = "Ћ",
	["ќ"] = "Ќ",
	["ѝ"] = "Ѝ",
	["ў"] = "Ў",
	["џ"] = "Џ",
	["ѡ"] = "Ѡ",
	["ѣ"] = "Ѣ",
	["ѥ"] = "Ѥ",
	["ѧ"] = "Ѧ",
	["ѩ"] = "Ѩ",
	["ѫ"] = "Ѫ",
	["ѭ"] = "Ѭ",
	["ѯ"] = "Ѯ",
	["ѱ"] = "Ѱ",
	["ѳ"] = "Ѳ",
	["ѵ"] = "Ѵ",
	["ѷ"] = "Ѷ",
	["ѹ"] = "Ѹ",
	["ѻ"] = "Ѻ",
	["ѽ"] = "Ѽ",
	["ѿ"] = "Ѿ",
	["ҁ"] = "Ҁ",
	["ҋ"] = "Ҋ",
	["ҍ"] = "Ҍ",
	["ҏ"] = "Ҏ",
	["ґ"] = "Ґ",
	["ғ"] = "Ғ",
	["ҕ"] = "Ҕ",
	["җ"] = "Җ",
	["ҙ"] = "Ҙ",
	["қ"] = "Қ",
	["ҝ"] = "Ҝ",
	["ҟ"] = "Ҟ",
	["ҡ"] = "Ҡ",
	["ң"] = "Ң",
	["ҥ"] = "Ҥ",
	["ҧ"] = "Ҧ",
	["ҩ"] = "Ҩ",
	["ҫ"] = "Ҫ",
	["ҭ"] = "Ҭ",
	["ү"] = "Ү",
	["ұ"] = "Ұ",
	["ҳ"] = "Ҳ",
	["ҵ"] = "Ҵ",
	["ҷ"] = "Ҷ",
	["ҹ"] = "Ҹ",
	["һ"] = "Һ",
	["ҽ"] = "Ҽ",
	["ҿ"] = "Ҿ",
	["ӂ"] = "Ӂ",
	["ӄ"] = "Ӄ",
	["ӆ"] = "Ӆ",
	["ӈ"] = "Ӈ",
	["ӊ"] = "Ӊ",
	["ӌ"] = "Ӌ",
	["ӎ"] = "Ӎ",
	["ӏ"] = "Ӏ",
	["ӑ"] = "Ӑ",
	["ӓ"] = "Ӓ",
	["ӕ"] = "Ӕ",
	["ӗ"] = "Ӗ",
	["ә"] = "Ә",
	["ӛ"] = "Ӛ",
	["ӝ"] = "Ӝ",
	["ӟ"] = "Ӟ",
	["ӡ"] = "Ӡ",
	["ӣ"] = "Ӣ",
	["ӥ"] = "Ӥ",
	["ӧ"] = "Ӧ",
	["ө"] = "Ө",
	["ӫ"] = "Ӫ",
	["ӭ"] = "Ӭ",
	["ӯ"] = "Ӯ",
	["ӱ"] = "Ӱ",
	["ӳ"] = "Ӳ",
	["ӵ"] = "Ӵ",
	["ӷ"] = "Ӷ",
	["ӹ"] = "Ӹ",
	["ӻ"] = "Ӻ",
	["ӽ"] = "Ӽ",
	["ӿ"] = "Ӿ",
	["ԁ"] = "Ԁ",
	["ԃ"] = "Ԃ",
	["ԅ"] = "Ԅ",
	["ԇ"] = "Ԇ",
	["ԉ"] = "Ԉ",
	["ԋ"] = "Ԋ",
	["ԍ"] = "Ԍ",
	["ԏ"] = "Ԏ",
	["ԑ"] = "Ԑ",
	["ԓ"] = "Ԓ",
	["ա"] = "Ա",
	["բ"] = "Բ",
	["գ"] = "Գ",
	["դ"] = "Դ",
	["ե"] = "Ե",
	["զ"] = "Զ",
	["է"] = "Է",
	["ը"] = "Ը",
	["թ"] = "Թ",
	["ժ"] = "Ժ",
	["ի"] = "Ի",
	["լ"] = "Լ",
	["խ"] = "Խ",
	["ծ"] = "Ծ",
	["կ"] = "Կ",
	["հ"] = "Հ",
	["ձ"] = "Ձ",
	["ղ"] = "Ղ",
	["ճ"] = "Ճ",
	["մ"] = "Մ",
	["յ"] = "Յ",
	["ն"] = "Ն",
	["շ"] = "Շ",
	["ո"] = "Ո",
	["չ"] = "Չ",
	["պ"] = "Պ",
	["ջ"] = "Ջ",
	["ռ"] = "Ռ",
	["ս"] = "Ս",
	["վ"] = "Վ",
	["տ"] = "Տ",
	["ր"] = "Ր",
	["ց"] = "Ց",
	["ւ"] = "Ւ",
	["փ"] = "Փ",
	["ք"] = "Ք",
	["օ"] = "Օ",
	["ֆ"] = "Ֆ",
	["ᵽ"] = "Ᵽ",
	["ḁ"] = "Ḁ",
	["ḃ"] = "Ḃ",
	["ḅ"] = "Ḅ",
	["ḇ"] = "Ḇ",
	["ḉ"] = "Ḉ",
	["ḋ"] = "Ḋ",
	["ḍ"] = "Ḍ",
	["ḏ"] = "Ḏ",
	["ḑ"] = "Ḑ",
	["ḓ"] = "Ḓ",
	["ḕ"] = "Ḕ",
	["ḗ"] = "Ḗ",
	["ḙ"] = "Ḙ",
	["ḛ"] = "Ḛ",
	["ḝ"] = "Ḝ",
	["ḟ"] = "Ḟ",
	["ḡ"] = "Ḡ",
	["ḣ"] = "Ḣ",
	["ḥ"] = "Ḥ",
	["ḧ"] = "Ḧ",
	["ḩ"] = "Ḩ",
	["ḫ"] = "Ḫ",
	["ḭ"] = "Ḭ",
	["ḯ"] = "Ḯ",
	["ḱ"] = "Ḱ",
	["ḳ"] = "Ḳ",
	["ḵ"] = "Ḵ",
	["ḷ"] = "Ḷ",
	["ḹ"] = "Ḹ",
	["ḻ"] = "Ḻ",
	["ḽ"] = "Ḽ",
	["ḿ"] = "Ḿ",
	["ṁ"] = "Ṁ",
	["ṃ"] = "Ṃ",
	["ṅ"] = "Ṅ",
	["ṇ"] = "Ṇ",
	["ṉ"] = "Ṉ",
	["ṋ"] = "Ṋ",
	["ṍ"] = "Ṍ",
	["ṏ"] = "Ṏ",
	["ṑ"] = "Ṑ",
	["ṓ"] = "Ṓ",
	["ṕ"] = "Ṕ",
	["ṗ"] = "Ṗ",
	["ṙ"] = "Ṙ",
	["ṛ"] = "Ṛ",
	["ṝ"] = "Ṝ",
	["ṟ"] = "Ṟ",
	["ṡ"] = "Ṡ",
	["ṣ"] = "Ṣ",
	["ṥ"] = "Ṥ",
	["ṧ"] = "Ṧ",
	["ṩ"] = "Ṩ",
	["ṫ"] = "Ṫ",
	["ṭ"] = "Ṭ",
	["ṯ"] = "Ṯ",
	["ṱ"] = "Ṱ",
	["ṳ"] = "Ṳ",
	["ṵ"] = "Ṵ",
	["ṷ"] = "Ṷ",
	["ṹ"] = "Ṹ",
	["ṻ"] = "Ṻ",
	["ṽ"] = "Ṽ",
	["ṿ"] = "Ṿ",
	["ẁ"] = "Ẁ",
	["ẃ"] = "Ẃ",
	["ẅ"] = "Ẅ",
	["ẇ"] = "Ẇ",
	["ẉ"] = "Ẉ",
	["ẋ"] = "Ẋ",
	["ẍ"] = "Ẍ",
	["ẏ"] = "Ẏ",
	["ẑ"] = "Ẑ",
	["ẓ"] = "Ẓ",
	["ẕ"] = "Ẕ",
	["ẛ"] = "Ṡ",
	["ạ"] = "Ạ",
	["ả"] = "Ả",
	["ấ"] = "Ấ",
	["ầ"] = "Ầ",
	["ẩ"] = "Ẩ",
	["ẫ"] = "Ẫ",
	["ậ"] = "Ậ",
	["ắ"] = "Ắ",
	["ằ"] = "Ằ",
	["ẳ"] = "Ẳ",
	["ẵ"] = "Ẵ",
	["ặ"] = "Ặ",
	["ẹ"] = "Ẹ",
	["ẻ"] = "Ẻ",
	["ẽ"] = "Ẽ",
	["ế"] = "Ế",
	["ề"] = "Ề",
	["ể"] = "Ể",
	["ễ"] = "Ễ",
	["ệ"] = "Ệ",
	["ỉ"] = "Ỉ",
	["ị"] = "Ị",
	["ọ"] = "Ọ",
	["ỏ"] = "Ỏ",
	["ố"] = "Ố",
	["ồ"] = "Ồ",
	["ổ"] = "Ổ",
	["ỗ"] = "Ỗ",
	["ộ"] = "Ộ",
	["ớ"] = "Ớ",
	["ờ"] = "Ờ",
	["ở"] = "Ở",
	["ỡ"] = "Ỡ",
	["ợ"] = "Ợ",
	["ụ"] = "Ụ",
	["ủ"] = "Ủ",
	["ứ"] = "Ứ",
	["ừ"] = "Ừ",
	["ử"] = "Ử",
	["ữ"] = "Ữ",
	["ự"] = "Ự",
	["ỳ"] = "Ỳ",
	["ỵ"] = "Ỵ",
	["ỷ"] = "Ỷ",
	["ỹ"] = "Ỹ",
	["ἀ"] = "Ἀ",
	["ἁ"] = "Ἁ",
	["ἂ"] = "Ἂ",
	["ἃ"] = "Ἃ",
	["ἄ"] = "Ἄ",
	["ἅ"] = "Ἅ",
	["ἆ"] = "Ἆ",
	["ἇ"] = "Ἇ",
	["ἐ"] = "Ἐ",
	["ἑ"] = "Ἑ",
	["ἒ"] = "Ἒ",
	["ἓ"] = "Ἓ",
	["ἔ"] = "Ἔ",
	["ἕ"] = "Ἕ",
	["ἠ"] = "Ἠ",
	["ἡ"] = "Ἡ",
	["ἢ"] = "Ἢ",
	["ἣ"] = "Ἣ",
	["ἤ"] = "Ἤ",
	["ἥ"] = "Ἥ",
	["ἦ"] = "Ἦ",
	["ἧ"] = "Ἧ",
	["ἰ"] = "Ἰ",
	["ἱ"] = "Ἱ",
	["ἲ"] = "Ἲ",
	["ἳ"] = "Ἳ",
	["ἴ"] = "Ἴ",
	["ἵ"] = "Ἵ",
	["ἶ"] = "Ἶ",
	["ἷ"] = "Ἷ",
	["ὀ"] = "Ὀ",
	["ὁ"] = "Ὁ",
	["ὂ"] = "Ὂ",
	["ὃ"] = "Ὃ",
	["ὄ"] = "Ὄ",
	["ὅ"] = "Ὅ",
	["ὑ"] = "Ὑ",
	["ὓ"] = "Ὓ",
	["ὕ"] = "Ὕ",
	["ὗ"] = "Ὗ",
	["ὠ"] = "Ὠ",
	["ὡ"] = "Ὡ",
	["ὢ"] = "Ὢ",
	["ὣ"] = "Ὣ",
	["ὤ"] = "Ὤ",
	["ὥ"] = "Ὥ",
	["ὦ"] = "Ὦ",
	["ὧ"] = "Ὧ",
	["ὰ"] = "Ὰ",
	["ά"] = "Ά",
	["ὲ"] = "Ὲ",
	["έ"] = "Έ",
	["ὴ"] = "Ὴ",
	["ή"] = "Ή",
	["ὶ"] = "Ὶ",
	["ί"] = "Ί",
	["ὸ"] = "Ὸ",
	["ό"] = "Ό",
	["ὺ"] = "Ὺ",
	["ύ"] = "Ύ",
	["ὼ"] = "Ὼ",
	["ώ"] = "Ώ",
	["ᾀ"] = "ᾈ",
	["ᾁ"] = "ᾉ",
	["ᾂ"] = "ᾊ",
	["ᾃ"] = "ᾋ",
	["ᾄ"] = "ᾌ",
	["ᾅ"] = "ᾍ",
	["ᾆ"] = "ᾎ",
	["ᾇ"] = "ᾏ",
	["ᾐ"] = "ᾘ",
	["ᾑ"] = "ᾙ",
	["ᾒ"] = "ᾚ",
	["ᾓ"] = "ᾛ",
	["ᾔ"] = "ᾜ",
	["ᾕ"] = "ᾝ",
	["ᾖ"] = "ᾞ",
	["ᾗ"] = "ᾟ",
	["ᾠ"] = "ᾨ",
	["ᾡ"] = "ᾩ",
	["ᾢ"] = "ᾪ",
	["ᾣ"] = "ᾫ",
	["ᾤ"] = "ᾬ",
	["ᾥ"] = "ᾭ",
	["ᾦ"] = "ᾮ",
	["ᾧ"] = "ᾯ",
	["ᾰ"] = "Ᾰ",
	["ᾱ"] = "Ᾱ",
	["ᾳ"] = "ᾼ",
	["ι"] = "Ι",
	["ῃ"] = "ῌ",
	["ῐ"] = "Ῐ",
	["ῑ"] = "Ῑ",
	["ῠ"] = "Ῠ",
	["ῡ"] = "Ῡ",
	["ῥ"] = "Ῥ",
	["ῳ"] = "ῼ",
	["ⅎ"] = "Ⅎ",
	["ⅰ"] = "Ⅰ",
	["ⅱ"] = "Ⅱ",
	["ⅲ"] = "Ⅲ",
	["ⅳ"] = "Ⅳ",
	["ⅴ"] = "Ⅴ",
	["ⅵ"] = "Ⅵ",
	["ⅶ"] = "Ⅶ",
	["ⅷ"] = "Ⅷ",
	["ⅸ"] = "Ⅸ",
	["ⅹ"] = "Ⅹ",
	["ⅺ"] = "Ⅺ",
	["ⅻ"] = "Ⅻ",
	["ⅼ"] = "Ⅼ",
	["ⅽ"] = "Ⅽ",
	["ⅾ"] = "Ⅾ",
	["ⅿ"] = "Ⅿ",
	["ↄ"] = "Ↄ",
	["ⓐ"] = "Ⓐ",
	["ⓑ"] = "Ⓑ",
	["ⓒ"] = "Ⓒ",
	["ⓓ"] = "Ⓓ",
	["ⓔ"] = "Ⓔ",
	["ⓕ"] = "Ⓕ",
	["ⓖ"] = "Ⓖ",
	["ⓗ"] = "Ⓗ",
	["ⓘ"] = "Ⓘ",
	["ⓙ"] = "Ⓙ",
	["ⓚ"] = "Ⓚ",
	["ⓛ"] = "Ⓛ",
	["ⓜ"] = "Ⓜ",
	["ⓝ"] = "Ⓝ",
	["ⓞ"] = "Ⓞ",
	["ⓟ"] = "Ⓟ",
	["ⓠ"] = "Ⓠ",
	["ⓡ"] = "Ⓡ",
	["ⓢ"] = "Ⓢ",
	["ⓣ"] = "Ⓣ",
	["ⓤ"] = "Ⓤ",
	["ⓥ"] = "Ⓥ",
	["ⓦ"] = "Ⓦ",
	["ⓧ"] = "Ⓧ",
	["ⓨ"] = "Ⓨ",
	["ⓩ"] = "Ⓩ",
	["ⰰ"] = "Ⰰ",
	["ⰱ"] = "Ⰱ",
	["ⰲ"] = "Ⰲ",
	["ⰳ"] = "Ⰳ",
	["ⰴ"] = "Ⰴ",
	["ⰵ"] = "Ⰵ",
	["ⰶ"] = "Ⰶ",
	["ⰷ"] = "Ⰷ",
	["ⰸ"] = "Ⰸ",
	["ⰹ"] = "Ⰹ",
	["ⰺ"] = "Ⰺ",
	["ⰻ"] = "Ⰻ",
	["ⰼ"] = "Ⰼ",
	["ⰽ"] = "Ⰽ",
	["ⰾ"] = "Ⰾ",
	["ⰿ"] = "Ⰿ",
	["ⱀ"] = "Ⱀ",
	["ⱁ"] = "Ⱁ",
	["ⱂ"] = "Ⱂ",
	["ⱃ"] = "Ⱃ",
	["ⱄ"] = "Ⱄ",
	["ⱅ"] = "Ⱅ",
	["ⱆ"] = "Ⱆ",
	["ⱇ"] = "Ⱇ",
	["ⱈ"] = "Ⱈ",
	["ⱉ"] = "Ⱉ",
	["ⱊ"] = "Ⱊ",
	["ⱋ"] = "Ⱋ",
	["ⱌ"] = "Ⱌ",
	["ⱍ"] = "Ⱍ",
	["ⱎ"] = "Ⱎ",
	["ⱏ"] = "Ⱏ",
	["ⱐ"] = "Ⱐ",
	["ⱑ"] = "Ⱑ",
	["ⱒ"] = "Ⱒ",
	["ⱓ"] = "Ⱓ",
	["ⱔ"] = "Ⱔ",
	["ⱕ"] = "Ⱕ",
	["ⱖ"] = "Ⱖ",
	["ⱗ"] = "Ⱗ",
	["ⱘ"] = "Ⱘ",
	["ⱙ"] = "Ⱙ",
	["ⱚ"] = "Ⱚ",
	["ⱛ"] = "Ⱛ",
	["ⱜ"] = "Ⱜ",
	["ⱝ"] = "Ⱝ",
	["ⱞ"] = "Ⱞ",
	["ⱡ"] = "Ⱡ",
	["ⱥ"] = "Ⱥ",
	["ⱦ"] = "Ⱦ",
	["ⱨ"] = "Ⱨ",
	["ⱪ"] = "Ⱪ",
	["ⱬ"] = "Ⱬ",
	["ⱶ"] = "Ⱶ",
	["ⲁ"] = "Ⲁ",
	["ⲃ"] = "Ⲃ",
	["ⲅ"] = "Ⲅ",
	["ⲇ"] = "Ⲇ",
	["ⲉ"] = "Ⲉ",
	["ⲋ"] = "Ⲋ",
	["ⲍ"] = "Ⲍ",
	["ⲏ"] = "Ⲏ",
	["ⲑ"] = "Ⲑ",
	["ⲓ"] = "Ⲓ",
	["ⲕ"] = "Ⲕ",
	["ⲗ"] = "Ⲗ",
	["ⲙ"] = "Ⲙ",
	["ⲛ"] = "Ⲛ",
	["ⲝ"] = "Ⲝ",
	["ⲟ"] = "Ⲟ",
	["ⲡ"] = "Ⲡ",
	["ⲣ"] = "Ⲣ",
	["ⲥ"] = "Ⲥ",
	["ⲧ"] = "Ⲧ",
	["ⲩ"] = "Ⲩ",
	["ⲫ"] = "Ⲫ",
	["ⲭ"] = "Ⲭ",
	["ⲯ"] = "Ⲯ",
	["ⲱ"] = "Ⲱ",
	["ⲳ"] = "Ⲳ",
	["ⲵ"] = "Ⲵ",
	["ⲷ"] = "Ⲷ",
	["ⲹ"] = "Ⲹ",
	["ⲻ"] = "Ⲻ",
	["ⲽ"] = "Ⲽ",
	["ⲿ"] = "Ⲿ",
	["ⳁ"] = "Ⳁ",
	["ⳃ"] = "Ⳃ",
	["ⳅ"] = "Ⳅ",
	["ⳇ"] = "Ⳇ",
	["ⳉ"] = "Ⳉ",
	["ⳋ"] = "Ⳋ",
	["ⳍ"] = "Ⳍ",
	["ⳏ"] = "Ⳏ",
	["ⳑ"] = "Ⳑ",
	["ⳓ"] = "Ⳓ",
	["ⳕ"] = "Ⳕ",
	["ⳗ"] = "Ⳗ",
	["ⳙ"] = "Ⳙ",
	["ⳛ"] = "Ⳛ",
	["ⳝ"] = "Ⳝ",
	["ⳟ"] = "Ⳟ",
	["ⳡ"] = "Ⳡ",
	["ⳣ"] = "Ⳣ",
	["ⴀ"] = "Ⴀ",
	["ⴁ"] = "Ⴁ",
	["ⴂ"] = "Ⴂ",
	["ⴃ"] = "Ⴃ",
	["ⴄ"] = "Ⴄ",
	["ⴅ"] = "Ⴅ",
	["ⴆ"] = "Ⴆ",
	["ⴇ"] = "Ⴇ",
	["ⴈ"] = "Ⴈ",
	["ⴉ"] = "Ⴉ",
	["ⴊ"] = "Ⴊ",
	["ⴋ"] = "Ⴋ",
	["ⴌ"] = "Ⴌ",
	["ⴍ"] = "Ⴍ",
	["ⴎ"] = "Ⴎ",
	["ⴏ"] = "Ⴏ",
	["ⴐ"] = "Ⴐ",
	["ⴑ"] = "Ⴑ",
	["ⴒ"] = "Ⴒ",
	["ⴓ"] = "Ⴓ",
	["ⴔ"] = "Ⴔ",
	["ⴕ"] = "Ⴕ",
	["ⴖ"] = "Ⴖ",
	["ⴗ"] = "Ⴗ",
	["ⴘ"] = "Ⴘ",
	["ⴙ"] = "Ⴙ",
	["ⴚ"] = "Ⴚ",
	["ⴛ"] = "Ⴛ",
	["ⴜ"] = "Ⴜ",
	["ⴝ"] = "Ⴝ",
	["ⴞ"] = "Ⴞ",
	["ⴟ"] = "Ⴟ",
	["ⴠ"] = "Ⴠ",
	["ⴡ"] = "Ⴡ",
	["ⴢ"] = "Ⴢ",
	["ⴣ"] = "Ⴣ",
	["ⴤ"] = "Ⴤ",
	["ⴥ"] = "Ⴥ",
	["ａ"] = "Ａ",
	["ｂ"] = "Ｂ",
	["ｃ"] = "Ｃ",
	["ｄ"] = "Ｄ",
	["ｅ"] = "Ｅ",
	["ｆ"] = "Ｆ",
	["ｇ"] = "Ｇ",
	["ｈ"] = "Ｈ",
	["ｉ"] = "Ｉ",
	["ｊ"] = "Ｊ",
	["ｋ"] = "Ｋ",
	["ｌ"] = "Ｌ",
	["ｍ"] = "Ｍ",
	["ｎ"] = "Ｎ",
	["ｏ"] = "Ｏ",
	["ｐ"] = "Ｐ",
	["ｑ"] = "Ｑ",
	["ｒ"] = "Ｒ",
	["ｓ"] = "Ｓ",
	["ｔ"] = "Ｔ",
	["ｕ"] = "Ｕ",
	["ｖ"] = "Ｖ",
	["ｗ"] = "Ｗ",
	["ｘ"] = "Ｘ",
	["ｙ"] = "Ｙ",
	["ｚ"] = "Ｚ",
	["𐐨"] = "𐐀",
	["𐐩"] = "𐐁",
	["𐐪"] = "𐐂",
	["𐐫"] = "𐐃",
	["𐐬"] = "𐐄",
	["𐐭"] = "𐐅",
	["𐐮"] = "𐐆",
	["𐐯"] = "𐐇",
	["𐐰"] = "𐐈",
	["𐐱"] = "𐐉",
	["𐐲"] = "𐐊",
	["𐐳"] = "𐐋",
	["𐐴"] = "𐐌",
	["𐐵"] = "𐐍",
	["𐐶"] = "𐐎",
	["𐐷"] = "𐐏",
	["𐐸"] = "𐐐",
	["𐐹"] = "𐐑",
	["𐐺"] = "𐐒",
	["𐐻"] = "𐐓",
	["𐐼"] = "𐐔",
	["𐐽"] = "𐐕",
	["𐐾"] = "𐐖",
	["𐐿"] = "𐐗",
	["𐑀"] = "𐐘",
	["𐑁"] = "𐐙",
	["𐑂"] = "𐐚",
	["𐑃"] = "𐐛",
	["𐑄"] = "𐐜",
	["𐑅"] = "𐐝",
	["𐑆"] = "𐐞",
	["𐑇"] = "𐐟",
	["𐑈"] = "𐐠",
	["𐑉"] = "𐐡",
	["𐑊"] = "𐐢",
	["𐑋"] = "𐐣",
	["𐑌"] = "𐐤",
	["𐑍"] = "𐐥",
	["𐑎"] = "𐐦",
	["𐑏"] = "𐐧"
}

local upper2lower = table.flipped( lower2upper )

do
	local metatable = { __index = function( _, key ) return key end }
	std.setmetatable( lower2upper, metatable )
	std.setmetatable( upper2lower, metatable )
end

local hex2char
do

	local tonumber = std.tonumber

	--- TODO
	---@param str string
	---@return string
	function hex2char( str )
		return byte2char( tonumber( str, 16 ) )
	end

end

local escapeChars = { ["\\n"] = "\n", ["\\t"] = "\t", ["\\0"] = "\0" }

--- TODO
---@param str string
---@return string
local function escapeToChar( str )
	return escapeChars[ str ] or string_sub( str, 2, 2 )
end

--- TODO
---@param position number
---@param utf8Length number
---@return number
local function stringOffset( position, utf8Length )
	if position < 0 then
		return math_max( utf8Length + position + 1, 0 )
	else
		return position
	end
end

--- TODO
---@param str string
---@param index number
---@param utf8Length number
---@return string
local function get( str, index, utf8Length )
	if utf8Length == nil then utf8Length = len( str ) end
	index = stringOffset( index or 1, utf8Length )
	if index == 0 then return "" end
	if index > utf8Length then return "" end
	return codepoint( str, offset_fn( str, index - 1 ) )
end

--- [SHARED AND MENU]
---
--- utf8 string library
---@class gpm.string.utf8
---@field charpattern string This is NOT a function, it's a pattern (a string, not a function) which matches exactly one UTF-8 byte sequence, assuming that the subject is a valid UTF-8 string.
local utf8 = {
	charpattern = charpattern,
	codepoint = codepoint,
	byte2char = byte2char,
	hex2char = hex2char,
	offset = offset_fn,
	char = char_fn,
	len = len,
	get = get
}

string.utf8 = utf8

--- TODO
---@param str string
---@param index number?
---@param char string
---@return string
function utf8.set( str, index, char )
	local utf8Length = len( str )
	index = stringOffset( index or 1, utf8Length )
	if index == 0 then return "" end

	if index > utf8Length then
		for _ = 1, index - utf8Length, 1 do
			str = str .. " "
		end
	end

	return string_sub( str, 1, offset_fn( str, index - 1 ) ) .. char .. string_sub( str, offset_fn( str, index ) or 1, utf8Length )
end

--- TODO
---@param str string
---@return function
function utf8.codes( str )
	local index, stringLength = 1, string_len( str )
	return function()
		if index > stringLength then return nil end

		local stringStart, stringEnd, codePoint = decode( str, index, stringLength )
		if stringStart == nil then
			std.error( "invalid UTF-8 code", 2 )
		end

		index = stringEnd + 1
		return stringStart, codePoint
	end
end

--- TODO
---@param str string
---@return string
function utf8.force( str )
	local stringLength = string_len( str )
	if stringLength == 0 then
		return str
	end

	local buffer, length, pointer = { }, 0, 1

	repeat
		local seqStartPos, seqEndPos = decode( str, pointer, stringLength )
		if seqStartPos then
			length = length + 1
			buffer[ length ] = string_sub( str, seqStartPos, seqEndPos )
			pointer = seqEndPos + 1
		else
			length = length + 1
			buffer[ length ] = char_fn( 0xFFFD )
			pointer = pointer + 1
		end
	until pointer > stringLength

	return table_concat( buffer, "", 1, length )
end

--- TODO
---@param str string
---@param charStart number?
---@param charEnd number?
---@return string
local function sub( str, charStart, charEnd )
	local utf8Length = len( str )
	local buffer, length = {}, 0

	for index = stringOffset( charStart or 1, utf8Length ), stringOffset( charEnd or -1, utf8Length ) do
		length = length + 1
		buffer[ length ] = get( str, index, utf8Length )
	end

	return table_concat( buffer, "", 1, length )
end

utf8.sub = sub
utf8.slice = sub

--- TODO
---@param str string
---@return string
function utf8.lower( str )
	local utf8Length = len( str )
	local buffer, length = {}, 0

	for index = 1, utf8Length, 1 do
		length = length + 1
		buffer[ length ] = upper2lower[ get( str, index, utf8Length ) ]
	end

	return table_concat( buffer, "", 1, length )
end

--- TODO
---@param str string
---@return string
function utf8.upper( str )
	local utf8Length = len( str )
	local buffer, length = {}, 0

	for index = 1, utf8Length, 1 do
		length = length + 1
		buffer[ length ] = lower2upper[ get( str, index, utf8Length ) ]
	end

	return table_concat( buffer, "", 1, length )
end

--- TODO
---@param str string
---@param isSequence boolean?
---@return string
function utf8.escape( str, isSequence )
	---@diagnostic disable-next-line: redundant-return-value
	return string_gsub( string_gsub( str, isSequence and "\\[uU]([0-9a-fA-F]+)" or "[uU]%+([0-9a-fA-F]+)", hex2char ), "\\.", escapeToChar ), nil
end

--- TODO
---@param str string
---@return string
function utf8.reverse( str )
	local utf8Length = len( str )
	local buffer, length, position = {}, 0, utf8Length

	while position > 0 do
		length = length + 1
		buffer[ length ] = get( str, position, utf8Length )
		position = position - 1
	end

	return table_concat( buffer, "", 1, length )
end

-- TODO: Add more functions

