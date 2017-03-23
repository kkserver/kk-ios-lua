//
//  KKLuaState.h
//  KKLua
//
//  Created by zhanghailong on 2016/11/26.
//  Copyright © 2016年 kkserver.cn. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <KKLua/lua.h>

@interface KKLuaState : NSObject

@property(nonatomic,readonly,assign) lua_State * L;

-(void) gc;

-(void) openlibs;

-(void) openlibs:(NSString *) path;

-(void) openlibFile:(NSString *) luaFile;

-(void) callFile:(NSString *) luaFile objects:(NSArray *) objects;

@end
