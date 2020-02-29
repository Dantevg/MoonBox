# Net
Provides internet access, basically a wrapper around Luasocket.

## Functions
### net.request ( url )
Performs a luasocket `http.request`.
Returns a table containing the fields `body`, `code` and `status`.

### net.udpInit ( )
Initializes the UDP socket. You don't have to call this function,
as it is called automatically when needed.

### net.udpSend ( data, ip, port )
Sends `data` to `ip` at `port`, over UDP.
When the transmission was successful, returns `true`.  
When the transmission failed, returns `false`,
followed by an error message.

### net.udpReceive ( )
When data was sent previously, returns that data,
followed by the senders ip and port.  
This function doesn't block, so if no data was available,
it returns `nil`, followed by `"timeout"`.