if not _P then
	print 'inject error'
	return
end

local cmd =_P.lua.CMD
print('match num = ',cmd.MATCH_NUM)
cmd.MATCH_NUM = 1

print 'inject ok'
