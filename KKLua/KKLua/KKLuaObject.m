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
            id v = [(__bridge id) * p KKLuaObjectValueForKey:[NSString stringWithCString:name encoding:NSUTF8StringEncoding]];
            lua_pushValue(L, v);
            return 1;
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
            id v = top > 2 ? lua_toValue(L, -top +2) : nil;
            [(__bridge id) * p KKLuaObjectValue:v forKey:[NSString stringWithCString:name encoding:NSUTF8StringEncoding]];
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

    CFTypeRef *p = (CFTypeRef *) lua_touserdata(L, -1);
    
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
            
            if(lua_iscfunction(L, -1)) {
                r = lua_tocfunction(L, -1) == KKLuaObjectGcFunction;
            }
            
            lua_pop(L, -1);
            
        }
        
        lua_pop(L, 1);
    }
    
    return r;
}

void lua_pushValue(lua_State * L, id value) {
    if(value == nil) {
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
                
                const char * key = lua_tostring(L, -2);
                int ii = atoi(key);
                
                if(i + 1 == ii) {
                    i ++;
                }
                
                id v = lua_toValue(L, -1);
                
                [object setValue:v forKey:[NSString stringWithCString:key encoding:NSUTF8StringEncoding]];
                [array addObject:v];
                
                lua_pop(L, 1);
                
                size ++;
            }
            
            if(i == size && size != 0) {
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
        return [self setValue:value forKey:key];
    }
    @catch(NSException * e) {
    }
}

@end

@implementation NSArray(KKLuaObject)

-(id) KKLuaObjectValueForKey:(NSString *) key {
    
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

-(void) KKLuaObjectValue:(id) value forKey:(NSString *) key {
    
}

@end

@implementation NSMutableArray(KKLuaObject)

-(void) KKLuaObjectValue:(id) value forKey:(NSString *) key {
    int i = [key intValue];
    
    if(i >=0 && i< [self count]) {
        [self replaceObjectAtIndex:i withObject:value];
    }
    else if(i == [self count]) {
        [self addObject:value];
    }
}

@end
