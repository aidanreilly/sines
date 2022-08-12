local tu = require 'sines/lib/tuning_util'

local note_freq_from_table = function(midi, rats, root_note, root_hz, oct)
   oct = oct or 2
   local degree = midi - root_note
   local n = #rats
   local mf = math.floor(midi)
   if midi == mf then
      local octpow = math.floor(degree / n)
      oct = oct ^ octpow
      local idx = (degree % n) + 1
      local rat = rats[idx]
      return root_hz * rat * oct
   else
      -- interpolate non-integer argument
      local mf = math.floor(midi)
      local f = math.abs(midi - mf)
      local deg1
      if (degree > 0) then
         deg1 = deg + 1
      else
         deg1 = deg - 1
      end
      local a = root_hz * rats[(degree % n) + 1] * (oct ^ (math.floor(degree / n)))
      local b = root_hz * rats[(deg1 % n) + 1] * (oct ^ (math.floor(deg1 / n)))
      return a * math.pow((b / a), f)
   end
end

local interval_ratio_from_table = function(interval, rats, oct)
   oct = oct or 2
   local n = #rats
   local rat = rats[(math.floor(interval) % n) + 1]
   return rat * (oct ^ (math.floor(interval / n)))
end

local bend_table_rats = function(rats)
   local t = {}
   for i,r in ipairs(rats) do
      table.insert(t, (tu.log2(r)*12) - (i-1))
   end
   return t
end

local bend_table_func = function(func)
   local t = {}
   for i=1,12 do
      table.insert(t, func(i) - (i-1))
   end
   return t
end

----------------------------------------------------
-- tuning class

local Tuning = {}
Tuning.__index = Tuning

Tuning.new = function(args)
   local x = setmetatable({}, Tuning)

   -- TODO: fallback value for pseudo-octave should always exceed highest ratio, if ratios are specified
   x.pseudo_octave = args.pseudo_octave or 2

   if args.note_freq and args.interval_ratio then
      x.note_freq = args.note_freq
      x.interval_ratio = args.interval_ratio
      x.bend_table = bend_table_func(args.interval_ratio)
   elseif args.ratios then
      x.note_freq = function(midi, root_note, root_hz)
         return note_freq_from_table(midi, args.ratios, root_note, root_hz, x.pseudo_octave)
      end
      x.interval_ratio = function(interval)
         return interval_ratio_from_table(interval, args.ratios, x.pseudo_octave)
      end
      x.bend_table = bend_table_rats(args.ratios)
   else
      print("error; don't know how to construct tuning with these arguments: ")
      tab.print(args)
      return nil
   end
   --tab.print(x.bend_table)
   return x
end

return Tuning