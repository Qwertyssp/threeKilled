local socket = require("socket")
local timer = require("timer")
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

local SEG_FINISH                = 1
local SEG_GET                   = 2
local SEG_SEND                  = 3
local SET_GIVEUP                = 4

local state_enter_handler = {}
local state_selchar_handler = {}
local state_play_handler = {}

--TODO: t.mem will can occurs hole when the user exit the room

local function new_mem(fd, uid)
        local t = {
                fd = fd,
                uid = uid,
                state = MEM_STATE_ENTER,
                character = nil,
                card_list = {},
                hp = 4,
                seg = SEG_FINISH,
                effect_card = "",
                current_time = 0,
        }

        return t
end

function room:create(fd, uid)
        local t = {
                owner = uid,
                mem = {
                        [fd] = new_mem(fd, uid)
                },
                
                name = tostring(uid) .. "room",
                count = 1,
                round_index = nil,
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
        local mem = new_mem(fd, msg.uid)

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

local function round_next(room)
        local index = nil
        local match = false
        local ri = room.round_index
        room.round_index = nil

        for k, v in pairs(room.mem) do
                if (ri == nil) or (ri == k) then
                        match = true
                elseif match then
                        room.round_index = k
                end
        end


        -- round the begin
        if room.round_index == nil then
                for k, v in pairs(room.mem) do
                        room.round_index = k
                        break;
                end
        end

        room.mem[room.round_index].current_time = timer.current()
        room.mem[room.round_index].seg = SEG_GET
end

local function seg_next(room, index)
        local mem = room.mem[index]
        assert(mem)

        if mem.seg == SEG_GET then
                mem.seg = SEG_SEND
        elseif mem.seg == SEG_SEND then
                mem.seg = SEG_GIVEUP
        elseif mem.seg == SEG_GIVEUP then
                mem.seg = SEG_FINISH
        elseif mem.seg == SEG_FINISH then
                print("error")
        end

        mem.current_time = timer.current()

        return 
end

local function seg_get(room, index)
        local mem = room.mem[index]
        assert(mem)
        if timer.current() - mem.current_time < 1000 then       --delay 1s
                return 
        else
                seg_next(room, index)
        end

        local card_add = {
                {name = "run"},
                {name = "peach"},
        }

        for _, v in pairs(card_add) do
                table.insert(room.mem[index].card_list, v)
        end

        local card_list = {
                cmd = "seg_get",
                card_list = room.mem[index].card_list,
        }

        socket.write(room.mem[index].fd, card_list)
end

local function seg_send(room, index)
        local mem = room.mem[index]
        assert(mem)
        if timer.current() - mem.current_time < 3000 then       --delay 3s
                return
        else
                seg_next(room, index)
        end

        local res_send = {
                cmd = "seg_send"
        }

        socket.write(room.mem[index].fd, res_send)
end

local function seg_giveup(room, index)
        local mem = room.mem[index]
        assert(mem)
        if timer.current() - mem.current_time < 3000 then       --delay 1s
                return
        else
                seg_next(room, index)
                round_next(room)
        end

        local res_giveup = {
                cmd = "seg_giveup"
        }

        socket.write(room.mem[index].fd, res_giveup)

        return
end

local function seg_finish(room, index)

end

local function update_user(room)
        
        local index = room.round_index
        local mem = room.mem[index]
        
        if mem then
                timer.add(3000, update_user, room)
        end

        assert(mem.state == MEM_STATE_PLAY)
        if (mem.seg == SEG_GET) then
                seg_get(room, index)
        elseif (mem.seg == SEG_SEND) then
                seg_send(room, index)
        elseif (mem.seg == SEG_GIVEUP) then
                seg_giveup(room, index)
        elseif (mem.seg == SEG_FINISH) then
                seg_finish(room, index)
        else
                print("unknow segment", mem.state)
        end
end

local function begin_play(room)
        round_next(room)
        update_user(room)
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

        character_sel_next(self, msg.name)

        return
end

--state selchar
function state_selchar_handler.ready(self, fd, msg)
        self.mem[fd].state = MEM_STATE_PLAY
        
        local all_ready = true
        for _, v in pairs(self.mem) do
                if v.state ~= MEM_STATE_PLAY then
                        all_ready = false
                        break;
                end
        end

        if all_ready then
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


