--- sines v1.0.1 ~
-- @oootini
-- @p3r7, @sixolet, @tomwaters,
-- @JosueArias, @x2mirko
-- z_tuning lib by @zebra
--
-- ,-.   ,-.   ,-.
--    `-'   `-'   `-'
--
-- ▼ controls ▼
-- E2 - select sine
-- E3 - selected sine volume
-- K2 - toggle sines/ctrl
-- K3 - toggle env/follow
--
-- 16n control
-- n - sine volume
--
-- z_tuning
-- params > edit > Z_TUNING

engine.name = "Sines"
_mods = require 'core/mods'
_16n = include "sines/lib/16n"
MusicUtil = require "musicutil"

local max_slider_size = 32
local prev_output_level = 0
local prev_amp_slew = 0
local prev_params_jump = 1
local sliders = {}
local fader_follow_vals = {}
local prev_vols = {}
local prev_envs = {}
local envs_set = {}
local fader_abs_vals = {}
local follow_clocks = {}
local crow_out_pairs = {}


for i = 1, 16 do
  fader_follow_vals[i] = 0
  fader_abs_vals[i] = 0
  prev_vols[i] = 0
  prev_envs[i] = 1
  envs_set[i] = 0
  sliders[i] = 0
  follow_clocks[i] = i
  crow_out_pairs[i] = i
end


local edit = 1
local accum = 1
local params_select = 1
-- env_name, env_bias, attack, decay. bias of 1.0 is used to create a static drone
local envs = {
  {"drone", 1.0, 1.0, 1.0},
  {"am1", 0.0, 0.001, 0.01},
  {"am2", 0.0, 0.001, 0.02},
  {"am3", 0.3, 0.001, 0.05},
  {"pulse1", 0.0, 0.001, 0.2},
  {"pulse2", 0.0, 0.001, 0.5},
  {"pulse3", 0.0, 0.001, 0.8},
  {"pulse4", 0.3, 0.001, 1.0},
  {"ramp1", 0.0, 1.5, 0.01},
  {"ramp2", 0.0, 2.0, 0.01},
  {"ramp3", 0.0, 3.0, 0.01},
  {"ramp4", 0.3, 4.0, 0.01},
  {"evolve1", 0.3, 10.0, 10.0},
  {"evolve2", 0.3, 15.0, 11.0},
  {"evolve3", 0.3, 20.0, 12.0},
  {"evolve4", 0.4, 25.0, 15.0}
}

local value = 0
local text = " "
local step = 0
local cents = {}
local notes = {}
local scale_names = {}
local scale_toggle = false
local control_toggle = false
-- active state for sliders, params 0-3
local current_state = {15, 2, 2, 2, 2}
local prev_16n_slider_v = {
  vol = {}
}

local fps = 14
local screen_dirty = false

local crow_option = {"quad v/o", "v/o + env", "v/o + trig"}
-- crow_outs maps individual sine synth outputs to crow outs 1-4 as hz > 1v/oct
local crow_outs = {
  {1, 3, 5, 7},
  {1, 5, 8, 10},
  {1, 5, 8, 12},
  {1, 5, 8, 11},
  {1, 5, 9, 11},
  {1, 6, 8, 11},
  {1, 4, 8, 12},
  {1, 4, 8, 10},
  {1, 4, 8, 11},
  {1, 4, 7, 10},
  {1, 4, 7, 11},
  {1, 5, 9, 12}
}

local sample_bitrates = {
  {"hifi", 48000, 24},
  {"clean1", 44100, 12},
  {"clean2", 32000, 10},
  {"clean3", 28900, 10},
  {"grunge1", 34800, 6},
  {"grunge2", 30700, 6},
  {"grunge3", 28600, 6},
  {"lofi1", 24050, 5},
  {"lofi2", 20950, 4},
  {"lofi3", 15850, 3},
  {"crush1", 10000, 3},
  {"crush2", 6000, 2},
  {"crush3", 800, 1}
}

local g = grid.connect()
local grid_width = g.cols
local grid_height = g.rows
local grid_slider_scale = max_slider_size / grid_height
local monobright = false

-- handle monobright grids
if util.string_starts(g.name, 'monome 64 m64')
  or util.string_starts(g.name, 'monome 128 m128')
  or util.string_starts(g.name, 'monome 256 m256') then
    monobright = true
end

function init()
  print("loaded Sines engine ~")
  add_params()

  edit = 0
  for i = 1, 16 do
    if not z_tuning then
      cents[i] = params:get("cents" .. i)
    end
    sliders[i] = (params:get("vol" .. i)) * max_slider_size
    prev_vols[i] = params:get("vol" .. i)
    prev_envs[i] = params:get("env" .. i)
  end

  _16n.init(_16n_slider_callback)
  for i = 1, 16 do
    prev_16n_slider_v["vol"][i] = util.linlin(0.0, 1.0, 0, 127, params:get("vol" .. i))
  end

  redraw_clock = clock.run(
    function()
      local step_s = 1 / fps
      while true do
        clock.sleep(step_s)
        if screen_dirty then
          set_active()
          redraw()
          screen_dirty = false
        end
      end
    end)

  for i = 1, 16 do
    follow_clocks[i] = clock.run(
      function()
        local step_s = 1 / fps
        while true do
          clock.sleep(step_s)
          -- bang the env delay rand value
          engine.env_delay_rand(i - 1, math.random() * params:get("env_delay_rand" .. i))
          fader_abs_vals[i] = params:get("fader" .. i)
          fader_follow_vals[i] = follow_countdown(i, fader_abs_vals[i])
          if params:get("play_mode") == 1 then
            if math.abs(fader_follow_vals[i] - fader_abs_vals[i]) > 10 then
              engine.vol(i - 1 , util.linexp(0, 127, 0.0, 1.0, fader_follow_vals[i]))
            end
            if fader_follow_vals[i] <= 10 then
              --reset slider to 0
              sliders[i] = 0
            end
          end
        end
        screen_dirty = false
      end)
  end

  -- check if z_tuning
  local ztuning
  if _mods.is_enabled('z_tuning') then
    z_tuning = require('z_tuning/lib/mod')
  end

  -- if z_tuning, configure and refresh all sine freqs when z_tuning changes
  if z_tuning then
    z_tuning.set_tuning_change_callback(
      function()
        local num, hz
        for voice = 1, 16 do
          num = params:get("note" .. voice)
          hz = MusicUtil.note_num_to_freq(num)
          engine.hz(voice - 1, hz)
        end
        if norns.crow.connected() then
          set_crow(params:get("crow_config"))
        end
      end)
  end
end

function cleanup()
  clock.cancel(redraw_clock)
  for i = 1, 16 do
    clock.cancel(follow_clocks[i])
  end
end

function is_prev_16n_slider_v_crossing(mode, i, v)
  local prev_v = prev_16n_slider_v[mode][i]
  if mode ~= "vol" and params:string("16n_params_jump") == "yes" then
    return true
  end
  if prev_v == nil then
    return true
  end
  if math.abs(v - prev_v) < 10 then
    return true
  end
  return false
end

function _16n_slider_callback(midi_msg)
  if params:string("16n_auto") == "no" then
  return
  end
  if midi_msg.type == "cc" then
    local slider_id = _16n.cc_2_slider_id(midi_msg.cc)
    local v = midi_msg.val

    -- update current slider
    params:set("fader" .. slider_id, v)
  end
end

function virtual_slider_callback(slider_id, v)
  accum = slider_id - 1
  edit = accum

  if is_prev_16n_slider_v_crossing("vol", slider_id, v) then
    params:set("vol" .. edit + 1, util.linlin(0, 127, 0.0, 1.0, v))
    prev_16n_slider_v["vol"][slider_id] = v
  end

  screen_dirty = true
end

function add_params()
  -- set the scale note values
  for i = 1, #MusicUtil.SCALES do
    table.insert(scale_names, string.lower(MusicUtil.SCALES[i].name))
  end

  params:add{type = "option", id = "scale_mode", name = "scale mode",
    options = scale_names, default = 5, action = function() set_notes() end}

  params:add{type = "number", id = "root_note", name = "root note",
  min = 0, max = 127, default = 60, formatter = function(param) return MusicUtil.note_num_to_name(param:get(), true) end, action = function() set_notes() end}

  -- amp slew
  params:add_control("amp_slew", "amp slew", controlspec.new(0.01, 10, 'lin', 0.01, 0.7, 's'))
  params:set_action("amp_slew", function(x) set_amp_slew(x) end)

  -- 16n control
  params:add_group("16n config", 2)
  params:add{type = "option", id = "16n_auto", name = "auto bind 16n", options = {"yes", "no"}, default = 1}
  params:add{type = "option", id = "16n_params_jump", name = "16n param jumps", options = {"yes", "no"}, default = 2}

  params:add_group("faders config", 2)
  -- reset style
  params:add{type = "option", id = "reset_style", name = "fader reset style", options = {"return", "zeroed"}, default = 2}

  -- play mode
  params:add{type = "number", id = "play_mode", name = "fader play mode", min = 0, max = 1, default = 0, formatter = function(param) return play_mode_formatter(param:get()) end, action = function(x) set_play_mode(x) end}

  -- crow config params
  params:add{type = "number", id = "crow_config", name = "crow config", min = 1, max = 3, default = 2, formatter = function(param) return crow_config_formatter(param:get()) end, action = function(x) set_crow(x) end}

  -- crow out quad v/o
  params:add{type = "number", id = "crow_out_vo", name = "crow v/o", min = 1, max = 12, default = 5, formatter = function(param) return crow_out_formatter(param:get()) end, action = function(x) set_crow_notes(x) end}

  -- crow out pairs
  params:add{type = "number", id = "crow_out_pairs", name = "crow v/o + out", min = 1, max = 16, default = 4, formatter = function(param) return crow_out_pairs_formatter(param:get()) end, action = function(x) set_crow_note_out_pairs(x) end}

  -- env delay
  params:add_group("env delay", 17)
  params:add_control("env_delay_rand_global", "global env delay rand mult", controlspec.new(0.0, 1.0, 'lin', 0.1, 0.0))
  params:set_action("env_delay_rand_global", function(x) set_env_delay_rand_global(x) end)
  for i = 1,16 do
    params:add_control("env_delay_rand" .. i, i .. "n env delay rand mult", controlspec.new(0.0, 1.0, 'lin', 0.1, 0.0))
    params:set_action("env_delay_rand" .. i, function(x) set_env_delay_rand(i - 1, x) end)
  end

  -- global pan settings
  params:add{type = "number", id = "global_pan", name = "global panning", min = 0, max = 1, default = 0, formatter = function(param) return global_pan_formatter(param:get()) end, action = function(x) set_global_pan(x) end}

  for i = 1, 16 do
    -- set voice params
    params:add_group(i .. "n voice", 13)
    -- set voice vols
    params:add_control("vol" .. i,  i .. "n vol", controlspec.new(0.0, 1.0, 'lin', 0.01, 0.0))
    params:set_action("vol" .. i, function(x) set_vol(i - 1, x) end)

    params:add{type = "number", id = "pan" ..i, name = i .. "n pan", min = -1, max = 1, default = 0, formatter = function(param) return pan_formatter(param:get()) end, action = function(x) set_synth_pan(i - 1, x) end}

    params:add{type = "number", id = "note" .. i, name = i .. "n note", min = 0, max = 127, default = 60, formatter = function(param) return MusicUtil.note_num_to_name(param:get(), true) end, action = function(x) set_note(i - 1, x) end}

    if not z_tuning then
      params:add_control("cents" .. i, i .. "n cents detune", controlspec.new(-200, 200, 'lin', 1, 0, 'cents'))
      params:set_action("cents" .. i, function(x) tune(i - 1, x) end)
    end

    params:add_control("fm_index" .. i, i .. "n fm index", controlspec.new(0.0, 200.0, 'lin', 1.0, 3.0))
    params:set_action("fm_index" .. i, function(x) set_fm_index(i - 1, x) end)

    params:add{type = "number", id = "env" .. i, name = i .. "n env", min = 1, max = 16, default = 1, formatter = function(param) return env_formatter(param:get()) end, action = function(x) set_env(i, x) end}

    params:add_control("attack" .. i, i .. "n attack", controlspec.new(0.01, 15.0, 'lin', 0.01, 1.0, 's'))
    params:set_action("attack" .. i, function(x) set_amp_atk(i - 1, x) end)

    params:add_control("decay" .. i, i .. "n decay", controlspec.new(0.01, 15.0, 'lin', 0.01, 1.0, 's'))
    params:set_action("decay" .. i, function(x) set_amp_rel(i - 1, x) end)

    params:add_control("env_bias" .. i, i .. "n bias", controlspec.new(0.0, 1.0, 'lin', 0.1, 1.0))
    params:set_action("env_bias" .. i, function(x) set_env_bias(i - 1, x) end)

    params:add{type = "number", id = "env_delay" .. i, name = i .. "n env delay", min = 0, max = 2000, default = 0, formatter = function(param) return env_delay_formatter(param:get()) end, action = function(x) set_amp_env_delay(i - 1, x) end}

    params:add{type = "number", id = "sample_bitrate" .. i, name = i .. "n smpl bitrate", min = 1, max = 13, default = 1, formatter = function(param) return sample_bitrate_formatter(param:get()) end, action = function(x) set_sample_bitrate(i, x) end}

    params:add_control("bit_depth" .. i, i .. "n bit depth", controlspec.new(1, 24, 'lin', 1, 24, 'bits'))
    params:set_action("bit_depth" .. i, function(x) set_bit_depth(i - 1, x) end)

    params:add_control("smpl_rate" .. i, i .. "n sample rate", controlspec.new(480, 48000, 'lin', 100, 48000, 'hz'))
    params:set_action("smpl_rate" .. i, function(x) set_sample_rate(i - 1, x) end)
  end

  -- set virtual faders params
  params:add_group("virtual faders", 16)
  for i = 1, 16 do
    params:add{type = "number", id = "fader" ..i, name = "fader " .. i, min = 0, max = 127, default = 0, action = function(v) virtual_slider_callback(i, v) end}
  end

  params:hide("crow_out_vo")
  params:hide("crow_out_pairs")

  params:read()
  params:bang()

  if norns.crow.connected() then
    set_crow(params:get("crow_config"))
    if params:get("crow_config") == 2 or params:get("crow_config") == 3 then
      crow.output[2]()
      crow.output[4]()
    end
  end
  if not norns.crow.connected() then
    params:hide("crow_config")
  end

end

function build_scale()
  notes = MusicUtil.generate_scale_of_length(params:get("root_note"), params:get("scale_mode"), 16)
  local num_to_add = 16 - #notes
  for i = 1, num_to_add do
    table.insert(notes, notes[16 - num_to_add])
  end
end

function set_notes()
  build_scale()
  scale_toggle = true
  for i = 1, 16 do
    params:set("note" .. i, notes[i])
    --TODO this is currently unused, is that right?
    local hz_value = MusicUtil.note_num_to_freq(notes[i])
    if norns.crow.connected() then
      set_crow(params:get("crow_config"))
    end
  end
end

function hz_to_1voct(hz, root_freq)
  local v_oct = math.log10(hz/root_freq)/math.log10(2)
  return v_oct
end

function set_crow_notes(x)
  -- quad vo
  for i = 1, 4 do
    local crow_voice = crow_outs[x][i]
    if z_tuning then
      local hz = MusicUtil.note_num_to_freq(params:get("note" .. crow_voice))
      crow.output[i].volts = hz_to_1voct(hz, params:get("zt_root_freq"))
    else
      crow.output[i].volts = params:get("note" .. crow_voice)/12
    end
  end
end

function set_crow_note_out_pairs(i)
  if z_tuning then
    -- 1n v/o output
    crow.output[1].volts = hz_to_1voct(MusicUtil.note_num_to_freq(params:get("note" .. 1)), params:get("zt_root_freq"))
    -- n v/o output
    crow.output[3].volts = hz_to_1voct(MusicUtil.note_num_to_freq(params:get("note" .. i)), params:get("zt_root_freq"))
  else
    crow.output[1].volts = params:get("note1")/12
    crow.output[3].volts = params:get("note" .. i)/12
  end
  -- set crow out 2 & 4 action
  if params:get("crow_config") == 2 then
    -- env action
    crow.output[2].action = "loop{ to(0, dyn{crow_out_delay2 = 0.0}), to(7, dyn{crow_attack2 = 0.01}), to(0, dyn{crow_decay2 = 0.1}) }"
    crow.output[4].action = "loop{ to(0, dyn{crow_out_delay4 = 0.0}), to(7, dyn{crow_attack4 = 0.01}), to(0, dyn{crow_decay4 = 0.1}) }"
    -- set env delay
    crow.output[2].dyn.crow_out_delay2 = params:get("env_delay1")/100 + math.random() * params:get("env_delay_rand1")
    crow.output[4].dyn.crow_out_delay4 = params:get("env_delay" .. i)/100 + math.random() * params:get("env_delay_rand" .. i)
    -- set env attack/decay
    crow.output[2].dyn.crow_attack2 = params:get("attack1")
    crow.output[2].dyn.crow_decay2 = params:get("decay1")
    crow.output[4].dyn.crow_attack4 = params:get("attack" .. i)
    crow.output[4].dyn.crow_decay4 = params:get("decay" .. i)
  elseif params:get("crow_config") == 3 then
    -- trigs
    crow.output[2].action = "loop{ to(0, dyn{crow_out_delay2 = 0.0}), to(5, 0.001, 'now'), to(0, 0.001, 'now') }"
    crow.output[4].action = "loop{ to(0, dyn{crow_out_delay4 = 0.0}), to(5, 0.001, 'now'), to(0, 0.001, 'now') }"
    -- sum env values for total trig delay
    crow.output[2].dyn.crow_out_delay2 = params:get("attack1") + params:get("decay1") + params:get("env_delay1")/100 + math.random() * params:get("env_delay_rand1")
    crow.output[4].dyn.crow_out_delay4 = params:get("attack" .. i) + params:get("decay" .. i) + params:get("env_delay" .. i)/100 + math.random() * params:get("env_delay_rand" .. i)
  end
end

function set_crow(x)
  if x == 1 then
    set_crow_notes(params:get("crow_out_vo"))
  elseif x == 2 or x ==3 then
    set_crow_note_out_pairs(params:get("crow_out_pairs"))
  end
end

function set_play_mode(x)
  if x == 0 then
    -- faders
    params:set('output_level', prev_output_level)
    params:set('amp_slew', prev_amp_slew)
    params:set('16n_params_jump', prev_params_jump)
    for i = 1,16 do
      -- init prev_envs with correct values
      -- this is icky there must be a beter way to do this
      if envs_set[i] == 0 then
        prev_envs[i] = params:get("env" .. i)
        envs_set[i] = 1
      end
      params:set("env" .. i, prev_envs[i])
      if params:string("reset_style") == "return" then
        params:set("env" .. i, prev_envs[i])
        params:set("vol" .. i, prev_vols[i])
        sliders[i] = math.floor(util.linlin(0.0, 1.0, 0, 32, prev_vols[i]))
      elseif params:string("reset_style") == "zeroed" then
        params:set("vol" .. i, 0)
      end
      prev_envs[i] = params:get("env" .. i)
      screen_dirty = true
    end
  elseif x == 1 then
    -- env follower
    prev_output_level = params:get('output_level')
    prev_slew_level = params:get('amp_slew')
    prev_params_jump = params:get("16n_params_jump")
    params:set("16n_params_jump", 1)
    for i = 1,16 do
      -- this is very goofy
      prev_vols[i] = params:get("vol" .. i)
      prev_envs[i] = params:get("env" .. i)
      params:set("vol" .. i, 0)
      params:set("env" .. i, 1.0)
      sliders[i] = 0
      screen_dirty = true
    end
    -- slight bump because this mode is a bit quieter
    params:set('output_level', 3)
    params:set('amp_slew', 2)
  end
end

function set_env_delay_rand_global(value)
  for i = 1,16 do
    params:set("env_delay_rand" .. i, value)
  end
end

function set_env_delay_rand(synth_num, value)
  engine.env_delay_rand(synth_num, value)
  if norns.crow.connected() then
    if params:get("crow_config") == 2 then
      set_crow(2)
    end
  end
end

function set_amp_slew(slew_rate)
  -- set the slew rate for every voice
  for i = 0, 15 do
    engine.amp_slew(i, slew_rate)
  end
end

function set_note(synth_num, value)
  notes[synth_num] = value
  -- also reset the cents value here too
  if not z_tuning then
    params:set("cents" .. synth_num + 1, 0)
  end
  local hz_value = MusicUtil.note_num_to_freq(notes[synth_num])
  engine.hz(synth_num, hz_value)
  engine.hz_lag(synth_num, 0.005)
  if scale_toggle then
    -- do nothing
  end
  if not scale_toggle then
    edit = synth_num
  end
  if norns.crow.connected() then
    set_crow(params:get("crow_config"))
  end
  screen_dirty = true
end

function set_freq(synth_num, value)
  engine.hz(synth_num, value)
  engine.hz_lag(synth_num, 0.005)
  edit = synth_num
  screen_dirty = true
end

function set_vol(synth_num, value)
  engine.vol(synth_num, value * 0.2)
  edit = synth_num
  -- update displayed sine value
  local s_id = (synth_num + 1)
  sliders[s_id] = math.floor(util.linlin(0.0, 1.0, 0, max_slider_size, value))

  screen_dirty = true
end

function follow_countdown(i, abs_val)
  local count = fader_follow_vals[i]
  if count ~= abs_val then
    count = util.clamp(count - 1, 0, 127)
  end
  return count
end

function tune(synth_num, value)
  -- calculate new tuned value from cents value + midi note
  -- https://music.stackexchange.com/questions/17566/how-to-calculate-the-difference-in-cents-between-a-note-and-an-arbitrary-frequen
  local detuned_freq = (math.pow(10, value / 3986)) * MusicUtil.note_num_to_freq(notes[synth_num])
  -- round to 2 decimal points
  detuned_freq = math.floor((detuned_freq) * 10 / 10)
  set_freq(synth_num, detuned_freq)
  edit = synth_num
  screen_dirty = true
end

function set_env(synth_num, value)
  -- env_name, env_bias, attack, decay
  params:set("env_bias" .. synth_num, envs[value][2])
  params:set("attack" .. synth_num, envs[value][3])
  params:set("decay" .. synth_num, envs[value][4])
  if norns.crow.connected() then
    set_crow(params:get("crow_config"))
  end
end

function env_formatter(value)
  local env_name = envs[value][1]
  return (env_name)
end

function crow_out_formatter(num)
  -- return the list as a string
  local crow_output = table.concat(crow_outs[num], ",")
  return (crow_output)
end

function crow_config_formatter(num)
  local crow_config = crow_option[num]
  return (crow_config)
end

function crow_out_pairs_formatter(num)
  -- create crow_out_pairs array of eg., {"1n + 2n", 1, 2}, {"1n + 3n", 1, 3}, etc
  local pair = "1n + " .. num .. "n"
  crow_out_pairs[num] = {pair, 1, num}
  return (crow_out_pairs[num][1])
end

function env_delay_formatter(value)
  local env_delay_ms = value/100
  return (env_delay_ms)
end

function sample_bitrate_formatter(value)
  local sample_bitrate_preset = sample_bitrates[value][1]
  return (sample_bitrate_preset)
end

function set_sample_bitrate(synth_num, value)
  params:set("smpl_rate" .. synth_num, sample_bitrates[value][2])
  params:set("bit_depth" .. synth_num, sample_bitrates[value][3])
  screen_dirty = true
end

function set_fm_index(synth_num, value)
  engine.fm_index(synth_num, value)
  edit = synth_num
  screen_dirty = true
end

function set_amp_atk(synth_num, value)
  engine.amp_atk(synth_num, value)
  edit = synth_num
  screen_dirty = true
end

function set_amp_rel(synth_num, value)
  engine.amp_rel(synth_num, value)
  edit = synth_num
  screen_dirty = true
end

function set_amp_env_delay(synth_num, value)
  engine.env_delay(synth_num, value/100)
  edit = synth_num
  screen_dirty = true
end

function set_env_bias(synth_num, value)
  engine.env_bias(synth_num, value)
  edit = synth_num
  screen_dirty = true
end

function set_bit_depth(synth_num, value)
  engine.bit_depth(synth_num, value)
  edit = synth_num
  screen_dirty = true
end

function set_sample_rate(synth_num, value)
  engine.sample_rate(synth_num, value)
  edit = synth_num
  screen_dirty = true
end

function set_synth_pan(synth_num, value)
  engine.pan(synth_num, value)
  screen_dirty = true
end

function pan_formatter(value)
  if value == -1 then
    text = "right"
  elseif value == 0 then
    text = "middle"
  elseif value == 1 then
    text = "left"
  end
  return (text)
end

function global_pan_formatter(value)
  if value == 0 then
    text = "middle"
  elseif value == 1 then
    text = "left/right"
  end
  return (text)
end

function play_mode_formatter(value)
  if value == 0 then
    text = "fader"
  elseif value == 1 then
    text = "env follower"
  end
  return (text)
end

function set_active()
  if control_toggle then
    -- set params
    if params_select == 0 then
      current_state = {5, 15, 2, 2, 2}
    elseif params_select == 1 then
      current_state = {5, 2, 15, 2, 2}
    elseif params_select == 2 then
      current_state = {5, 2, 2, 15, 2}
    elseif params_select == 3 then
      current_state = {5, 2, 2, 2, 15}
    end
  else
    -- set sliders active
    current_state = {15, 2, 2, 2, 2}
  end
  screen_dirty = true
end

function set_global_pan(value)
  -- pan position on the bus, 0 is middle, 1 is l/r
  if value == 0 then
    for i = 1, 16 do
      set_synth_pan(i, 0)
      params:set("pan" .. i, 0)
    end
  elseif value == 1 then
    for i = 1, 16 do
      if i % 2 == 0 then
        -- even, pan right
        set_synth_pan(i, 1)
        params:set("pan" .. i, 1)
      elseif i % 2 == 1 then
        -- odd, pan left
        set_synth_pan(i, -1)
        params:set("pan" .. i, -1)
      end
    end
  end
end

-- update when a cc change is detected
m = midi.connect()
m.event = function(data)
local d = midi.to_msg(data)
  if d.type == "note_on" then
    params:set("root_note", d.note)
  end
  screen_dirty = true
end

function enc(n, delta)
  if n == 1 then
    if control_toggle then
      -- select params line 0-3
     params_select = (params_select + delta) % 4
    end
  elseif n == 2 then
    if control_toggle then
      if params_select == 0 then
        -- increment the note value with delta
        if not z_tuning then
          params:set("note" .. edit + 1, params:get("note" .. edit + 1) + delta)
          local synth_num =  edit + 1
          local hz_value = MusicUtil.note_num_to_freq(notes[synth_num])
        end
        if norns.crow.connected() then
          set_crow(params:get("crow_config"))
        end
      elseif params_select == 1 then
        -- envl
        params:set("env" .. edit + 1, params:get("env" .. edit + 1) + delta)
        if norns.crow.connected() then
          set_crow(params:get("crow_config"))
        end
      elseif params_select == 2 then
        -- smpl
        params:set("sample_bitrate" .. edit + 1, params:get("sample_bitrate" .. edit + 1) + (delta))
      elseif params_select == 3 then
        -- pan
        params:set("pan" .. edit + 1, params:get("pan" .. edit + 1) + (delta))
      end
    elseif not control_toggle then
      -- navigate up/down the list of sliders
      -- accum wraps around 0-15
      accum = (accum + delta) % 16
      --edit is the slider number
      edit = accum
    end
  elseif n == 3 then
    if control_toggle then
      if params_select == 0 then
        -- detune
        if not z_tuning then
          params:set("cents" .. edit + 1, params:get("cents" .. edit + 1) + delta)
        end
      elseif params_select == 1 then
        -- env delay
        params:set("env_delay" .. edit + 1, params:get("env_delay" .. edit + 1) + delta)
        if norns.crow.connected() then
          set_crow(params:get("crow_config"))
        end
      elseif params_select == 2 then
        -- fm index
        params:set("fm_index" .. edit + 1, params:get("fm_index" .. edit + 1) + delta)
      elseif params_select == 3 then
        -- crow
        if params:get("crow_config") == 1 then
          params:set("crow_out_vo", params:get("crow_out_vo") + delta)
        elseif params:get("crow_config") == 2 then
          params:set("crow_out_pairs", params:get("crow_out_pairs") + delta)
          screen.text("1n + " .. params:get("crow_out_pairs") .. "n")
        elseif params:get("crow_config") == 3 then
          params:set("crow_out_pairs", params:get("crow_out_pairs") + delta)
          screen.text("1n + " .. params:get("crow_out_pairs") .. "n ^")
        end
      end
    elseif not control_toggle then
      -- current slider amplitude
      local new_v = sliders[edit + 1] + (delta * 2)
      local amp_value = util.linlin(0, max_slider_size, 0.0, 1.0, new_v)
      params:set("vol" .. edit + 1, amp_value)
    end
  end
  screen_dirty = true
end

function key(n, z)
  if n == 2 and z == 1 then
    control_toggle = not control_toggle
  elseif n == 3 and z == 1 then
    if params:get("play_mode") == 0 then
      -- faders
      params:set("play_mode", 1)
    elseif params:get("play_mode") == 1 then
      -- env follower
      params:set("play_mode", 0)
    end
  end
  screen_dirty = true
end

function redraw()
  redraw_screen()
  redraw_grid()
end

function redraw_screen()
  screen.aa(1)
  screen.line_width(2.0)
  screen.clear()

  for i = 0, 15 do
    if i == edit then
      screen.level(15)
    else
      screen.level(2)
    end
    screen.move(32 + i * 4, 62)
    screen.line(32 + i * 4, 60 - sliders[i + 1])
    screen.stroke()
  end
  screen.level(10)
  screen.line(32 + step * 4, 68)
  screen.stroke()
  -- display current values
  if z_tuning then
    screen.move(0, 5)
    screen.level(2)
    screen.text("ztun:")
    screen.move(24, 5)
    -- get the tuning state
    tuning_table = z_tuning.get_tuning_state()
    if tuning_table and tuning_table.selected_tuning then
      selected_tuning_value = tuning_table.selected_tuning
    end
    -- clip to fit on the screen
    screen.text(string.sub(selected_tuning_value, 1, 7))
    screen.move(62, 5)
    screen.level(2)
    screen.text("root:")
    screen.move(89, 5)
    screen.text((string.format("%.2f", params:get("zt_root_freq"))) .. "hz")
  else
    screen.move(0, 5)
    screen.level(2)
    screen.text("note: ")
    screen.level(current_state[2])
    screen.move(24, 5)
    screen.text(MusicUtil.note_num_to_name(params:get("note" .. edit + 1), true) .. " ")
    screen.move(62, 5)
    screen.level(2)
    screen.text("dtun:")
    screen.level(current_state[2])
    screen.move(89, 5)
    screen.text(params:get("cents" .. edit + 1) .. " cents")
  end
  screen.move(0, 12)
  screen.level(2)
  screen.text("envl:")
  screen.level(current_state[3])
  screen.move(24, 12)
  if params:get("play_mode") == 1 then
    screen.text("[follow]")
  else
    screen.text(env_formatter(params:get("env" .. edit + 1)))
  end
  screen.level(2)
  screen.move(62, 12)
  screen.text("envd:")
  screen.level(current_state[3])
  screen.move(89, 12)
  screen.text(env_delay_formatter(params:get("env_delay" .. edit + 1)) .. " s")
  screen.move(0, 19)
  screen.level(2)
  screen.text("smpl:")
  screen.level(current_state[4])
  screen.move(24, 19)
  screen.text(sample_bitrate_formatter(params:get("sample_bitrate" .. edit + 1)))
  screen.level(2)
  screen.move(62, 19)
  screen.text("fmind:")
  screen.level(current_state[4])
  screen.move(89, 19)
  screen.text(params:get("fm_index" .. edit + 1))
  screen.move(0, 26)
  screen.level(2)
  screen.text("pan:")
  screen.level(current_state[5])
  screen.move(24, 26)
  screen.text(pan_formatter(params:get("pan" .. edit + 1)))
  screen.level(2)
  screen.move(62, 26)
  screen.text("crow:")
  screen.level(current_state[5])
  screen.move(89, 26)
  if norns.crow.connected() then
    if params:get("crow_config") == 1 then
      screen.text(crow_out_formatter(params:get("crow_out_vo")))
    elseif params:get("crow_config") == 2 then
      screen.text("1n + " .. params:get("crow_out_pairs") .. "n")
    elseif params:get("crow_config") == 3 then
      screen.text("1n + " .. params:get("crow_out_pairs") .. "n ^")
    end
  else
    screen.text("none")
  end
  screen.update()
end

function redraw_grid()
  g:all(0)
  for x = 1, grid_width do
    local col_height = grid_height - math.ceil(sliders[x] / grid_slider_scale)
    for y = col_height, grid_height do
      if monobright then
        g:led(x,y,15)
      else
        g:led(x,y,x == (edit + 1) and 8 or 4)
      end
    end
  end
  g:refresh()
end

g.key = function(x,y,z)
  if z == 1 then
    local amp_value = util.linlin(0, grid_height, 0.0, 1.0, grid_height - y)
    params:set("vol" .. x, amp_value)
    edit = x - 1
  end
  screen_dirty = true
end