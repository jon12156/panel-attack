local TCP_sock = nil
local type_to_length = {G=1, H=1, N=1, E=4, P=121, O=121, I=2, Q=121, R=121, L=2, U=2}
local leftovers = ""
local wait = coroutine.yield
local floor = math.floor
local char = string.char
local byte = string.byte

function flush_socket()
  if not TCP_sock then return end
  local junk,err,data = TCP_sock:receive('*a')
  -- lol, if it returned successfully then that's bad!
  if not err then
    error("the connection closed unexpectedly")
  end
  leftovers = leftovers..data
end

function close_socket()
  if TCP_sock then
    TCP_sock:close()
  end
  TCP_sock = nil
end

function get_message()
  if string.len(leftovers) == 0 then
    return nil
  end
  local typ, gap, len = string.sub(leftovers,1,1), 0
  if typ == "J" then
    if string.len(leftovers) >= 4 then
      len = byte(string.sub(leftovers,2,2)) * 65536 +
            byte(string.sub(leftovers,3,3)) * 256 +
            byte(string.sub(leftovers,4,4))
      print("json message has length "..len)
      gap = 3
    else
      return nil
    end
  else
    len = type_to_length[typ] - 1
  end
  if len + gap + 1 > string.len(leftovers) then
    return nil
  end
  local ret = string.sub(leftovers,2+gap,len+gap+1)
  leftovers = string.sub(leftovers,len+gap+2)
  return typ, ret
end

local lag_q = Queue()
function net_send(...)
  if not TCP_sock then return false end
  if not STONER_MODE then
    TCP_sock:send(...)
  else
    lag_q:push({...})
    if lag_q:len() == 70 then
      TCP_sock:send(unpack(lag_q:pop()))
    end
  end
  return true
end

function json_send(obj)
  local json = json.encode(obj)
  local len = json:len()
  local prefix = "J"..char(floor(len/65536))..char(floor((len/256)%256))..char(len%256)
  return net_send(prefix..json)
end

function undo_stonermode()
  while lag_q:len() ~= 0 do
    TCP_sock:send(unpack(lag_q:pop()))
  end
end

local got_H = false

local process_message = {
  L=function(s) P2_level = ({["0"]=10})[s] or (s+0) end,
  --G=function(s) got_opponent = true end,
  H=function(s) got_H = true end,
  --N=function(s) error("Server told us to upgrade the game at burke.ro/panel.zip (for burke.ro server) or the TetrisAttackOnline Discord (for Jon's Server)") end,
  N=function(s) error("PLEASE DOWNLOAD the latest version of the game from #welcome-getting-started at the TetrisAttackOnline Discord http://discord.panelattack.com") end,
  P=function(s) P1.panel_buffer = P1.panel_buffer..s end,
  O=function(s) P2.panel_buffer = P2.panel_buffer..s end,
  U=function(s) P1.input_buffer = P1.input_buffer..s end,  -- used for P1's inputs when spectating.
  I=function(s) P2.input_buffer = P2.input_buffer..s end,
  Q=function(s) P1.gpanel_buffer = P1.gpanel_buffer..s end,
  R=function(s) P2.gpanel_buffer = P2.gpanel_buffer..s end,
  E=function(s) net_send("F"..s) connection_up_time = connection_up_time +1 end,  --connection_up_time counts "E" messages, not seconds
  J=function(s)
    local current_message = json.decode(s)
    this_frame_messages[#this_frame_messages+1] = current_message
    print("JSON LOL "..s)
    if not current_message then
      error("Error in network.lua process_message\nMessage: \""..(s or "nil").."\"\ncould not be decoded")
    end
    if current_message.spectators then
      spectator_list = current_message.spectators
      spectators_string = spectator_list_string(current_message.spectators)
    end
  end}

function network_init(ip)
  TCP_sock = socket.tcp()
  TCP_sock:settimeout(7)
  --if not TCP_sock:connect(ip,49569) then --for official server
  if not TCP_sock:connect(ip,59569) then --for beta server
    error("Failed to connect =(")
  end
  TCP_sock:settimeout(0)
  got_H = false
  net_send("H"..VERSION)
  assert(config.name and config.level and config.character and config.save_replays_publicly)
  json_send({name=config.name, level=config.level, character=config.character, save_replays_publicly = config.save_replays_publicly})
end

function connection_is_ready()
  return got_H and #this_frame_messages > 0
end

function do_messages()
  flush_socket()
  while true do
    local typ, data = get_message()
    if typ then
      if typ ~= "I" and typ ~= "U" then
        print("Got message "..typ.." "..data)
      end
      process_message[typ](data)
      if typ == "J" then
        if this_frame_messages[#this_frame_messages].replay_of_match_so_far then
          --print("***BREAKING do_messages because received a replay")
          break  -- don't process any more messages this frame
                   -- we need to initialize P1 and P2 before we do any I or U messages
        end
      end
      if typ == "U" then
        typ = "in_buf"
      end
      if P1 and P1.mode and replay[P1.mode][typ] then
        replay[P1.mode][typ]=replay[P1.mode][typ]..data
      end
    else
      break
    end
  end
end

function request_game(name)
  json_send({game_request = {sender=config.name, receiver=name}})
end

function request_spectate(roomNr)
  json_send({spectate_request = {sender=config.name, roomNumber = roomNr}})
end

function ask_for_panels(prev_panels, stack)
  if TCP_sock then
    net_send("P"..tostring(P1.NCOLORS)..prev_panels)
  else
    make_local_panels(stack or P1, prev_panels)
  end
end

function ask_for_gpanels(prev_panels, stack)
  if TCP_sock then
    net_send("Q"..tostring(P1.NCOLORS)..prev_panels)
  else
    make_local_gpanels(stack or P1, prev_panels)
  end
end

function make_local_panels(stack, prev_panels)
  local ncolors = stack.NCOLORS
  local ret = make_panels(stack.NCOLORS, prev_panels, stack)
  stack.panel_buffer = stack.panel_buffer..ret
  local replay = replay[P1.mode]
  if replay and replay.pan_buf then
    replay.pan_buf = replay.pan_buf .. ret
  end
end

function make_local_gpanels(stack, prev_panels)
  ret = make_gpanels(stack.NCOLORS, prev_panels)
  stack.gpanel_buffer = stack.gpanel_buffer..ret
  local replay = replay[P1.mode]
  if replay and replay.gpan_buf then
    replay.gpan_buf = replay.gpan_buf .. ret
  end
end

function Stack.send_controls(self)
  local k = K[self.which]
  local to_send = base64encode[
    ((keys[k.raise1] or keys[k.raise2] or this_frame_keys[k.raise1]
      or this_frame_keys[k.raise2]) and 32 or 0) +
    ((this_frame_keys[k.swap1] or this_frame_keys[k.swap2]) and 16 or 0) +
    ((keys[k.up] or this_frame_keys[k.up]) and 8 or 0) +
    ((keys[k.down] or this_frame_keys[k.down]) and 4 or 0) +
    ((keys[k.left] or this_frame_keys[k.left]) and 2 or 0) +
    ((keys[k.right] or this_frame_keys[k.right]) and 1 or 0)+1]
  if TCP_sock then
    net_send("I"..to_send)
  end
  local replay = replay[self.mode]
  if replay and replay.in_buf then
    replay.in_buf = replay.in_buf .. to_send
  end
  return to_send
end
