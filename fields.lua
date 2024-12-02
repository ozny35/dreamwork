--- Table used by `http.request` function.
---@class HTTPRequest
local HTTPRequest = {}

--- Request method, case insensitive. Possible values are:
--- * GET
--- * POST
--- * HEAD
--- * PUT
--- * DELETE
--- * PATCH
--- * OPTIONS
---@type string
HTTPRequest.method = nil

--- The target url
---@type string
HTTPRequest.url = nil

--- KeyValue table for parameters. This is only applicable to the following request methods:
--- * GET
--- * POST
--- * HEAD
---@type table
HTTPRequest.parameters = nil

--- KeyValue table for headers
---@type table
HTTPRequest.headers = nil

--- Body string for POST data. If set, will override parameters
---@type string
HTTPRequest.body = nil

--- Content type for body.
---@type string
HTTPRequest.type = "text/plain; charset=utf-8"

--- The timeout for the connection.
---@type number
HTTPRequest.timeout = 60

--- Whether to cache the response.
---@type boolean
HTTPRequest.cache = false

--- The cache lifetime for the request.
---@type number
HTTPRequest.lifetime = nil

--- Whether to use ETag caching.
---@type boolean
HTTPRequest.etag = false

--- The success callback.
---@class HTTPResponse
local HTTPResponse = {}

--- The response status code.
---@type number
HTTPResponse.status = nil

--- The response body.
---@type string
HTTPResponse.body = nil

--- The response headers.
---@type table
HTTPResponse.headers = nil
