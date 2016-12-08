--[[--------------------
  # {{type}} <a href="https://travis-ci.org/lubyk/{{type}}"><img src="https://travis-ci.org/lubyk/{{type}}.png" alt="Build Status"></a> 

  Summary

  <html><a href="https://github.com/lubyk/{{type}}"><img style="position: absolute; top: 0; right: 0; border: 0;" src="https://s3.amazonaws.com/github/ribbons/forkme_right_green_007200.png" alt="Fork me on GitHub"></a></html>
  
  *MIT license* &copy [author] [year].

  ## Installation
  
  With [luarocks](http://luarocks.org):

    $ luarocks install {{type}}

  Description

  ## Usage example

    local {{type}} = require '{{type}}'

--]]--------------------
local lub  = require 'lub'
local lib  = lub.Autoload '{{type}}'

-- Current version respecting [semantic versioning](http://semver.org).
lib.VERSION = '1.0.0'

lib.DEPENDS = { -- doc
  -- Compatible with Lua 5.1, 5.2 and LuaJIT
  "lua >= 5.1, < 5.3",
  -- Uses [Lubyk base library](http://doc.lubyk.org/lub.html)
  'lub >= 1.0.3, < 2.0',
}

-- nodoc
lib.DESCRIPTION = {
  summary = "",
  detailed = [[
  ]],
  homepage = "http://doc.lubyk.org/{{type}}.html", -- FIXME: set documentation url
  author   = "author", -- FIXME: set author name
  license  = "MIT",
}

-- nodoc
lib.BUILD = {
  github    = 'lubyk', -- FIXME: Set github account name
  sources   = {'src/*.cpp', 'src/bind/*.cpp', 'src/bind/dub/*.cpp'},
  includes  = {'include', 'src/bind'},
  libraries = {'stdc++'},
}

return lib
