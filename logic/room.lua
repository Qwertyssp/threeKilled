local socket = require("socket")

local room = {

}

--TODO: t.mem will can occurs hole when the user exit the room
function room:create(fd, uid)
        local t = {}
        local mem = {}
        self.__index = self
        setmetatable(t, self)
        t.owner = uid
        t.mem = {}
        t.mem[#t.mem + 1] = mem
        mem.uid = uid
        mem.fd = fd
        t.name = tostring(uid) .. " room"
        return t
end

function room:getname()
        return self.name
end

function room:handler(fd, msg)
        printf("room:handler", fd, msg)
end

function room:enter(fd, msg)
        local t = {}
        self.mem[#self.mem + 1] = t;
        t.fd = fd
        t.uid = msg.uid

        return #self.mem
end

function room:start()
        local gs = {};
        gs.cmd = "game_start";
        print("gamestart")
        for _, v in pairs(self.mem) do
                print("room:start", v.fd)
                socket.write(v.fd, gs);
        end
end

function room:leave(fd)
        return 0;
end


return room


