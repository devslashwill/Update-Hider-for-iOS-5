#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreGraphics/CoreGraphics.h>
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>

#define RGB(r, g, b) [UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:1.0]

#define APP_STORE_UI_FRAMEWORK [NSBundle bundleWithPath:@"/System/Library/PrivateFrameworks/AppStoreUI.framework"]
#define ITUNES_STORE_UI_FRAMEWORK [NSBundle bundleWithPath:@"/System/Library/PrivateFrameworks/iTunesStoreUI.framework"]
#define CHATKIT_FRAMEWORK [NSBundle bundleWithPath:@"/System/Library/PrivateFrameworks/ChatKit.framework"]

#define LOADING_STRING NSLocalizedStringFromTableInBundle(@"LOADING", @"Localizable", ITUNES_STORE_UI_FRAMEWORK, @"")
#define VERSION_FORMAT_STRING NSLocalizedStringFromTableInBundle(@"VERSION_FORMAT", @"Localizable", APP_STORE_UI_FRAMEWORK, @"")
#define NO_UPDATES_STRING NSLocalizedStringFromTableInBundle(@"NO_UPDATES", @"Localizable", APP_STORE_UI_FRAMEWORK, @"")
#define HIDE_STRING NSLocalizedStringFromTableInBundle(@"HIDE_DETAILS", @"ChatKit", CHATKIT_FRAMEWORK, @"")
