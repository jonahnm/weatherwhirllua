#include <Foundation/Foundation.h>
#include <Foundation/NSObjCRuntime.h>
#include <luajit-2.1/lauxlib.h>
#include <luajit-2.1/lualib.h>
#include <luajit-2.1/luajit.h>
#include <string.h>
#include "../init.h"
#include "../main.h"
#include "../json.h"
#include "../weatherhandler.h" 
#include <libroot.h>
int loader(lua_State *state) {
	const char *name = lua_tostring(state, 1);
	NSLog(@"Hello again! %@",@(name));
	if(strcmp(name,"objc.src") == 0) {
		luaL_loadbuffer(state, luaJIT_BC_initobf, luaJIT_BC_initobf_SIZE, name);
		return 1;
	} else if(strcmp(name, "json") == 0) {
		luaL_loadbuffer(state, luaJIT_BC_jsonobf, luaJIT_BC_jsonobf_SIZE, name);
		return 1;
	} else if (strcmp(name,"weatherhandler") == 0) {
		luaL_loadbuffer(state, luaJIT_BC_weatherhandler, luaJIT_BC_weatherhandler_SIZE, name);
		return 1;
	}
	return 0;
}
int custom_print(lua_State *L) {
	int nargs = lua_gettop(L);
	for(int i = 1; i <= nargs; i++) {
		if(lua_isstring(L, i)) {
			const char *str = lua_tostring(L,i);
			NSLog(@"%@",@(str));
		}
	}
	return 0;
}
__attribute__((constructor)) static void init() {
	NSLog(@"Hello!");
	lua_State *L = lua_open();
	luaL_openlibs(L);
	luaopen_ffi(L);
	luaopen_bit(L);
	lua_getglobal(L, "package");
	lua_getfield(L, -1, "loaders");
	const size_t length = lua_objlen(L, -1);
	lua_pushcfunction(L, loader);
	lua_rawseti(L, -2,length + 1);
	lua_pop(L,2);
	lua_pushstring(L, libroot_dyn_get_root_prefix());
	lua_setglobal(L, "root");
	lua_pushcfunction(L, custom_print);
	lua_setglobal(L, "print");
	luaL_loadbuffer(L, luaJIT_BC_mainobf, luaJIT_BC_mainobf_SIZE, "main");
	if(lua_pcall(L, 0, 0, 0) != 0) {
		NSLog(@"Oops. %@",@(lua_tostring(L, -1)));
		return;
	}
	lua_getglobal(L, "Initme");
	if(lua_pcall(L, 0, 0, 0) != 0) {
		NSLog(@"Initme Oops. %@",@(lua_tostring(L, -1)));
	}
}