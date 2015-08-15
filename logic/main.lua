local socket = require("socket")
local timer = require("timer")
local core = require("core")
local spacker = require("spacker")
local game = require("game")
local usrmgr = require("usrmgr")
local packet = require("packet")

local conn_pool = {}

local CMD = {}

function CMD.auth(fd, cmd)
        local res = {}
        local valid

        valid = usrmgr.reg(cmd.name, fd)
        
        res.cmd="auth"
        if (valid == true) then
                res.uid = fd;
                conn_pool[fd].handler = game.handler
                assert(conn_pool[fd].handler["enter"])(fd, res.uid)
        else
                res.uid = -1;
        end

        print("auth result:", res.uid)

        socket.write(fd, res)
end

local EVENT = {}

function EVENT.accept(fd)
        conn_pool[fd] = {
                handler = CMD,
        }
        socket.packet(fd, packet.pack, packet.unpack)
        print("new client:", fd)
end

function EVENT.close(fd)
        print("---close:", fd)
        assert(conn_pool[fd].handler["leave"])(fd)
        usrmgr.kick(fd)
        conn_pool[fd] = nil
end

function EVENT.data(fd, cmd)
        local func = conn_pool[fd].handler[cmd.cmd]
        if func == nil then
                func = conn_pool[fd].handler["other"]
        end

        if func then
                func(fd, cmd)
        end
end


socket.service(EVENT, spacker:create("binpacket"))

print("-------Hello Boy----------")

