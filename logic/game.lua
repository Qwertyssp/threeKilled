local socket = require("socket")
local room = require("room")

local game = {
        handler = {},
}

local usr_pool = {}
local room_list = {}
local CMD = {}

setmetatable(room_list, {__mode = "v"})

local function getrid()
        local rid = #room_list + 1
        --TODO:need to reuse the hold index
        --
        return rid
end

function game.handler.enter(fd, uid)
        assert(usr_pool[fd] == nil)
        usr_pool[fd] = {
                fd = fd,
                uid = uid,
                room = nil
        }
end

function game.handler.leave(fd)
        local r = usr_pool[fd].room
        if r then
                r:leave(fd, cmd)
        end
        usr_pool[fd] = nil
end

function game.handler.room_create(fd, cmd)
        local res = {}
        local rid;
        rid = getrid()

        assert(room_list[rid] == nil)
        room_list[rid] = room:create(fd, cmd.uid)

        res.cmd = "room_create"
        if room_list[rid] then
                res.rid = rid
                usr_pool[fd].room = room_list[rid]
        else
                res.rid = -1
        end

        socket.write(fd, res)
end

function game.handler.room_list(fd, cmd)
        local rl = {}
        rl.cmd = "room_list"
        rl.room = {}

        for k, v in pairs(room_list) do
                print("name", v:getname())
                rl.room[#rl.room + 1] = {name = v:getname(), count = v:getcount(), rid = k}
        end

        socket.write(fd, rl)
end

function game.handler.room_enter(fd, cmd)
        local re = {}
        local r

        re.cmd = "room_enter"
        
        r = room_list[tonumber(cmd.rid)]
        if r then
                assert(usr_pool[fd].room == nil)
                usr_pool[fd].room = r
                re.count = r:enter(fd, cmd)
        else
                re.count = -1
        end

        socket.write(fd, re)

        if re.count == 2 then
                r:start()
        end
end

function game.handler.room_leave(fd, cmd)
        local r
        assert(usr_pool[fd].room):leave(fd, cmd)
        usr_pool[fd].room = nil
end

function game.handler.other(fd, cmd)
        local r = usr_pool[fd].room
        if r then
                r:process(fd, cmd)
        end
end

return game

