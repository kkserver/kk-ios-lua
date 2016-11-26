//
//  KKLuaObject.h
//  KKLua
//
//  Created by zhanghailong on 2016/11/26.
//  Copyright © 2016年 kkserver.cn. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <KKLua/lua.h>

void lua_pushValue(lua_State * L, id value);

void lua_pushObject(lua_State * L, id object);

id lua_toObject(lua_State * L, int idx);

id lua_toValue(lua_State * L, int idx);

BOOL lua_isObject(lua_State * L, int idx);

@interface NSObject (KKLuaObject)

-(int) KKLuaObjectGet:(NSString *) key L:(lua_State *)L;

-(int) KKLuaObjectSet:(NSString *) key L:(lua_State *)L;

-(id) KKLuaObjectValueForKey:(NSString *) key;

-(void) KKLuaObjectValue:(id) value forKey:(NSString *) key;

@end
