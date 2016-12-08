--[[------------------------------------------------------
  # {{type}} Foo

  TODO: DESCRIPTION

  ## Usage example

    local {{type}} = require '{{type}}'

  
--]]------------------------------------------------------
local lub     = require 'lub'
local {{type}}     = require '{{type}}'
local lib     = lub.class '{{type}}.Foo'

-- # Class functions

-- Create a new client connected to a given `host` and `port`.
function lib.new()
  local self = {
  }
  setmetatable(self, lib)
  return self
end

-- # Methods


return lib

