#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import "ObjectiveHooker.h"

static void hook_method(Class base, Class hook, Class proxy, SEL selector)
{
    if ([base instancesRespondToSelector:selector]) {
        /* Hooking a method */
        
        Method base_method = class_getInstanceMethod(base, selector);
        /* Making sure this method is not inherited so we don't affect base's superclass */
        if (class_addMethod(base, selector, method_getImplementation(base_method), method_getTypeEncoding(base_method))) {
            base_method = class_getInstanceMethod(base, selector);
        }
        
        /* Add the message to the proxy so the hook class can use super to call orig */
        class_addMethod(proxy, selector, method_getImplementation(base_method), method_getTypeEncoding(base_method));
        
        /* Hook */
        method_setImplementation(base_method, [hook instanceMethodForSelector:selector]);
    }
    else {
        /* Add a method */
        Method hook_method = class_getInstanceMethod(hook, selector);
        class_addMethod(base, selector, method_getImplementation(hook_method), method_getTypeEncoding(hook_method));
    }
}

static void hook_class_method(Class base, Class hook, Class proxy, SEL selector)
{
    if ([base respondsToSelector:selector]) {
        /* Hooking a method */
        
        Method base_method = class_getClassMethod(base, selector);
        /* Making sure this method is not inherited so we don't affect base's superclass */
        if (class_addMethod(object_getClass(base), selector, method_getImplementation(base_method), method_getTypeEncoding(base_method))) {
            base_method = class_getClassMethod(base, selector);
        }
        
        /* Add the message to the proxy so the hook class can use super to call orig */
        class_addMethod(object_getClass(proxy), selector, method_getImplementation(base_method), method_getTypeEncoding(base_method));
        
        /* Hook */
        method_setImplementation(base_method, [hook methodForSelector:selector]);
    }
    else {
        /* Add a method */
        Method hook_method = class_getClassMethod(hook, selector);
        class_addMethod(object_getClass(base), selector, method_getImplementation(hook_method), method_getTypeEncoding(hook_method));
    }
}

@interface NSObject()
+ (Class) $classToHook;
@end

void OBH_install_hook_class(Class hook)
{
    Class proxy = [hook superclass];
    Class base = [hook $classToHook];
    {
        unsigned count = 0;
        Method *instance_methods = class_copyMethodList(hook, &count);
        
        for (unsigned i = 0; i < count; i++) {
            hook_method(base, hook, proxy, method_getName(instance_methods[i]));
        }
        
        if (instance_methods) {
            free(instance_methods);
        }
    }
    
    {
        unsigned count = 0;
        Method *class_methods = class_copyMethodList(object_getClass(hook), &count);
        
        for (unsigned i = 0; i < count; i++) {
            hook_class_method(base, hook, proxy, method_getName(class_methods[i]));
        }
        
        if (class_methods) {
            free(class_methods);
        }
    }
}


@implementation NSObject(OBHDynamicClassSupport)

+ (void) load
{
    extern struct objc2_class *classrefs[] __asm("section$start$__DATA$__objc_classrefs");
    extern struct objc2_class *classrefs_end __asm("section$end$__DATA$__objc_classrefs");
    
    extern __attribute__((weak)) void dynaclass __asm("section$start$__DATA$__obh_dynaclass");
    extern __attribute__((weak)) void dynaclass_end __asm("section$end$__DATA$__obh_dynaclass");
    
    extern __attribute__((weak)) void dynameta __asm("section$start$__DATA$__obh_dynameta");
    extern __attribute__((weak)) void dynameta_end __asm("section$end$__DATA$__obh_dynameta");
    
    for (struct objc2_class **ref = &classrefs[0]; ref != &classrefs_end; ref++) {
        if ((void *) *ref >= &dynaclass && (void *)*ref < &dynameta_end) {
            *ref = (__bridge struct objc2_class *)(objc_getClass((*ref)->data->name + sizeof("OBH_DUMMY$") - 1));
        }
        if ((void *)*ref >= &dynameta && (void *)*ref < &dynameta_end) {
            *ref = (__bridge struct objc2_class *)objc_getMetaClass((*ref)->data->name + sizeof("OBH_DUMMY$") - 1);
        }
    }
}
@end

const void *OBH_empty_cache[2];
