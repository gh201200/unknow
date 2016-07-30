local transform = class("transform")

function transform:ctor(pos,dir)
	self.pos = pos
	self.dir = dir
end
function transform:test()
	print("test")
end
return transform
