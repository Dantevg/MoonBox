local net = {}

--[[
local http = require "socket.http"
local ltn12 = require "ltn12"

function net.request(url)
	local response = {}
	local body, code, headers, status = http.request{
		url = url,
		sink = ltn12.sink.table(response)
	}
	
	return {
		body = table.concat(response),
		code = code
	}
end
]]--

return net