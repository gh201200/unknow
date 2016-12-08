--[[------------------------------------------------------
  # Ease starting new Lua projects

  This class helps setup files and folders for a new lua project with tests,
  pure Lua files and C++ code.

  # Usage example

  Run from the shell:

    # lua
    > lut = require 'lut'
    > lut.Project('blast'):make()

--]]------------------------------------------------------
local lub     = require 'lub'
local lib     = lub.class 'lut.Project'

-- # Class functions

-- Create a new object object named `name`.
function lib.new(name)
  if not name:match('^[a-z]+$') then
    error("The name should only contain ascii letters (a-z).")
  end

  local self = {
    type = name,
  }
  return setmetatable(self, lib)
end

-- # Methods

-- Generate files (creates a new directory with the name of the project).
function lib:make()
  if lub.exist(self.type) then
    error("There is already a file or folder named '"..self.type.."'.")
  end

  local src = lub.path '|assets/project'
  local src_len = string.len(src) + 2
  local trg = self.type

  for file in lub.Dir(lub.path '|assets/project'):glob() do
    local base = string.sub(file, src_len):gsub('type', self.type)
    -- Luarocks renaming file fixing.
    base = string.gsub(base, '_lua%.lua$', '%.lua')
    local target = trg..'/'..base

    local tmp = lub.Template(lub.content(file))
    lub.writeall(target, tmp:run(self))
  end
end

return lib

