local lppb = Proto("lppb","Length Prefixed Protocol Buffers");
len_F = ProtoField.string("lppb.len","Length")
lppb.fields = {len_F}

lppb.prefs.port = Pref.uint("TCP Port:", 0, "")
lppb.prefs.schema = Pref.string("Schema:", "", "E.g. MY.PROTOBUF.MESSAGE")
lppb.prefs.prefix_size = Pref.uint("Prefix size (bytes):", 4, "")
lppb.prefs.prefix_endianess = Pref.bool("Little Endian ?", true, "Check this to decode the length prefix as if it were encoded as Little Endian")

function get_message_len(tvb, pinfo, tree)
  local length_buf = tvb:range(0, lppb.prefs.prefix_size)
  local len = 0
  if lppb.prefs.prefix_endianess then
    len = Struct.unpack('<I', length_buf:string())
  else
    len = length_buf:uint()
  end
  local result = len + lppb.prefs.prefix_size
  return result
end

function dissect_message(tvb, pinfo, tree)
  local subtree = tree:add(lppb,tvb(),"Length Prefixed Protocol Buffers Data")
  local len = get_message_len(tvb, pinfo, tree)
  subtree:add(len_F, tostring(len - lppb.prefs.prefix_size))
  if lppb.prefs.schema == "" then
    subtree:add_expert_info(PI_DEBUG, PI_ERROR, "No protobuf schema specified")
  else
    local dissector = DissectorTable.get("protobuf.message"):get_dissector(lppb.prefs.schema)
    if dissector == nil then
      subtree:add_expert_info(PI_DEBUG, PI_ERROR, "Schema not found: "..lppb.prefs.schema)
    else
      return dissector:call(tvb(lppb.prefs.prefix_size):tvb(), pinfo, subtree)
    end
  end
  return 0
end

function lppb.dissector(tvb, pinfo, tree)
  dissect_tcp_pdus(tvb, tree, lppb.prefs.prefix_size, get_message_len, dissect_message)
end

local port = 0

lppb.prefs_changed = function()
  if port ~= lppb.prefs.port then
    -- remove old port, if not 0
    if port ~= 0 then
    DissectorTable.get("tcp.port"):remove(port, lppb)
    end

    -- save new port
    port = lppb.prefs.port

    -- add new port, if not 0
    if port ~= 0 then
      DissectorTable.get("tcp.port"):add(port, lppb)
    end
  end
end

