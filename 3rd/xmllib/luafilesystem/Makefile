# $Id: Makefile,v 1.36 2009/09/21 17:02:44 mascarenhas Exp $

T= lfs

CONFIG= ./config

include $(CONFIG)

SRCS= src/$T.c
OBJS= src/$T.o

lib: ../lfs.so

../lfs.so: $(OBJS)
	MACOSX_DEPLOYMENT_TARGET="10.3"; export MACOSX_DEPLOYMENT_TARGET; $(CC) $(LIB_OPTION) -o ../lfs.so $(OBJS)

test: lib
	LUA_CPATH=../?.so lua tests/test.lua

install:
	mkdir -p $(LUA_LIBDIR)
	cp ../lfs.so $(LUA_LIBDIR)

clean:
	rm -f ../lfs.so $(OBJS)
