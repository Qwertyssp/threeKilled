local socket = require("socket")
local random = math.random

math.randomseed(os.time())

local room = {

}

local function multicast(room, msg, skip)
        for _, v in pairs(room.mem) do
                if v.fd ~= skip then
                        socket.write(v.fd, msg);
                end
        end
end

local MEM_STATE_ENTER           = 1
local MEM_STATE_SELCHAR         = 2
local MEM_STATE_PLAY            = 3

local state_enter_handler = {}
local state_selchar_handler = {}
local state_play_handler = {}

--TODO: t.mem will can occurs hole when the user exit the room
function room:create(fd, uid)
        local t = {
                owner = uid,
                mem = {
                        [fd] = {
                                fd = fd,
                                uid = uid,
                                state = MEM_STATE_ENTER,
                                card = {},
                        },
                },
                
                name = tostring(uid) .. "room",
                count = 1
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
                card_list = {},
                hp = 4,
        }

        self.mem[fd] = mem;
        local res = {
                cmd = "player_enter",
                uid = tostring(msg.uid),
        }

        self.count = self.count + 1

        multicast(self, res, fd)

        return self.count
end

function room:leave(fd)
        assert(self.count >= 1)
        self.mem[fd] = nil
        self.count = self.count - 1

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

local function begin_play(room)
        local uindex = random(room.count)
        local card_add = {
                {name = "run"},
                {name = "peach"},
        }

        for _, v in pairs(card_add) do
                table.insert(room.mem[uindex].card_list, v)
        end

        local card_list = {
                cmd = "card_list",
                card_list = room.mem[uindex].card_list,
        }

        socket.write(room.mem[uindex].fd, card_list)

        for _, v in pairs(room.mem) do
                v.state = MEM_STATE_PLAY
        end

end

-- the character process

local function character_sel_next(room, character)
        local usr_list = {}
        local removeindex = -1
        for k, v in ipairs(room.character_list) do
                print(character, v.name)
                if character == v.name then
                        removeindex = k
                        break
                end
        end

        if (removeindex ~= -1) then
                table.remove(room.character_list, removeindex)
        end

        for _, v in ipairs(room.mem) do
                if v.fd ~= fd and v.state == MEM_STATE_ENTER then
                        table.insert(usr_list, v)
                end
        end

        if #usr_list > 0 then
                local mem = usr_list[random(#usr_list)]
                local gs = {
                        cmd = "character_list",
                        character_list = room.character_list,
                }
                socket.write(mem.fd, gs)
                return true
        else
                return false
        end
 
end

--state enter
function state_enter_handler.character_sel(self, fd, msg)
        local i
        for k, v in ipairs(self.mem) do
                if v.fd == fd then
                        i = k
                        break
                end
        end

        if self.mem[i].state ~= MEM_STATE_ENTER then
                return
        end

        self.mem[i].state = MEM_STATE_SELCHAR
        self.mem[i].character = character
        self.mem[i].card_list = {
                {name = "kill"},
                {name = "run"},
                {name = "peach"},
                {name = "peach"},
        }

        local origin_card = {
                cmd = "card_list",
                card_list = self.mem[i].card_list,
        }

        socket.write(fd, origin_card)

        if character_sel_next(self, msg.name) == false then
                begin_play(self)               
        end

end


function room:process(fd, msg)
        local func = nil
        if (self.mem[fd].state == MEM_STATE_ENTER) then
                func = state_enter_handler[msg.cmd]
        elseif (self.mem[fd].state == MEM_STATE_SELCHAR) then
                func = state_selchar_handler[msg.cmd]
        elseif (self.mem[fd].state == MEM_STATE_PLAY) then
                func = state_play_handler[msg.cmd]
        end

        if func then
                func(self, fd, msg)
        else
                print("room:process error cmd:", self.mem[fd].state, msg.cmd)
        end
end


return room


