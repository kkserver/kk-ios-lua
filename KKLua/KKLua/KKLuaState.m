//
//  KKLuaState.m
//  KKLua
//
//  Created by zhanghailong on 2016/11/26.
//  Copyright © 2016年 kkserver.cn. All rights reserved.
//

#import "KKLuaState.h"
#include <KKLua/lualib.h>
#include <KKLua/lauxlib.h>
#import "KKLuaObject.h"

static int kk_lua_log_function(struct lua_State * L) {
    
    int top = lua_gettop(L);
    
    printf("[KK]");
    
    for(int i=0;i<top;i++) {
        
        printf(" ");
        
        switch (lua_type(L, - top + i)) {
        case LUA_TNUMBER:
            if(lua_isinteger(L, -top + i)) {
                printf("%lld",lua_tointeger(L, -top + i));
            } else {
                printf("%f",lua_tonumber(L, -top + i));
            }
            break;
        case LUA_TBOOLEAN:
            if(lua_isboolean(L, -top + i)) {
                printf("true");
            } else {
                printf("false");
            }
            break;
        case LUA_TSTRING:
            printf("%s",lua_tostring(L, -top + i));
            break;
        case LUA_TUSERDATA:
            {
                id v = lua_toObject(L, -top +i );
                if(v) {
                    printf("%s",[[v description] UTF8String]);
                } else {
                    printf("nil");
                }
            }
            break;
        case LUA_TLIGHTUSERDATA:
            printf("[lightuserdata]");
            break;
        case LUA_TFUNCTION:
            printf("[function]");
            break;
        case LUA_TTABLE:
            printf("[table]");
            break;
        default:
            printf("nil");
            break;
        }
        
    }
    
    printf("\n");
    
    return 0;
}

@implementation KKLuaState

-(id) init {
    if((self = [super init])) {
        _L = luaL_newstate();
    }
    return self;
}

-(void) dealloc {
    lua_close(_L);
}

-(void) openlibs {
    luaL_openlibs(_L);
    
    lua_pushcfunction(_L, kk_lua_log_function);
    lua_setglobal(_L, "log");
    
}

-(void) openlibFile:(NSString *) luaFile {
    
    if(0 != luaL_loadfile(_L, [luaFile UTF8String])) {
        NSLog(@"[KK][KKLua] %s",lua_tostring(_L, -1));
        lua_pop(_L, 1);
    }
    else if(0 != lua_pcall(_L, 0, 0, 0)) {
        NSLog(@"[KK][KKLua] %s",lua_tostring(_L, -1));
        lua_pop(_L, 1);
    }
    
}

-(void) openlibs:(NSString *) path {
    
    NSFileManager * fm = [NSFileManager defaultManager];
    NSDirectoryEnumerator * e = [fm enumeratorAtPath:path];
    NSString * name;
    
    while((name = [e nextObject]) != nil) {
    
        if([name hasPrefix:@"."]) {
            continue;
        }
        
        NSString * fname = [path stringByAppendingPathComponent:name];
        BOOL isDirectory = NO;
    
        if([fm fileExistsAtPath:fname isDirectory:&isDirectory]) {
            
            if(isDirectory) {
                [self openlibs:fname];
            }
            else if([name hasSuffix:@".lua"]) {
                [self openlibFile:fname];
            }
        }
        
    }
}

-(void) callFile:(NSString *) luaFile objects:(NSArray *) objects {
    
    if(0 != luaL_loadfile(_L, [luaFile UTF8String])) {
        NSLog(@"[KK][KKLua] %s",lua_tostring(_L, -1));
        lua_pop(_L, 1);
    }
    else if(0 != lua_pcall(_L, 0, 1, 0)) {
        NSLog(@"[KK][KKLua] %s",lua_tostring(_L, -1));
        lua_pop(_L, 1);
    }
    else {
        if(lua_isfunction(_L, -1)) {
            for(id object in objects) {
                lua_pushValue(_L,object);
            }
            if(0 != lua_pcall(_L, (int) [objects count], 0, 0)) {
                NSLog(@"[KK][KKLua] %s",lua_tostring(_L, -1));
                lua_pop(_L, 1);
            }
        }
        else {
            lua_pop(_L, 1);
        }
    }
}

-(void) gc {
    lua_gc(_L, LUA_GCCOLLECT, 0);
}

@end
