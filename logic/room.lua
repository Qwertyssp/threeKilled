local socket = require("socket")

local room = {

}

local function multicast(room, msg)
        for _, v in pairs(room.mem) do
                socket.write(v.fd, msg);
        end
end


--TODO: t.mem will can occurs hole when the user exit the room
function room:create(fd, uid)
        local t = {
                owner = uid,
                count = 1,
                mem = {
                        {fd = fd, uid = uid},
                },
                
                name = tostring(uid) .. "room",
        }
        
        self.__index = self
        setmetatable(t, self)

        return t
end

function room:getname()
        return self.name
end

function room:getcount()
        return self.count
end

function room:enter(fd, msg)
        self.mem[#self.mem + 1] = {
                fd = fd,
                uid = msg.uid,
        }

        self.count = self.count + 1

        return self.count
end

function room:start()
        local gs = {};
        local card = {{name="kill"}, {name="kill"}, {name="run"}, {name="peach"}}
        
        assert(self.count == 2)
        gs.cmd = "game_start";
        gs.card = card
        for _, v in pairs(self.mem) do
                v.card = card
                gs.uid = v.uid;
                socket.write(v.fd, gs)
        end
end

function room:leave(fd)
        if self.mem[fd] then
                self.count = self.count - 1
                self.mem[fd] = nil
        end

        return self.count
end


return room


