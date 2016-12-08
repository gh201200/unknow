--[[------------------------------------------------------

  # {{type}} test

--]]------------------------------------------------------
local lub    = require 'lub'
local lut    = require 'lut'

local {{type}}    = require  '{{type}}'
local should = lut.Test '{{type}}'

function should.haveType()
  assertEqual('{{type}}', {{type}}.type)
end

should:test()
