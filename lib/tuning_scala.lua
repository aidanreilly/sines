-- taken from https://github.com/catfact/z_tuning thank you zebra
-- shamelessly ripped from @ngwese

local Scala = {}

-- parse a non-comment scala line, returning a pitch ratio
Scala.parse_ratio = function(str)
   -- try full ratio syntax
   local n, d = string.match(str, "([%d.-]+)%s*/%s*([%d.-]+)")
   if n ~= nil then
      return tonumber(n) / tonumber(d)
   end

   -- try individual number
   local p = string.match(str, "([%d-.]+)")
   if p ~= nil then
      -- determine if in cents or ratio
      if string.find(p, "[.]") ~= nil then
         return 2 ^ (tonumber(p) / 1200)
      else
         return tonumber(p)
      end
   end

   -- not recognized
   return nil
end

local is_comment = function(line)
   return string.find(line, "^!")
end

-- parse a .scl file, return ratios
Scala.load_file = function(path)
   local ratios = {}

   local lines = io.lines(path)
   local l = nil

   -- skip initial comments
   repeat
      l = lines()
   until not is_comment(l)

   -- header
   local description = l
   local pitch_count = tonumber(lines())

   -- intermediate comments
   repeat
      l = lines()
   until not is_comment(l)

   -- pitches
   repeat
      local r = Scala.parse_ratio(l)
      if r ~= nil then
         table.insert(ratios, r)
      end
      l = lines()
   until l == nil
   return ratios
end

return Scala