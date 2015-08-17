local socket = require("socket")
local random = math.random

math.randomseed(os.time())

local room = {

}

local function multicast(room, msg)
        for _, v in pairs(room.mem) do
                socket.write(v.fd, msg);
        end
end

local MEM_STATE_ENTER           = 1
local MEM_STATE_SELCHAR         = 2

--TODO: t.mem will can occurs hole when the user exit the room
function room:create(fd, uid)
        local t = {
                owner = uid,
                count = 1,
                mem = {
                        {
                                fd = fd,
                                uid = uid,
                                state = MEM_STATE_ENTER,
                        },
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
        local mem = {
                fd = fd,
                uid = msg.uid,
                state = MEM_STATE_ENTER,
                character = nil,
        }

        if self.mem[1] == nil then
                self.mem[1] = mem
        else
                self.mem[#self.mem + 1] = mem
        end

        self.count = self.count + 1

        return self.count
end

function room:start()
        self.character_list = {{name = "liubei"}, {name = "guanyu"}, {name = "zhangfei"}}
        assert(self.count == 2)
        local gs = {
                cmd = "character_list",
                character_list = self.character_list,
        }

        local index = random(self.count)
        local mem = self.mem[index];

        socket.write(mem.fd, gs)
end

function room:character_sel(fd, msg)
        local char = msg.name
        local usr_list = {}
        local removeindex = -1
        for k, v in ipairs(self.character_list) do
                print(char, v.name)
                if char == v.name then
                        removeindex = k
                        break
                end
        end

        if (removeindex ~= -1) then
                table.remove(self.character_list, removeindex)
        end

        for _, v in ipairs(self.mem) do
                if v.fd == fd then
                        v.state = MEM_STATE_SELCHAR
                        v.character = char
                elseif v.state == MEM_STATE_ENTER then
                        table.insert(usr_list, v)
                end
        end

        if #usr_list > 0 then
                local mem = usr_list[random(#usr_list)]
                local gs = {
                        cmd = "character_list",
                        character_list = self.character_list,
                }

                socket.write(mem.fd, gs)
        else
                print("room:game start")
        end
end

function room:leave(fd)
        for k, v in pairs(self.mem) do
                if v.fd == fd then
                        self.mem[k] = nil
                        self.count = self.count - 1
                        break
                end
        end

        return self.count
end


return room


