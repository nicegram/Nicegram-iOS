#import <Foundation/Foundation.h>

#import "LegacyComponentsInternal.h"

#import <LegacyComponents/TGLocalization.h>

NSString *NGLocalized(NSString *key) {
    TGLocalization *localization = [[LegacyComponentsGlobals provider] effectiveLocalization];
    NSString *code = localization.code;
    NSString *table = @"NiceLocalizable";
    
    NSBundle *enBundle = [NSBundle bundleWithPath:[[NSBundle mainBundle] pathForResource:@"en" ofType:@"lproj"]];
    NSBundle *bundle = [NSBundle bundleWithPath:[[NSBundle mainBundle] pathForResource:code ofType:@"lproj"]];
    
    NSString *enString = [enBundle localizedStringForKey:key value:key table:table];
    
    return [bundle localizedStringForKey:key value:enString table:table];
}
