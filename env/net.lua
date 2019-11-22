--[[
	
	Net API
	Provides network access
	
]]--

local http = require "socket.http"

local net = {}
local args = {...}
local computer = args[1]
local love = args[2]



-- FUNCTIONS

function net.request(url)
	expect( url, "string" )
	
	local body, code, headers, status = http.request(url)
	
	return {
		body = body,
		code = code,
		status = status
	}
end

function net.udpInit()
	net.udp = socket.udp()
	net.udp:setsockname( "*", 64242 )
	net.udp:settimeout(0)
end

function net.udpSend( data, ip, port )
	expect( data, "string", 1, "net.udpSend" )
	expect( ip, "string", 2, "net.udpSend" )
	expect( port, "number", 3, "net.udpSend" )
	
	if not net.udp then net.udpInit() end
	net.udp:setpeername( ip, port )
	local success, err = net.udp:send(data)
	return success == 1, err
end

function net.udpReceive()
	if not net.udp then net.udpInit() end
	
	return net.udp:receivefrom()
end



-- RETURN

return net