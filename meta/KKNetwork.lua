---@meta

---@class KKNetwork
---@overload fun(): self
KKNetwork = {}

--Example Initialize the network environment
--@param ip Remote IP address. The value is a string
--@param port Indicates the port type
--@param buffer_size Size of the network buffer
--@return Returns whether the initialization succeeds. If the initialization fails, an error message will be displayed
--The @detail function will check whether the ip port is valid, but will not actually start the network loop, but will request the corresponding resources in advance
function KKNetwork:init(ip, port, buffer_size)
end

--Start a network connection
--@return true or false
--@detail initiates the network connection, and this function call will actually connect to the server
--The is_connecting method returns true if the connection is successful
function KKNetwork:start()
end

--Returns the active status of the network connection
---@return boolean
function KKNetwork:is_connecting()
end

--Disconnect the network connection and stop receiving network message events
--@detail disconnects the current connection and releases the corresponding resource. As long as destory is not called, the start method can be called again to start the network connection
function KKNetwork:stop()
end

--Main loop, which needs to be called in the user main loop
function KKNetwork:run_once()
end

--Release network resources. If the network connection is not already disconnected, the network connection will be disconnected
function KKNetwork:destroy()
end

--Send network message
--@param message_body The message body is a string. It can be a string or a binary array after pb serialization
--@param length message_body length
--@return The length of the actual message sent. A value of <= 0 is returned on failure
function KKNetwork:send(message_body, length)
end

--Receive network message
--@param length Indicates the length of the message that is expected to be received. If it is insufficient, the length of the message that is actually received is returned
--@return message Message body, string, returns nil on failure to accept
--@return result Indicates the length of the received message
--The @detail accept message function removes the message from the buffer and is the actual accept message
function KKNetwork:recv(length)
end

--Detection of network messages, not removed from the message queue, mostly used to determine whether the message header is sufficient
--@return message Message body, string, returns nil on failure to accept
--@return result Indicates the length of the received message
--The @detail accept message function does not remove the message from the buffer
function KKNetwork:peek(length)
end

function KKNetwork:reset()
end
