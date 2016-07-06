local skynet = require "skynet"
local sharedata = require "sharedata"
local testconfig = {
	{
	id = 1,
	name = "name1"},
	{
	id = 2,
	name = "name2"
	},
}
skynet.start(function()
	sharedata.new("testconfig",testconfig)	
end)

