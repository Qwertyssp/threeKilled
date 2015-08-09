local socket = require("socket")
local timer = require("timer")
local core = require("core")
local game = require("game")
local usrmgr = require("usrmgr")
local packet = require("packet")

local conn_process = {}
local CMD = {}

function CMD.auth(fd, cmd)
        local res = {}
        local valid

        valid = usrmgr.reg(cmd.name, fd)
        
        res.cmd="auth"
        if (valid == true) then
                res.uid = fd;
                game.enter(fd)
                conn_process[fd].handler = game.handler
                conn_process[fd].kick = game.kick
        else
                res.uid = -1;
        end

        print("auth result:", res.uid)

        socket.write(fd, res)
end

function CMD.kick(fd)
        usrmgr.kick(fd)
end

function CMD.message(fd, cmd)
        if conn_process[fd].handler then
                conn_process[fd].handler(fd, cmd)
        else
                --kick it
        end
end




local EVENT = {}

function EVENT.accept(fd)
        conn_process[fd] = {}
        socket.packet(fd, packet.pack, packet.unpack)
        print("new client:", fd)
end

function EVENT.close(fd)
        print("---close:", fd)
        usrmgr.kick(fd)
end

function EVENT.data(fd, cmd)
        local handler = CMD[cmd.cmd]
        if handler then
                handler(fd, cmd)
        else
                CMD.message(fd, cmd)
        end
end


socket.service(EVENT)

print("-------Hello Boy----------")

