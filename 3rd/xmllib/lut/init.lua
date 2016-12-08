--[[--------------------
  # Lubyk utility module <a href="https://travis-ci.org/lubyk/lut"><img src="https://travis-ci.org/lubyk/lut.png" alt="Build Status"></a> 

  Currently, this module contains a documentation generator and
  testing facilities.
  
  <html><a href="https://github.com/lubyk/lut"><img style="position: absolute; top: 0; right: 0; border: 0;" src="https://s3.amazonaws.com/github/ribbons/forkme_right_green_007200.png" alt="Fork me on GitHub"></a></html>

  *MIT license* &copy Gaspard Bucher 2014.

  ## Installation
  
  With [luarocks](http://luarocks.org):

    $ luarocks install lut
  
--]]--------------------
local lub = require 'lub'
local lib = lub.Autoload 'lut'

-- Current version of 'lut' respecting [semantic versioning](http://semver.org).
lib.VERSION = '1.2.1'

-- Library dependencies
lib.DEPENDS = { -- doc
  -- Compatible with Lua 5.1 to 5.3 and LuaJIT
  'lua >= 5.1, < 5.4',
  -- Uses [Lubyk base library](http://doc.lubyk.org/lub.html)
  'lub >= 1.0.3, < 2',
}

-- nodoc
lib.DESCRIPTION = {
  summary = "Utility module for lubyk. Contains a documentation generator and testing facilities.",
  detailed = [[
    lut.Doc: a powerful documentation generator for Lua code with support for
    litterate programming, cross-reference linking, images, latex math, etc.
    
    lut.Test: unit testing framework.

    lut.Builder: helper to generate luarocks and CMake files.

    Read the documentation at http://doc.lubyk.org/lut.html. 
  ]],
  homepage = "http://doc.lubyk.org/lut.html",
  author   = "Gaspard Bucher",
  license  = "MIT",
}

-- nodoc
lib.BUILD = {
  github   = 'lubyk',
  pure_lua = true,
}

return lib
