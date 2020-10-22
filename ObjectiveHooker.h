#ifndef ObjectiveHooker_h
#define ObjectiveHooker_h
#import <objc/runtime.h>

void OBH_install_hook_class(Class hook);

struct objc2_class_data
{
    unsigned flags;
    unsigned ivar_start;
    unsigned ivar_end;
    unsigned reserved;
    void *ivar_lyt;
    const char *name;
    void *base_methods;
    void *base_protocols;
    void *ivars;
    void *weak_ivar_lyt;
    void *base_props;
};

struct objc2_class
{
    struct objc2_class *meta_class;
    struct objc2_class *super_class;
    const void *cache;
    void *vtable;
    struct objc2_class_data *data;
};

extern struct objc2_class OBJC_METACLASS_$_NSObject, OBJC_CLASS_$_NSObject;
extern struct objc2_class_data OBH_dummy_class_data;
extern const void *OBH_empty_cache[2];

#define OBHHookClass(Base, Hook) \
@interface Hook##$Proxy : Base \
@end \
@implementation Hook##$Proxy \
@end \
@interface Hook : Hook##$Proxy \
@end \
@implementation Hook($OBHHookClass) \
+ (Class) $classToHook \
{\
    return objc_getClass(#Base);\
}\
+ (void) load \
{ \
    OBH_install_hook_class(self);\
} \
@end

#define OBHHookSwiftClass(Base, Hook, Interface) \
OBHDynamicClass2(Interface, Base)\
@interface Hook##$Proxy : Interface \
@end \
@implementation Hook##$Proxy \
@end \
@interface Hook : Hook##$Proxy \
@end \
@implementation Hook($OBHHookClass) \
+ (Class) $classToHook \
{\
return objc_getClass(#Base);\
}\
+ (void) load \
{ \
    OBH_install_hook_class(self);\
} \
@end

#define OBHDynamicClass2(_symname, _name) \
static struct objc2_class_data OBH_DUMMY_$_##_symname = { .name = "OBH_DUMMY$" #_name}; \
__attribute__((visibility("hidden"))) __attribute__((section("__DATA,__obh_dynaclass"))) struct objc2_class OBJC_METACLASS_$_##_symname __asm__("_OBJC_METACLASS_$_" #_symname) = {&OBJC_METACLASS_$_NSObject, &OBJC_METACLASS_$_NSObject, .cache = &OBH_empty_cache[0], .data = & OBH_DUMMY_$_##_symname,}; \
__attribute__((visibility("hidden"))) __attribute__((section("__DATA,__obh_dynameta"))) struct objc2_class OBJC_CLASS_$_##_symname  __asm__("_OBJC_CLASS_$_" #_symname)  = {&OBJC_METACLASS_$_NSObject, &OBJC_CLASS_$_NSObject, .cache = &OBH_empty_cache[0], .data = & OBH_DUMMY_$_##_symname,};

#define OBHDynamicClass(_name) OBHDynamicClass2(_name, _name)

#endif /* ObjectiveHooker_h */
