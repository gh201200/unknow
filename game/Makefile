
THIRD_LIB_ROOT ?= ../3rd/

SKYNET_ROOT ?= $(THIRD_LIB_ROOT)skynet/
include $(SKYNET_ROOT)platform.mk

CJSON_ROOT ?= $(THIRD_LIB_ROOT)lua-cjson-master
CJSON_INC ?= ../skynet/3rd/lua

RVO_ROOT ?= lualib-src/src
RVO_INC ?= ../skynet/3rd/lua

SKYNET_BUILD_PATH ?= .
LUA_CLIB_PATH ?= luaclib
MCSERVICE_PATH ?= cservice

CFLAGS = -g -O2 -Wall -I$(LUA_INC) $(MYCFLAGS) 

# lua

LUA_STATICLIB := $(SKYNET_ROOT)3rd/lua/liblua.a
LUA_LIB ?= $(LUA_STATICLIB)
LUA_INC ?= $(SKYNET_ROOT)3rd/lua

# skynet

MCSERVICE = syslog
LUA_CLIB = cjson uuid pathfinding librvo

all : \
  $(foreach v, $(MCSERVICE), $(MCSERVICE_PATH)/$(v).so) \
  $(foreach v, $(LUA_CLIB), $(LUA_CLIB_PATH)/$(v).so)

$(MCSERVICE_PATH) :
	mkdir $(MCSERVICE_PATH)

$(LUA_CLIB_PATH) :
	mkdir $(LUA_CLIB_PATH)

$(MCSERVICE_PATH)/syslog.so : service-src/service_syslog.c | $(MCSERVICE_PATH)
	$(CC) $(CFLAGS) $(SHARED) $< -o $@ -I$(SKYNET_ROOT)skynet-src


$(LUA_CLIB_PATH)/uuid.so : lualib-src/lua-uuid.c | $(LUA_CLIB_PATH)
	$(CC) $(CFLAGS) $(SHARED) $^ -o $@ 

$(LUA_CLIB_PATH)/cjson.so : | $(LUA_CLIB_PATH)
	cd $(CJSON_ROOT) && $(MAKE) LUA_INCLUDE_DIR=$(CJSON_INC) CC=$(CC) CJSON_LDFLAGS="$(SHARED)" && cd - && cp $(CJSON_ROOT)/cjson.so $@

$(LUA_CLIB_PATH)/librvo.so : | $(LUA_CLIB_PATH)
	cd $(RVO_ROOT) && $(MAKE) LUA_INCLUDE_DIR=$(RVO_INC) CJSON_LDFLAGS="$(SHARED)" && cd - && cp $(RVO_ROOT)/librvo.so $@



$(LUA_CLIB_PATH)/pathfinding.so : lualib-src/pathfinding.c | $(LUA_CLIB_PATH)
	$(CC) $(CFLAGS) $(SHARED) $^  -o $@ 

clean :
	rm -f $(MCSERVICE_PATH)/*.so $(LUA_CLIB_PATH)/*.so

cleanall: clean

