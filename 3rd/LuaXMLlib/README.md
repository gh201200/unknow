
LuaXML-0.0.5 [![MIT license](http://img.shields.io/badge/license-MIT-brightgreen.svg)](http://opensource.org/licenses/MIT)
------------

This is an initial release of LuaXML - a native XML parser for Lua.
The parser was written by Paul Chakravarti and originally available on [LuaUsers](http://lua-users.org/wiki/LuaXml).

This version was adapted to work with Lua 5 and can be used in Lua application, including
interactive Digital Television [Ginga NCL applications](http://gingancl.org.br/en) for the [Brazilian Digital Television System](http://forumsbtvd.org.br) 
(worldwide known as [ISDB-T International or ISDB-Tb](https://en.wikipedia.org/wiki/ISDB-T_International)) and [H.761 ITU-T recommendation](https://www.itu.int/rec/T-REC-H.761).

The code (and documentation) is not complete as yet however it is usable
and this release is indented to avoid potential duplication between efforts
and get early feedback.

The API is relatively stable however there may be some detailed changes.

The distribution comprises:

    - README          : This file
    - xml.lua         : Main XML parser module
    - handler.lua     : Standard XML handlers
    - testxml.lua     : Command line test tool
    - xmlrpclib.lua   : XMLRPC marshaller/unmarshaller (incomplete and now probably superseeded)
    - xmlrpc-lua.cgi  : Test XML-RPC server (CGI)
    - cgi.lua         : CGI module to support XMLRPC server
                      (will probably be packaged separately idc)
    - cgitest.cgi     
    - pretty.lua      : Lua pretty printer [23/02/2001 jcw@equi4.com]

Most of the modules are relatively well documented in the source - the key
ones are 'xml.lua' & 'handler.lua'. The 'testxml.lua' utility is also
useful for testing the modules.

This is all being released a bit earlier than I would have liked due
to all the current XML related activity on lua-l and as a result isnt
quite as well packaged/docuemnted as I would like. I will be working
on fixing this asp.

How to use
----------

An example of how to use the library is available [here](example).

License
-------
This code is freely distributable under the terms of the [MIT license](LICENSE).

Authors
-------
  - Paul Chakravarti
    
    paulc@passtheaardvark.com
	
	28 Nov 2001
	
  -  Manoel Campos da Silva Filho
  
	<http://manoelcampos.com>
	
	<http://about.me/manoelcampos>
		
    10 May 2016
