#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#define APP_STORE_UI_FRAMEWORK [NSBundle bundleWithPath:@"/System/Library/PrivateFrameworks/AppStoreUI.framework"]
#define NO_UPDATES_STRING NSLocalizedStringFromTableInBundle(@"NO_UPDATES", @"Localizable", APP_STORE_UI_FRAMEWORK, @"")
#define IS_IPAD ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)

@interface DOMNode : NSObject
@property (readonly, retain) DOMNode *parentNode;
- (id)getElementsByClassName:(NSString *)className;
- (id)removeChild:(id)node;
- (id)appendChild:(id)node;
@end

@interface DOMElement : DOMNode
- (id)getAttribute:(NSString *)attr;
- (void)setAttribute:(NSString *)attr value:(NSString *)value;
@property (readonly, retain) DOMElement *firstElementChild;
@property (readonly, retain) DOMNode *parentNode;
@property (copy) NSString *className;
@property (copy) NSString *innerHTML;
@end

@interface DOMNodeList : NSObject
@property (readonly) NSUInteger length;
- (id)item:(NSUInteger)index;
@end

@interface DOMDocument : NSObject
@property (retain) DOMElement *body;
- (id)createElement:(NSString *)elementName;
- (id)getElementsByClassName:(NSString *)className;
@end

@interface WebDataSource : NSObject
- (NSURLRequest *)initialRequest;
@end

@interface SUWebView : UIWebView
- (DOMDocument *)_DOMDocument;
- (WebDataSource *)webDataSource;
@end

@interface ASClientApplicationController : NSObject
+ (id)sharedController;
@end

@interface SoftwareUpdate : NSObject
@property (readonly, nonatomic) NSDictionary *dictionary;
@property (readonly, nonatomic) NSNumber *_versionIdentifier;
@end

@interface SUClientApplicationController : NSObject
+ (id)sharedController;
- (UITabBarController *)tabBarController;
@end
