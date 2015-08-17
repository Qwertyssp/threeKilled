local io = require("io")
local socket = require("socket")

local fd = socket.connect("127.0.0.1", 8989);

print("connect fd:", fd)

local CMD = {}

local function pause()
        for line in io.stdin:lines() do
                break;
        end
end

function CMD.login()
        local a = 0
        local cmd = "{\"cmd\":\"auth\", \"name\":\"findstr\"}\r\n\r"
        socket.send(fd, cmd)
        local res = socket.recv(fd)
        print (res)
end

function CMD.roomlist()
        local cmd = "{\"cmd\":\"room_list\", \"page_index\":\"1\"}\r\n\r"
        socket.send(fd, cmd)
        local res = socket.recv(fd)
        print("roomlist", res)
end

function CMD.roomcreate()
        local cmd = "{\"cmd\":\"room_create\", \"uid\":\"1\"}\r\n\r"
        socket.send(fd, cmd)
        local res = socket.recv(fd)
        print(res)
        local res = socket.recv(fd)
        print(res)
end

function CMD.roomenter()
        local cmd = "{\"cmd\":\"room_enter\", \"uid\":\"2\", \"rid\":1}\r\n\r"
        socket.send(fd, cmd)
        local res = socket.recv(fd)
        print(res)
        res = socket.recv(fd)
        print(res);
end

function CMD.sela()
        print("sel1")
        local cmd = "{\"cmd\":\"character_sel\", \"name\":\"liubei\"}\r\n\r"
        socket.send(fd, cmd)
end

function CMD.selb()
        local cmd = "{\"cmd\":\"character_sel\", \"name\":\"guanyu\"}\r\n\r"
        socket.send(fd, cmd)
end


for line in io.stdin:lines() do
        local handler = CMD[line]
        if (handler) then
                handler()
        else
                print("input err")
        end
end

socket.close(fd);

