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

@end
