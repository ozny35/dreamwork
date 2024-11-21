--- Table used by [Global.HTTP](https://wiki.facepunch.com/gmod/Global.HTTP) function.
---@class HTTPRequest
local HTTPRequest = {}

---Request method, case insensitive. Possible values are:
--- * GET
--- * POST
--- * HEAD
--- * PUT
--- * DELETE
--- * PATCH
--- * OPTIONS
---@type string
HTTPRequest.method = nil

---The target url
---@type string
HTTPRequest.url = nil

---KeyValue table for parameters. This is only applicable to the following request methods:
--- * GET
--- * POST
--- * HEAD
---@type table
HTTPRequest.parameters = nil

---KeyValue table for headers
---@type table
HTTPRequest.headers = nil

---Body string for POST data. If set, will override parameters
---@type string
HTTPRequest.body = nil

---Content type for body.
---@type string
HTTPRequest.type = "text/plain; charset=utf-8"

---The timeout for the connection.
---@type number
HTTPRequest.timeout = 60

---The cache lifetime for the request.
---@type number
HTTPRequest.lifetime = 0
