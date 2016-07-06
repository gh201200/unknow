local socketdriver = require "socketdriver"

function send_msg (fd, msg)
	local package = string.pack (">s2", msg)
	socketdriver.send (fd, package)
end

function bit(n)
	return 1<<n
end
