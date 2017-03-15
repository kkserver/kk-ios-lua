//
//  KKLuaObject.m
//  KKLua
//
//  Created by zhanghailong on 2016/11/26.
//  Copyright © 2016年 kkserver.cn. All rights reserved.
//

#import "KKLuaObject.h"

#include <KKLua/lua.h>
#include <KKLua/lualib.h>
#include <KKLua/lauxlib.h>

static int KKLuaObjectGcFunction(lua_State * L) {
    
    if(lua_isuserdata(L, -1)) {
        
        CFTypeRef *p = (CFTypeRef *) lua_touserdata(L, -1);
        
        if(p != nil) {
            CFBridgingRelease(* p);
            * p = NULL;
        }
    }
    
    return 0;
}

static int KKLuaObjectIndexFunction(lua_State * L) {
    
    int top = lua_gettop(L);
    
    if(top > 1 && lua_isuserdata(L, - top) && lua_isstring(L, - top + 1)) {
        
        CFTypeRef *p = (CFTypeRef *) lua_touserdata(L, - top);
        
        if(p != nil) {
            const char * name = lua_tostring(L, - top + 1);
            return [(__bridge id) * p KKLuaObjectGet:[NSString stringWithCString:name encoding:NSUTF8StringEncoding] L:L];
        }
    }
    
    return 0;
}

static int KKLuaObjectNewIndexFunction(lua_State * L) {
    
    int top = lua_gettop(L);
    
    if(top > 1 && lua_isuserdata(L, - top) && lua_isstring(L, - top + 1)) {
        
        CFTypeRef *p = (CFTypeRef *) lua_touserdata(L, -1);
        
        if(p != nil) {
            const char * name = lua_tostring(L, - top + 1);
            return [(__bridge id) * p KKLuaObjectSet:[NSString stringWithCString:name encoding:NSUTF8StringEncoding] L:L];
        }
    }
    
    return 0;
}

void lua_pushObject(lua_State * L, id object) {
    
    if(object == nil) {
        lua_pushnil(L);
        return ;
    }
    
    CFTypeRef *p = (CFTypeRef *) lua_newuserdata(L, sizeof(CFTypeRef));
    
    * p = CFBridgingRetain(object);
    
    lua_newtable(L);
    lua_pushstring(L, "__gc");
    lua_pushcfunction(L, KKLuaObjectGcFunction);
    lua_rawset(L, -3);
    
    lua_pushstring(L, "__index");
    lua_pushcfunction(L, KKLuaObjectIndexFunction);
    lua_rawset(L, -3);
    
    lua_pushstring(L, "__newindex");
    lua_pushcfunction(L, KKLuaObjectNewIndexFunction);
    lua_rawset(L, -3);
    
    lua_setmetatable(L, -2);
    
}

id lua_toObject(lua_State * L, int idx) {

    CFTypeRef *p = (CFTypeRef *) lua_touserdata(L, idx);
    
    if(p != nil) {
        return (__bridge id)(* p);
    }
    
    return nil;
    
}

BOOL lua_isObject(lua_State * L, int idx) {
    
    BOOL r = NO;
    
    if(lua_isuserdata(L, idx)) {
        
        lua_getmetatable(L, idx);
        
        if(lua_istable(L, -1)) {
            
            lua_pushstring(L, "__gc");
            lua_rawget(L, -2);
            
            if(lua_iscfunction(L, -1)) {
                r = lua_tocfunction(L, -1) == KKLuaObjectGcFunction;
            }
            
            lua_pop(L, 1);
            
        }
        
        lua_pop(L, 1);
    }
    
    return r;
}

void lua_pushValue(lua_State * L, id value) {
    if(value == nil || [value isKindOfClass:[NSNull class]] ) {
        lua_pushnil(L);
    }
    else if([value isKindOfClass:[NSNumber class]]) {
        if(strcmp([value objCType] ,@encode(BOOL)) == 0) {
            lua_pushboolean(L, [value boolValue]);
        }
        else {
            lua_pushnumber(L, [value doubleValue]);
        }
    }
    else if([value isKindOfClass:[NSString class]]) {
        lua_pushstring(L, [value UTF8String]);
    }
    else {
        lua_pushObject(L, value);
    }
}

id lua_toValue(lua_State * L, int idx) {
    
    int type = lua_type(L, idx);
    
    switch (type) {
        case LUA_TNUMBER:
            return [NSNumber numberWithDouble:lua_tonumber(L, idx)];
        case LUA_TBOOLEAN:
            return [NSNumber numberWithBool:lua_toboolean(L, idx)];
        case LUA_TSTRING:
            return [NSString stringWithCString:lua_tostring(L, idx) encoding:NSUTF8StringEncoding];
        case LUA_TUSERDATA:
            if(lua_isObject(L,idx)) {
                return lua_toObject(L, idx);
            }
            break;
        case LUA_TTABLE:
        
        {
            NSMutableDictionary * object = [NSMutableDictionary dictionaryWithCapacity:4];
            NSMutableArray * array = [NSMutableArray arrayWithCapacity:4];
            
            int i = 0;
            int size = 0;
            
            lua_pushnil(L);
            
            while(lua_next(L, idx - 1)) {
                
                if(lua_type(L, -2) == LUA_TNUMBER) {
                    if(lua_tointeger(L, -2) == i +1) {
                        id v = lua_toValue(L, -1);
                        i ++;
                        [array addObject:v];
                        [object setValue:v forKey:[NSString stringWithFormat:@"%d",i]];
                    } else if(lua_isinteger(L, -2)) {
                        id v = lua_toValue(L, -1);
                        [object setValue:v forKey:[NSString stringWithFormat:@"%d",lua_tointeger(L, -2)]];
                    } else {
                        id v = lua_toValue(L, -1);
                        [object setValue:v forKey:[NSString stringWithFormat:@"%f",lua_tonumber(L, -2)]];
                    }
                }
                else if(lua_type(L,-2) == LUA_TSTRING){
                    if(lua_isinteger(L, -2) && lua_tointeger(L, -2) == i +1) {
                        id v = lua_toValue(L, -1);
                        i ++ ;
                        [array addObject:v];
                        [object setValue:v forKey:[NSString stringWithFormat:@"%d",i]];
                        
                    } else {
                        const char * key = lua_tostring(L, -2);
                        id v = lua_toValue(L, -1);
                        [object setValue:v forKey:[NSString stringWithCString:key encoding:NSUTF8StringEncoding]];
                    }
                }
                
                lua_pop(L, 1);
                
                size ++;
            }
            
            if(size == 0) {
                return object;
            }
            
            if(size == i) {
                return array;
            }
            
            return object;
        }
            
        default:
            break;
    }
    
    return nil;
}

@implementation NSObject(KKLuaObject)


-(id) KKLuaObjectValueForKey:(NSString *) key {
    @try {
        return [self valueForKey:key];
    }
    @catch(NSException * e) {
        return nil;
    }
}

-(void) KKLuaObjectValue:(id) value forKey:(NSString *) key {
    @try {
        [self setValue:value forKey:key];
    }
    @catch(NSException * e){}
}

-(int) KKLuaObjectGet:(NSString *) key L:(lua_State *)L {
    id v = [self KKLuaObjectValueForKey:key];
    lua_pushValue(L, v);
    return 1;
}

-(int) KKLuaObjectSet:(NSString *) key L:(lua_State *)L {
    
    id v = lua_toValue(L, -1);
    
    [self KKLuaObjectValue:v forKey:key];
    
    return 0;
}

@end

@implementation NSArray(KKLuaObject)

-(id) KKLuaObjectValueForKey:(NSString *) key{
    
    if([key isEqualToString:@"@last"]) {
        return [self lastObject];
    }
    
    if([key isEqualToString:@"@first"]) {
        return [self firstObject];
    }
    
    if([key isEqualToString:@"@length"]) {
        return [NSNumber numberWithUnsignedInteger:[self count]];
    }
    
    int i = [key intValue];
    
    if(i >=0 && i< [self count]) {
        return [self objectAtIndex:i];
    }
    
    return nil;
}

-(void) KKLuaObjectValue:(id) value forKey:(NSString *) key{
    
}

@end

@implementation NSMutableArray(KKLuaObject)

-(void) KKLuaObjectValue:(id) value forKey:(NSString *) key{
    int i = [key intValue];
    
    if(i >=0 && i< [self count]) {
        [self replaceObjectAtIndex:i withObject:value];
    }
    else if(i == [self count]) {
        [self addObject:value];
    }
}

@end


@interface KKLuaRef() {
    int _ref;
}

@end

@implementation KKLuaRef

-(instancetype) initWithL:(lua_State *) L {
    if((self = [super init])) {
        _L = L;
        _ref = luaL_ref(L, LUA_REGISTRYINDEX);
    }
    return self;
}

-(void) dealloc {
    
    [self unref];
    
}

-(void) unref {
    if(_ref != 0) {
        luaL_unref(_L, LUA_REGISTRYINDEX, _ref);
        _ref = 0;
    }
}

-(void) get {
    if(_ref == 0) {
        lua_pushnil(_L);
    }
    else {
        lua_rawgeti(_L, LUA_REGISTRYINDEX, _ref);
    }
}

@end

@implementation KKLuaWeakObject

-(instancetype) initWithObject:(id)object {
    if((self = [super init])) {
        _object = object;
    }
    return self;
}

-(int) KKLuaObjectGet:(NSString *) key L:(lua_State *)L {
    return [_object KKLuaObjectGet:key L:L];
}

-(int) KKLuaObjectSet:(NSString *) key L:(lua_State *)L {
    return [_object KKLuaObjectSet:key L:L];
}

@end
