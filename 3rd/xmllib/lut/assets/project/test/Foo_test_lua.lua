--[[------------------------------------------------------

  {{type}}.Foo test
  --------------


--]]------------------------------------------------------
local {{type}}   = require '{{type}}'
local lut    = require 'lut'
local should = lut.Test '{{type}}.Foo'

should.ignore.deleted = true

function should.doSomething()
  local f = {{type}}.Foo()
  assertEqual(1.0, f:doSomething())
end

should:test()

