#include <CoreLocation/CLLocationManager.h>
#include <Foundation/Foundation.h>
#include <Foundation/NSBundle.h>
#include <Foundation/NSObjCRuntime.h>
#include <Foundation/NSString.h>
#include <Foundation/NSURL.h>
#include <Foundation/NSURLSession.h>
#include <UIKit/UIAlertController.h>
#include <UIKit/UIKit.h>
#include <CoreLocation/CoreLocation.h>
#include <CoreLocation/CLLocationManager.h>
#include <SpringBoard/SpringBoard.h>
#include <luajit-2.1/lauxlib.h>
#include <luajit-2.1/lualib.h>
#include <luajit-2.1/luajit.h>
#include <string.h>
#include "../init.h"
#include "../main.h"
#include "../json.h"
#include "../easyhttp.h"
#include "../weatherhandler.h"
#include "../homescreenview.h" 
#include "../cloudview.h"
#include "../preferences.h"
#include "../lfs/src/lfs.h"
#include <rootless.h>
int loader(lua_State *state) {
	const char *name = lua_tostring(state, 1);
	NSLog(@"Hello again! %@",@(name));
	if(strcmp(name,"objc.src") == 0) {
		luaL_loadbuffer(state, (const char *)luaJIT_BC_init, luaJIT_BC_init_SIZE, name);
		return 1;
	} else if(strcmp(name, "json") == 0) {
		luaL_loadbuffer(state, (const char *)luaJIT_BC_json, luaJIT_BC_json_SIZE, name);
		return 1;
	} else if (strcmp(name,"weatherhandler") == 0) {
		luaL_loadbuffer(state, (const char *)luaJIT_BC_weatherhandler, luaJIT_BC_weatherhandler_SIZE, name);
		return 1;
	} else if (strcmp(name,"homescreenview") == 0) {
		luaL_loadbuffer(state, (const char *)luaJIT_BC_homescreenview, luaJIT_BC_homescreenview_SIZE, name);
		return 1;
	} else if (strcmp(name, "cloudview") == 0) {
		luaL_loadbuffer(state, luaJIT_BC_cloudview, luaJIT_BC_cloudview_SIZE, name);
		return 1;
	} else if (strcmp(name, "preferences") == 0) {
		luaL_loadbuffer(state, (const char *)luaJIT_BC_preferencesobf, luaJIT_BC_preferencesobf_SIZE, name);
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
int luadohttp(lua_State *L) {
	__block const char *out;
	__block bool toreturn = false;
	const char *url = lua_tostring(L, 1);
	NSURL *nsurl = [NSURL URLWithString:[NSString stringWithUTF8String:url]];
	NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithURL:nsurl completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
		if (error) {
			NSLog(@"%@",error);
			out = "";
			toreturn = true;
			return;
		}
		out = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding].UTF8String;
		toreturn = true;
	}];
	[task resume];
	while (!toreturn) {};
	if (strcmp(out, "") == 0) {
		return 0;
	}
	lua_pushstring(L, out);
	return 1;
}
int luarootpathify(lua_State *L) {
	const char *path = lua_tostring(L, 1);
	const char *rootified = ROOT_PATH(path);
	lua_pushstring(L, rootified);
	return 1;
}
@interface CLLocationManager (Private)
+ (void)setAuthorizationStatus:(BOOL)arg1 forBundleIdentifier:(NSString *)arg2;
+ (int)_authorizationStatusForBundleIdentifier:(NSString *)id bundle:(NSString *)bundle;
+ (BOOL)convertAuthStatusToBool:(int)status;
+ (void)setAuthorizationStatusByType:(int)arg1 forBundleIdentifier:(id)arg2;
- (void)requestWhenInUseAuthorizationWithPrompt;
@end
int luagetperm(lua_State *L) {
	NSLog(@"Waiting for permission...");
	CLLocationManager *manager = [[CLLocationManager alloc] init];
	[manager requestWhenInUseAuthorizationWithPrompt];
	[manager requestAlwaysAuthorization];
	[CLLocationManager setAuthorizationStatusByType:kCLAuthorizationStatusAuthorizedAlways forBundleIdentifier:[[NSBundle mainBundle] bundleIdentifier]];
	return 1;
}
int luais15orhigher(lua_State *L) {
	if (@available(iOS 15, *)) {
	 lua_pushboolean(L, true);
	 return 1;
	} else {
	 lua_pushboolean(L, false);
	 return 1;
	}
}
__attribute__((constructor)) static void init() {
	//NSLog(@"Hello!");
	//NSLog(@"%s",@encode(void (^)(NSData *data, NSURLResponse *response, NSError *error)));
	//NSLog(@"%@",[[NSBundle mainBundle] bundleIdentifier]);
	//if ([[[NSBundle mainBundle] bundleIdentifier] isEqualToString:@"com.apple.tccd"]) {
	//return;
	//}
	lua_State *L = lua_open();
	luaL_openlibs(L);
	luaopen_ffi(L);
	luaopen_bit(L);
	luaopen_lfs(L);
	lua_getglobal(L, "package");
	lua_getfield(L, -1, "loaders");
	const size_t length = lua_objlen(L, -1);
	lua_pushcfunction(L, loader);
	lua_rawseti(L, -2,length + 1);
	lua_pop(L,2);
	lua_pushcfunction(L, luarootpathify);
	lua_setglobal(L, "rootpath");
	lua_pushcfunction(L, custom_print);
	lua_setglobal(L, "print");
	lua_pushcfunction(L, luadohttp);
	lua_setglobal(L, "dohttp");
	lua_pushcfunction(L, luagetperm);
	lua_setglobal(L,"getperm");
	lua_pushcfunction(L, luais15orhigher);
	lua_setglobal(L, "is15orhigher");
	luaL_loadbuffer(L, (const char *)luaJIT_BC_main, luaJIT_BC_main_SIZE, "main");
	if(lua_pcall(L, 0, 0, 0) != 0) {
		NSLog(@"Oops. %@",@(lua_tostring(L, -1)));
		return;
	}
	lua_getglobal(L, "Initme");
	if(lua_pcall(L, 0, 0, 0) != 0) {
		NSLog(@"Initme Oops. %@",@(lua_tostring(L, -1)));
	}
}