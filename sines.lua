--- ~ Sines v0.7 ~
-- E1 - norns volume
-- E2 - select sine 1-16
-- E3 - set sine amplitude
-- K2 + E2 - change note
-- K2 + E3 - detune
-- K3 + E2 - change envelope
-- K3 + E3 - change FM index
-- K2 + K3 - set voice panning

-- arc lfo control vars
a = arc.connect()
-- aspirational
-- c = clock.set_source("midi")
local framerate = 40
local arcDirty = true
local startTime
local tau = math.pi * 2
local newSpeed = false
local options = {}
local lfo = {}
for i=1,16 do
  lfo[i] = {init=1, freq=1, counter=1, interpolator=1}
end
local voice_quad = 1

-- engine control vars
local sliders = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}
local env_types = {"drone", "am1", "am2", "am3", "pulse1", "pulse2", "pulse3", "pulse4", "ramp1", "ramp2", "ramp3", "ramp4", "evolve1", "evolve2", "evolve3", "evolve4", "arc"}
-- env_num, env_bias, attack, decay. bias of 1.0 is used to create a static drone
local envs = {{1, 1.0, 1.0, 1.0},--drone
{2, 0.0, 0.001, 0.01},--am1
{3, 0.0, 0.001, 0.02},--am2
{4, 0.0, 0.001, 0.05},--am3
{5, 0.0, 0.001, 0.1},--pulse1
{6, 0.0, 0.001, 0.2},--pulse2
{7, 0.0, 0.001, 0.5},--pulse3
{8, 0.0, 0.001, 0.8},--pulse4
{9, 0.0, 1.5, 0.01},--ramp1
{10, 0.0, 2.0, 0.01},--ramp2
{11, 0.0, 3.0, 0.01},--ramp3
{12, 0.0, 4.0, 0.01},--ramp4
{13, 0.3, 10.0, 10.0},--evolve1
{14, 0.3, 15.0, 11.0},--evolve2
{15, 0.3, 20.0, 12.0},--evolve3
{16, 0.3, 25.0, 15.0},--evolve4
{17, 0.0, 1.0, 1.0} -- arc
}
local env_values = {}
local fm_index_values = {}
local edit = 1
local env_edit = 1
local accum = 1
local env_accum = 1
local step = 0
local freq_increment = 0
local cents_increment = 0
local cents_values = {}
local scale_names = {}
local notes = {}
local key_2_pressed = 0
local key_3_pressed = 0
local toggle = false
local pan_display = "m"
local interp_divisor = 100


engine.name = "Sines"
MusicUtil = require "musicutil"

function init()
  startTime = util.time()
  lfo_metro = metro.init()
  lfo_metro.time = 0.01
  lfo_metro.count = -10
  lfo_metro.event = function()
    currentTime = util.time()
    for i = 1,16 do
      lfo[i].counter = ((lfo[i].counter + (1*lfo[i].freq)))%100
      lfo[i].ar = lfo[i].counter*0.64
    end
  end
  lfo_metro:start()
  local arc_redraw_metro = metro.init()
  arc_redraw_metro.event = function()
    arc_redraw()
    redraw()
  end
  arc_redraw_metro:start(1 / framerate)
  print("loaded Sines engine")
  add_params()
  set_voices()
end

function add_params()
  for i = 1, #MusicUtil.SCALES do
    table.insert(scale_names, string.lower(MusicUtil.SCALES[i].name))
  end
  params:add{type = "option", id = "scale_mode", name = "scale mode",
    options = scale_names, default = 5,
  action = function() build_scale() end}
  params:add{type = "number", id = "root_note", name = "root note",
    min = 0, max = 127, default = 60, formatter = function(param) return MusicUtil.note_num_to_name(param:get(), true) end,
  action = function() build_scale() end}
  --set voice vol, fm, env controls
  for i = 1,16 do
    params:add_control("vol" .. i, "voice " .. i .. " volume", controlspec.new(0.0, 1.0, 'lin', 0.01, 0.0))
    params:set_action("vol" .. i, function(x) set_voice(i - 1, x) end)
  end
  for i = 1,16 do
    params:add_control("fm_index" .. i, "fm_index " .. i, controlspec.new(0.1, 100.0, 'lin', 0.1, 3.0))
    params:set_action("fm_index" .. i, function(x) engine.fm_index(i - 1, x) end)
  end
  for i = 1,16 do
    params:add_number("env" .. i, "env " .. i, 1, 16, 1)
    params:set_action("env" .. i, function(x) set_env(i, x) end)
  end
  params:default()
  edit = 0
end

function build_scale()
  notes = MusicUtil.generate_scale_of_length(params:get("root_note"), params:get("scale_mode"), 16)
  local num_to_add = 16 - #notes
  for i = 1, num_to_add do
    table.insert(notes, notes[16 - num_to_add])
  end
  for i = 1,16 do
    --also set notes
    set_freq(i, MusicUtil.note_num_to_freq(notes[i]))
  end
end

function set_voice(voice_num, value)
  engine.vol(voice_num, value)
  --also set the currently edited voice
  edit = voice_num
end

function set_voices()
  for i = 1,16 do
    cents_values[i] = 0
    env_values[i] = "drone"
    fm_index_values[i] = 3.0
    set_freq(i, MusicUtil.note_num_to_freq(notes[i]))
    params:set("fm_index" .. i, 3.0)
    params:set("vol" .. i, 0.0)
    params:set("env" .. i, 1)
  end
end

function set_env(synth_num, env_num)
  -- goofy way to loop through the envs list, but whatever
  for i = 1,17 do
    if envs[i][1] == env_num then
      engine.env_bias(synth_num - 1, envs[i][2])
      engine.amp_atk(synth_num - 1, envs[i][3])
      engine.amp_rel(synth_num - 1, envs[i][4])
    end
  end
  env_edit = env_num
  env_values[synth_num] = env_types[env_edit]  
end

function set_freq(synth_num, value)
  engine.hz(synth_num - 1, value)
  engine.hz_lag(synth_num - 1, 0.005)
end

function set_synth_pan(synth_num, value)
  engine.pan(synth_num - 1, value)
end

--update when a cc change is detected
m = midi.connect()
m.event = function(data)
  redraw()
  local d = midi.to_msg(data)
  if d.type == "cc" then
    --set all the sliders + fm values
    for i = 1,16 do
      sliders[i] = (params:get("vol" .. i))*32-1
      fm_index_values[i] = params:get("fm_index" .. i)
      if sliders[i] > 32 then sliders[i] = 32 end
      if sliders[i] < 0 then sliders[i] = 0 end
    end
    redraw()
  end
end

function set_pan()
  -- pan position on the bus, -1 is left, 1 is right
  if key_2_pressed == 1 and key_3_pressed == 1 then
    toggle = not toggle
    if toggle then
      pan_display = "l/r"
      --set hard l/r pan values
      for i = 1,16 do
        if i % 2 == 0 then
          --even, pan right
          set_synth_pan(i,1)
        elseif i % 2 == 1 then
          --odd, pan left
          set_synth_pan(i,-1)
        end
      end
    end
    if not toggle then
      pan_display = "m"
      for i = 1,16 do
        set_synth_pan(i,0)
      end
    end
  end
end

-- hardware functions

function a.delta(n,delta)
  -- gross, refactor plz, I'm tired of typing the numbers.
  -- this seems like a maths thing. something about a vector of 16
  -- into a 4x4 matrix? Computer, do what I say in English, not Lua
  local voice = 1
  if voice_quad == 1 then
    voice = n
  elseif voice_quad == 2 then
    voice = n + 4
  elseif voice_quad == 3 then
    voice = n + 8
  elseif voice_quad == 4 then
    voice = n + 12
  end
  if lfo[voice].interpolater == 1 then
    lfo[voice].freq = lfo[voice].freq + delta/interp_divisor
    newSpeed = true
    -- we need polarity of the LED ring
    if lfo[voice].freq > 0 then
      -- seventeen is a special arc envelope
      envs[17][3] = 0.001
      -- we need seconds per cycle for the envelope
      envs[17][4] = 1 / lfo[voice].freq
    else
      envs[17][4] = 0.001
      envs[17][3] = math.abs(1 / lfo[voice].freq)
    end
    set_env(voice, 17)
  end
  lfo[voice].interpolater = 1
  lastTouched = n
  arcDirty = true
end

function arc_redraw()
  local brightness = 12
  a:all(0)
  -- there are 4 encoders and 16 lfos. Using the same voice_quad logic
  -- as the encoder delta, determine what quadrant we are in before setting
  -- the value of seg
  for n = 1,4 do
    if voice_quad == 1 then
      seg = lfo[n].ar/64
    elseif voice_quad == 2 then
      seg = lfo[n + 4].ar/64
    elseif voice_quad == 3 then
      seg = lfo[n + 8].ar/64
    elseif voice_quad == 4 then
      seg = lfo[n + 12].ar/64
    end
    a:segment(n, seg*tau, tau*seg+0.2, brightness)
  end
  a:refresh()
end

function enc(n, delta)
  if n == 1 then
    params:delta('output_level', delta)
  elseif n == 2 then
    if key_2_pressed == 0 and key_3_pressed == 0 then
      --navigate up/down the list of sliders
      --accum wraps around 0-15
      accum = (accum + delta) % 16
      --edit is the slider number
      edit = accum
      -- this would be better with maths
      if edit < 4 then
        voice_quad = 1
      elseif edit > 3 and edit < 8 then
        voice_quad = 2
      elseif edit > 7 and edit < 12 then
        voice_quad = 3
      elseif edit > 11 then
        voice_quad = 4
      end
    elseif key_2_pressed == 0 and key_3_pressed == 1 then
      env_accum = (env_accum + delta) % 16
      --env_edit is the env_values selector
      env_edit = env_accum
      --set the env
      set_env(edit+1, env_edit+1)
    elseif key_2_pressed == 1 and key_3_pressed == 0 then
      -- increment the note value with delta
      notes[edit+1] = notes[edit+1] + util.clamp(delta, -1, 1)
      set_freq(edit+1, MusicUtil.note_num_to_freq(notes[edit+1]))
      cents_values[edit+1] = 0
      cents_increment = 0
      freq_increment = 0
    end
  elseif n == 3 then
    if key_3_pressed == 0 and key_2_pressed == 0 then
      --set the slider value
      sliders[edit+1] = sliders[edit+1] + delta
      amp_value = util.clamp(((sliders[edit+1] + delta) * .026), 0.0, 1.0)
      params:set("vol" .. edit+1, amp_value)
      if sliders[edit+1] > 32 then sliders[edit+1] = 32 end
      if sliders[edit+1] < 0 then sliders[edit+1] = 0 end
    elseif key_2_pressed == 1 and key_3_pressed == 0 then
      -- increment the current note freq
      freq_increment = freq_increment + util.clamp(delta, -1, 1) * 0.1
      -- calculate increase in cents
      -- https://music.stackexchange.com/questions/17566/how-to-calculate-the-difference-in-cents-between-a-note-and-an-arbitrary-frequen
      cents_increment = 3986*math.log((MusicUtil.note_num_to_freq(notes[edit+1]) + freq_increment)/(MusicUtil.note_num_to_freq(notes[edit+1])))
      -- round down to 2 dec points
      cents_increment = math.floor((cents_increment) * 10 / 10)
      cents_values[edit+1] = cents_increment
      set_freq(edit+1, MusicUtil.note_num_to_freq(notes[edit+1]) + freq_increment)
    elseif key_2_pressed == 0 and key_3_pressed == 1 then
      -- set the index_slider value
      params:set("fm_index" .. edit+1, params:get("fm_index" .. edit+1) + (delta) * 0.1)
      fm_index_values[edit+1] = params:get("fm_index" .. edit+1)
    end
  end
  redraw()
end

function key(n, z)
  --use these keypress variables to add extra functionality on key hold
  if n == 2 and z == 1 then
    key_2_pressed = 1
  elseif n == 2 and z == 0 then
    key_2_pressed = 0
  elseif n == 3 and z == 1 then
    key_3_pressed = 1
  elseif n == 3 and z == 0 then
    key_3_pressed = 0
  end
  set_pan()
  redraw()
end

function redraw()
  screen.aa(1)
  screen.line_width(2.0)
  screen.clear()

  for i=0, 15 do
    if i == edit then
      screen.level(15)
    else
      screen.level(2)
    end
    screen.move(32+i*4, 54)
    screen.line(32+i*4, 52-sliders[i+1])
    screen.stroke()
  end

  screen.level(10)
  screen.line(32+step*4, 58)
  screen.stroke()
  --display current values
  screen.move(0,5)
  screen.level(2)
  screen.text("Note: ")
  screen.level(15)
  screen.text(MusicUtil.note_num_to_name(notes[edit+1],true) .. " ")
  screen.level(2)
  screen.text("Detune: ")
  screen.level(15)
  screen.text(cents_values[edit+1] .. " cents")
  screen.move(0,12)
  screen.level(2)
  screen.text("Env: ")
  screen.level(15)
  screen.text(env_values[edit+1])
  screen.level(2)
  screen.text(" FM Ind: ")
  screen.level(15)
  screen.text(fm_index_values[edit+1])
  screen.move(0,19)
  screen.level(2)
  screen.text("Pan: ")
  screen.level(15)
  screen.text(pan_display)
  screen.level(2)
  screen.text(" Vol: ")
  screen.level(15)
  screen.text(math.floor((params:get('output_level')) * 10 / 10) .. " dB")
  screen.update()
end
