--- ~ Sines v0.1 by @oootini ~
-- E1 - overall volume
-- E2 - select sine 1-16
-- E3 - set sine amplitude
-- K1 - exit to norns main menu
-- K2 + E2 - change note
-- K2 + E3 - detune
-- K3 + E2 - change octave
-- K3 + E3 -  change FM index
-- K2 + K3 - set voice panning

local sliders = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}
local freq_values = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}
local cents_values = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}
local index_values = {3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3}
local octave_values = {"0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0"}
local current_index = 3
local current_note = 0
local current_octave = "0"
local edit = 1
local accum = 1
local cc_index = 3
local cc_accum = 1
local step = 0
local freq_increment = 0
local current_freq = 0
local current_cents = 0
local scale_names = {}
local unison_opts = {"yes", "no"}
local notes = {}
local key_2_pressed = 0
local key_3_pressed = 0
local toggle = false
local pan_display = "m"

engine.name = "Sines"
MusicUtil = require "musicutil"

function init()
  print("loaded Sines engine")
  engine.mul1(0)
  engine.mul2(0)
  engine.mul3(0)
  engine.mul4(0)
  engine.mul5(0)
  engine.mul6(0)
  engine.mul7(0)
  engine.mul8(0)
  engine.mul9(0)
  engine.mul10(0)
  engine.mul11(0)
  engine.mul12(0)
  engine.mul13(0)
  engine.mul14(0)
  engine.mul15(0)
  engine.mul16(0)
  add_params()
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
  params:default()
end

function build_scale()
  notes = MusicUtil.generate_scale_of_length(params:get("root_note"), params:get("scale_mode"), 16)
  local num_to_add = 16 - #notes
  for i = 1, num_to_add do
    table.insert(notes, notes[16 - num_to_add])
  end
  --set notes
  for i = 1,16 do
    index_values[i] = 3
    cents_values[i] = 0
    set_freq(i, MusicUtil.note_num_to_freq(notes[i]))
    set_vol(i, 0)
    set_fm_index(i, index_values[i])
    octave_values[i] = "0" 
    current_octave = "0"
  end  
end

function set_fm_index(synth_num, value)
  --set index between 0-24 for pleasant sounds
  if synth_num == 1 then engine.index1(value)
  elseif synth_num == 2 then engine.index2(value)
  elseif synth_num == 3 then engine.index3(value)
  elseif synth_num == 4 then engine.index4(value)
  elseif synth_num == 5 then engine.index5(value)
  elseif synth_num == 6 then engine.index6(value)
  elseif synth_num == 7 then engine.index7(value)
  elseif synth_num == 8 then engine.index8(value)
  elseif synth_num == 9 then engine.index9(value)
  elseif synth_num == 10 then engine.index10(value)
  elseif synth_num == 11 then engine.index11(value)
  elseif synth_num == 12 then engine.index12(value)
  elseif synth_num == 13 then engine.index13(value)
  elseif synth_num == 14 then engine.index14(value)
  elseif synth_num == 15 then engine.index15(value)
  elseif synth_num == 16 then engine.index16(value)
  end
end

function set_freq(synth_num, value)
  --set freq
  if synth_num == 1 then engine.freq1(value)
  elseif synth_num == 2 then engine.freq2(value)
  elseif synth_num == 3 then engine.freq3(value)
  elseif synth_num == 4 then engine.freq4(value)
  elseif synth_num == 5 then engine.freq5(value)
  elseif synth_num == 6 then engine.freq6(value)
  elseif synth_num == 7 then engine.freq7(value)
  elseif synth_num == 8 then engine.freq8(value)
  elseif synth_num == 9 then engine.freq9(value)
  elseif synth_num == 10 then engine.freq10(value)
  elseif synth_num == 11 then engine.freq11(value)
  elseif synth_num == 12 then engine.freq12(value)
  elseif synth_num == 13 then engine.freq13(value)
  elseif synth_num == 14 then engine.freq14(value)
  elseif synth_num == 15 then engine.freq15(value)
  elseif synth_num == 16 then engine.freq16(value)
  end
end

function set_synth_pan(synth_num, value)
  --set pan
  if synth_num == 1 then engine.pan1(value)
  elseif synth_num == 2 then engine.pan2(value)
  elseif synth_num == 3 then engine.pan3(value)
  elseif synth_num == 4 then engine.pan4(value)
  elseif synth_num == 5 then engine.pan5(value)
  elseif synth_num == 6 then engine.pan6(value)
  elseif synth_num == 7 then engine.pan7(value)
  elseif synth_num == 8 then engine.pan8(value)
  elseif synth_num == 9 then engine.pan9(value)
  elseif synth_num == 10 then engine.pan10(value)
  elseif synth_num == 11 then engine.pan11(value)
  elseif synth_num == 12 then engine.pan12(value)
  elseif synth_num == 13 then engine.pan13(value)
  elseif synth_num == 14 then engine.pan14(value)
  elseif synth_num == 15 then engine.pan15(value)
  elseif synth_num == 16 then engine.pan16(value)
  end
end

function set_vol(synth_num, value)
  if synth_num == 1 then engine.mul1(value)
  elseif synth_num == 2 then engine.mul2(value)
  elseif synth_num == 3 then engine.mul3(value)
  elseif synth_num == 4 then engine.mul4(value)
  elseif synth_num == 5 then engine.mul5(value)
  elseif synth_num == 6 then engine.mul6(value)
  elseif synth_num == 7 then engine.mul7(value)
  elseif synth_num == 8 then engine.mul8(value)
  elseif synth_num == 9 then engine.mul9(value)
  elseif synth_num == 10 then engine.mul10(value)
  elseif synth_num == 11 then engine.mul11(value)
  elseif synth_num == 12 then engine.mul12(value)
  elseif synth_num == 13 then engine.mul13(value)
  elseif synth_num == 14 then engine.mul14(value)
  elseif synth_num == 15 then engine.mul15(value)
  elseif synth_num == 16 then engine.mul16(value)
  end
end

function set_vol_from_cc(cc_num, value)
  if cc_num == 32 then engine.mul1(value)
  elseif cc_num == 33 then engine.mul2(value)
  elseif cc_num == 34 then engine.mul3(value)
  elseif cc_num == 35 then engine.mul4(value)
  elseif cc_num == 36 then engine.mul5(value)
  elseif cc_num == 37 then engine.mul6(value)
  elseif cc_num == 38 then engine.mul7(value)
  elseif cc_num == 39 then engine.mul8(value)
  elseif cc_num == 40 then engine.mul9(value)
  elseif cc_num == 41 then engine.mul10(value)
  elseif cc_num == 42 then engine.mul11(value)
  elseif cc_num == 43 then engine.mul12(value)
  elseif cc_num == 44 then engine.mul13(value)
  elseif cc_num == 45 then engine.mul14(value)
  elseif cc_num == 46 then engine.mul15(value)
  elseif cc_num == 47 then engine.mul16(value)
  end
end

function map_cc_to_slider(cc_num)
  if cc_num == 32 then cc_num = 0
  elseif cc_num == 33 then cc_num = 1
  elseif cc_num == 34 then cc_num = 2
  elseif cc_num == 35 then cc_num = 3
  elseif cc_num == 36 then cc_num = 4
  elseif cc_num == 37 then cc_num = 5
  elseif cc_num == 38 then cc_num = 6
  elseif cc_num == 39 then cc_num = 7
  elseif cc_num == 40 then cc_num = 8
  elseif cc_num == 41 then cc_num = 9
  elseif cc_num == 42 then cc_num = 10
  elseif cc_num == 43 then cc_num = 11
  elseif cc_num == 44 then cc_num = 12
  elseif cc_num == 45 then cc_num = 13
  elseif cc_num == 46 then cc_num = 14
  elseif cc_num == 47 then cc_num = 15
  end
  return cc_num
end

m = midi.connect()
m.event = function(data)
  local d = midi.to_msg(data)
  if d.type == "cc" then
    --clamp the cc value to acceptable range for engine sinOsc
    cc_val = util.clamp((d.val/127), 0.0, 1.0)
    set_vol_from_cc(d.cc, cc_val)
    --edit is the current slider
    edit = map_cc_to_slider(d.cc)
    current_index = index_values[edit+1]
    current_octave = octave_values[edit+1]
    current_note = notes[edit+1]
    --clamp cc_val value to set gui slider
    sliders[edit+1] = cc_val*32
    if sliders[edit+1] > 32 then sliders[edit+1] = 32 end
    if sliders[edit+1] < 0 then sliders[edit+1] = 0 end
  end
  redraw()
end


--not used
function keys_down()
  if key_2_pressed == 1 and key_3_pressed == 1 then
    print ("Reset everything to default...")
    --set notes
    for i = 1,16 do
      set_freq(i, MusicUtil.note_num_to_freq(notes[i]))
      mul(i, 0)
      set_fm_index(i, 3)
      sliders = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}
      freq_values = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}
      cents_values = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}
      index_values = {3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3}
      octave_values = {"0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0"}
      current_index = 3
      current_note = 0
      current_cents = 0
      current_octave = "0"
    end
  end
end

--not used
function set_unison()
  if key_2_pressed == 1 and key_3_pressed == 1 then
    local root = params:get("root_note")
    print ("Setting unison with root note...")
    --set notes
    for i = 1,16 do
      notes[i] = root
      sliders[i] = 0
      freq_values[i] = MusicUtil.note_num_to_freq(notes[i])
      --set random index and detune values
      index_values[i] = math.floor((util.clamp(math.random(), 0, 3)) * 10)
      cents_values[i] = math.floor((util.clamp(math.random(), 0, 20) * 100) * 10 / 10)
      current_index = index_values[i]
      octave_values[i] = "0"
      current_note = notes[i]
      current_cents = cents_values[i]
      current_octave = "0"
      set_freq(i, freq_values[i])
      mul(i, 0)
      set_fm_index(i, index_values[i])
    end
  end
end

-- pan position on the bus, -1 is left, 1 is right
function set_pan()
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

function enc(n, delta)
  if n == 1 then
    params:delta('output_level', delta)

    --how can i return this value to the gui?
  elseif n == 2 then
    if key_2_pressed == 0 and key_3_pressed == 0 then 
      --accum wraps around 0-15
      accum = (accum + delta) % 16
      --edit is the slider number
      edit = accum
      --set current_index and current_octave to be displayed
      current_index = index_values[edit+1]
      current_octave = octave_values[edit+1]
      current_note = notes[edit+1]
      current_cents = cents_values[edit+1]
    elseif key_2_pressed == 0 and key_3_pressed == 1 then
      -- set the freq_slider value
      freq_values[edit+1] = freq_values[edit+1] + delta
      if freq_values[edit+1] > 2 then freq_values[edit+1] = 2 end
      if freq_values[edit+1] < -2 then freq_values[edit+1] = -2 end
      --set octave based on freq_slider
      if freq_values[edit+1] == -2 then
        set_freq(edit+1, MusicUtil.note_num_to_freq(notes[edit+1]-24))
        octave_values[edit+1] = "-2" 
        current_octave = "-2"
      elseif freq_values[edit+1] == -1 then
        set_freq(edit+1, MusicUtil.note_num_to_freq(notes[edit+1]-12))
        octave_values[edit+1] = "-1" 
        current_octave = "-1"
      elseif freq_values[edit+1] == 0 then
        set_freq(edit+1, MusicUtil.note_num_to_freq(notes[edit+1]))
        octave_values[edit+1] = "0"
        current_octave = "0"
      elseif freq_values[edit+1] == 1 then
        set_freq(edit+1, MusicUtil.note_num_to_freq(notes[edit+1]+12))
        octave_values[edit+1] = "+1"
        current_octave = "+1"
      elseif freq_values[edit+1] == 2 then
        set_freq(edit+1, MusicUtil.note_num_to_freq(notes[edit+1]+24))
        octave_values[edit+1] = "+2"
        current_octave = "+2"
      end
    elseif key_2_pressed == 1 and key_3_pressed == 0 then
      -- increment the note value with delta 
      notes[edit+1] = notes[edit+1] + util.clamp(delta, -1, 1)
      current_note = notes[edit+1]
      set_freq(edit+1, MusicUtil.note_num_to_freq(notes[edit+1]))
    end
  elseif n == 3 then
    if key_3_pressed == 0 and key_2_pressed == 0 then
      --set the slider value in the gui
      sliders[edit+1] = sliders[edit+1] + delta
      amp_value = util.clamp(((sliders[edit+1] + delta) * .026), 0.0, 1.0)
      mul(edit+1, amp_value)
      if sliders[edit+1] > 32 then sliders[edit+1] = 32 end
      if sliders[edit+1] < 0 then sliders[edit+1] = 0 end
    elseif key_2_pressed == 1 and key_3_pressed == 0 then
      -- increment the current note freq
      freq_increment = freq_increment + util.clamp(delta, -1, 1) * 0.1
      -- calculate increase in cents 
      -- https://music.stackexchange.com/questions/17566/how-to-calculate-the-difference-in-cents-between-a-note-and-an-arbitrary-frequen
      local cents_increment = 3986*math.log((MusicUtil.note_num_to_freq(notes[edit+1]) + freq_increment)/(MusicUtil.note_num_to_freq(notes[edit+1]))) 
      -- round down to 2 dec points
      cents_increment = math.floor((cents_increment) * 10 / 10)
      cents_values[edit+1] = cents_increment
      current_cents = cents_increment
      current_note = notes[edit+1]
      current_freq = (MusicUtil.note_num_to_freq(notes[edit+1]) + freq_increment)
      set_freq(edit+1, MusicUtil.note_num_to_freq(notes[edit+1]) + freq_increment)
    elseif key_2_pressed == 0 and key_3_pressed == 1 then
      -- set the index_slider value
      index_values[edit+1] = index_values[edit+1] + delta
      if index_values[edit+1] > 500 then index_values[edit+1] = 500 end
      if index_values[edit+1] < 0 then index_values[edit+1] = 0 end
      set_fm_index(edit+1, index_values[edit+1])
      current_index = index_values[edit+1]
    end
  end
  redraw()
  set_pan()
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
  redraw()
  set_pan()
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
  screen.level(16)
  screen.text(MusicUtil.note_num_to_name(current_note,true) .. " ")
  screen.level(2)
  screen.text("Detune: ")
  screen.level(16)
  screen.text(current_cents .. " cents")
  screen.move(0,12)
  screen.level(2)
  screen.text("Octave: ")
  screen.level(16)
  screen.text(current_octave)
  screen.level(2)
  screen.text(" FM Index: ")
  screen.level(16)
  screen.text(current_index)
  screen.move(0,19)
  screen.level(2)
  screen.text("Pan: ")
  screen.level(16)
  screen.text(pan_display)
  screen.level(2)
  screen.text(" Env: ")
  screen.level(16)
  screen.text("loop")
  screen.level(2)
  screen.text(" Vol: ")
  screen.level(16)
  screen.text(math.floor((params:get('output_level')) * 10 / 10) .. " dB")
  screen.update()
end
