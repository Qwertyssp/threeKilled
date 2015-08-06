local socket = require("socket")
local room = require("room")
local game = {}

local usr_pool = {}
local room_list = {}
local CMD = {}

local function getrid()
        local rid = #room_list + 1
        --TODO:need to reuse the hold index
        --
        return rid
end

function CMD.room_create(fd, cmd)
        local res = {}
        local rid;
        local r;

        rid = getrid()
        assert(room_list[rid] == nil)
        room_list[rid] = room:create(fd, cmd.uid)

        res.cmd = "room_create"
        if room_list[rid] then
                res.rid = rid
        else
                res.rid = -1
        end

        if res.rid == rid then
                r = room_list[rid];
                usr_pool[fd].room = r;
        end

        socket.write(fd, res)
end

function CMD.room_list(fd, cmd)
        local rl = {}
        assert(cmd.page_index == tostring(1))
        rl.cmd = "room_list"
        rl.room = {}
        for k, v in pairs(room_list) do
                print("name", v:getname())
                rl.room[#rl.room + 1] = {name=v:getname(), rid = k}
        end

        socket.write(fd, rl)
end

function CMD.room_enter(fd, cmd)
        local re = {}
        local room;
        
        re.cmd = "room_enter";
        room = room_list[tonumber(cmd.rid)];
        if room then
                usr_pool[fd].room = room;
                re.count = room:enter(fd, cmd)
        else
                re.count = -1;
        end

        socket.write(fd, re)

        if (re.count == 2) then
                room:start()
        end
end

function CMD.room_leave(fd, cmd)
        local room;
        assert(usr_pool[fd].room):leave(fd);
        usr_pool[fd].room = nil
end

function game.enter(fd)
        usr_pool[fd] = {}
        usr_pool[fd].fd = fd
        usr_pool[fd].room = nil 
        usr_pool[fd].kick = nil
end

function game.kick(fd)
        if (usr_pool[fd].kick) then
                usr_pool[fd].kick(fd)
        end
        usr_pool[fd] = {}
end

function game.handler(fd, cmd)
        if CMD[cmd.cmd] then
                CMD[cmd.cmd](fd, cmd)
        else
                assert(usr_pool[fd].room):handler(fd, cmd)
        end
end

return game

