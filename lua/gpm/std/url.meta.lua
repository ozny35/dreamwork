---@meta

---@class gpm.std
std = {}

---@alias URLState gpm.std.URLState
---@class gpm.std.URLState
---@field scheme string?
---@field username string?
---@field password string?
---@field hostname string | table | number | nil
---@field port number?
---@field path string | table | nil
---@field query string | URLSearchParams
local URLState = {}

---@alias URLSearchParams gpm.std.URLSearchParams
---@class gpm.std.URLSearchParams : gpm.std.Object
---@field __class gpm.std.URLSearchParamsClass
local URLSearchParams = {}

--- Appends name and value to the end
---@param name string
---@param value string?
function URLSearchParams:append(name, value) end

--- searches all parameters with given name, and deletes them
--- if `value` is given, then searches for exactly given name AND value
---@param name string
---@param value string?
function URLSearchParams:delete(name, value) end

--- Finds first value associated with given name
---@param name string
---@return string | nil
function URLSearchParams:get(name) end

--- Finds all values associated with given name and returns them as list
---@param name string
---@return table
function URLSearchParams:getAll(name) end

--- Returns true if parameters with given name exists
--- and value if given
---@param name string
---@param value string?
---@return boolean
function URLSearchParams:has(name, value) end

--- Sets first name to a given value (or appends [name, value])
--- and deletes other parameters with the same name
---@param name string
---@param value string?
function URLSearchParams:set(name, value) end

--- Sorts parameters inside URLSearchParams
function URLSearchParams:sort() end

--- returns iterator that can be used in for loops
--- e.g. `for name, value in searchParams:entries() do ... end`
---@return fun(): string, string
function URLSearchParams:iterator() end

--- returns iterator that can be used in for loops
---@return fun(): string
function URLSearchParams:keys() end

--- returns iterator that can be used in for loops
---@return fun(): string
function URLSearchParams:values() end

---@class URLSearchParamsClass : gpm.std.URLSearchParams
---@field __base URLSearchParams
---@operator len:integer

--- Parses given `init` and returns a new URLSearchParams object
--- if `init` is table, then it must be a list that consists of tables
--- that have two value, name and value
--- e.g. `{ {"name", "value"}, {"foo", "bar"}, {"good"} }`
---
--- also calling tostring(...) with URLSearchParams given will result in getting serialized query
--- also `#` can be used to get a total count of parameters (e.g. #searchParams)
---@return URLSearchParams
function std.URLSearchParams(init, url) end

---@alias URL gpm.std.URL
---@class gpm.std.URL : gpm.std.Object, gpm.std.URLState
---@field __class gpm.std.URLClass
---@field state URLState internal state of URL
---@field href string full url
---@field origin string? *readonly* scheme + hostname + port
---@field protocol string? just a scheme with ':' appended at the end
---@field username string?
---@field password string?
---@field host string hostname + port
---@field hostname string?
---@field port number?
---@field pathname string?
---@field query string?
---@field search string? a query with '?' prepended
---@field searchParams URLSearchParams
---@field fragment string?
---@field hash string? fragment with # prepended
local URL = {}

---@class gpm.std.URLClass : gpm.std.URL
---@field __base URL
local URLClass = {}

--- Parses given URL string but returns URLState object instead
---@see std.URL
---@param url string
---@param base string | URL | nil
---@return URLState
function URLClass.parse(url, base) end

--- Returns true if given url can be parsed with URLState
--- otherwise returns false and error string
---@param url string
---@param base string | URL | nil
---@return boolean
---@return URLState | string
function URLClass.canParse(url, base) end

--- see https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/encodeURI
---@param uri string
---@return string
function URLClass.encodeURI(uri) end

--- see https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/encodeURIComponent
---@param uri string
---@return string
function URLClass.encodeURIComponent(uri) end

--- see https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/decodeURI
---@param uri string
---@return string
function URLClass.decodeURI(uri) end

--- see https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/decodeURIComponent
---@param uri string
---@return string
function URLClass.decodeURIComponent(uri) end

--- Serializes given URLState object to full url string
--- basically same as accessing ``.href`` of URL object
---@param state URLState
---@param excludeFragment boolean if true, fragment will be excluded (default: false)
---@return string
function URLClass.serialize(state, excludeFragment) end

--- Parses given URL string and returns a new URL object
--- using URL object with tostring(...) will result in getting `.href`
--- ```lua
--- local baseUrl = "https://developer.mozilla.org"
---
--- local A = URL("/", baseURL)
--- -- => 'https://developer.mozilla.org/'
---
--- local B = URL(baseURL)
--- -- => 'https://developer.mozilla.org/'
---
--- URL("en-US/docs", B)
--- -- => 'https://developer.mozilla.org/en-US/docs'
---
--- local D = URL("/en-US/docs", B)
--- -- => 'https://developer.mozilla.org/en-US/docs'
---
--- URL("/en-US/docs", D)
--- -- => 'https://developer.mozilla.org/en-US/docs'
---
--- URL("/en-US/docs", A)
--- -- => 'https://developer.mozilla.org/en-US/docs'
---
--- URL("/en-US/docs", "https://developer.mozilla.org/fr-FR/toto")
--- -- => 'https://developer.mozilla.org/en-US/docs'
--- ```
---@param url string an url string to parse
---@param base string | URL | nil optional base url
---@return URL
function std.URL(url, base) end
