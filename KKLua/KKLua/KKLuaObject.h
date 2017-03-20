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
    
-(int) KKLuaObjectLenWithL:(lua_State *)L;

-(void) KKLuaObjectValue:(id) value forKey:(NSString *) key;

@end

@interface KKLuaRef : NSObject

@property(nonatomic,assign,readonly) lua_State * L;

-(instancetype) initWithL:(lua_State *) L;

-(void) unref;

-(void) get;

@end

@interface KKLuaWeakObject : NSObject

@property(nonatomic,weak,readonly) id object;

-(instancetype) initWithObject:(id) object;

@end
