--[[------------------------------------------------------

  # Foo usage example

  In this tutorial, we show how to use {{type}}.Foo
  
  We use lens.FileWatch to enable live coding for this script.

  ## Download source

  [LiveFoo.lua](example/{{type}}/LiveFoo.lua)

--]]------------------------------------------------------
-- doc:lit

-- # Preamble
--
-- Require lens and {{type}} libraries.
local lens = require 'lens'
local {{type}}  = require '{{type}}'

-- Start scheduler and setup script reload hook with `lens.FileWatch`. Starting
-- the scheduler at the top of the script and using file reloading is a nice
-- trick that ensures all the code after `lens.run` is only executed within the
-- scope of the scheduler.
lens.run(function() lens.FileWatch() end)


--[[
  ## Download source

  [LiveFoo.lua](example/{{type}}/LiveFoo.lua)
--]]

