#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#define APP_STORE_UI_FRAMEWORK [NSBundle bundleWithPath:@"/System/Library/PrivateFrameworks/AppStoreUI.framework"]
#define NO_UPDATES_STRING NSLocalizedStringFromTableInBundle(@"NO_UPDATES", @"Localizable", APP_STORE_UI_FRAMEWORK, @"")
#define IS_IPAD ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)

@interface DOMNode : NSObject
@property (readonly, retain) DOMNode *parentNode;
- (id)getElementsByClassName:(NSString *)className;
- (id)removeChild:(id)node;
@end

@interface DOMElement : DOMNode
- (id)getAttribute:(NSString *)attr;
- (void)setAttribute:(NSString *)attr value:(NSString *)value;
@property (readonly, retain) DOMElement *firstElementChild;
@property (readonly, retain) DOMNode *parentNode;
@end

@interface DOMNodeList : NSObject
@property (readonly) NSUInteger length;
- (id)item:(NSUInteger)index;
@end

@interface DOMDocument : NSObject
@property (retain) DOMElement *body;
- (id)getElementsByClassName:(NSString *)className;
@end

@interface WebDataSource : NSObject
- (NSURLRequest *)initialRequest;
@end

@interface WebFrame : NSObject
- (DOMDocument *)DOMDocument;
- (WebDataSource *)dataSource;
- (NSString *)_stringByEvaluatingJavaScriptFromString:(NSString *)js;
@end

@interface ASClientApplicationController : NSObject
+ (id)sharedController;
@end

@interface SoftwareUpdate : NSObject
@property (readonly, nonatomic) NSDictionary *dictionary;
@property (readonly, nonatomic) NSNumber *_versionIdentifier;
@end

NSArray *blockedUpdates = nil;

BOOL isUpdateBlocked(NSString *bundleID, NSString *versionID)
{
	BOOL blocked = NO;
	
	for (NSDictionary *item in blockedUpdates)
	{
		if ([bundleID isEqualToString:[item objectForKey:@"bundleID"]] && [versionID isEqualToString:[item objectForKey:@"versionID"]])
		{
			blocked = YES;
			break;
		}
	}
	
	return blocked;
}

%group AppStoreHooks

// Hook here to execute the hideUpdates js func /before/ the webpage appears
%hook WebDefaultUIKitDelegate

- (void)webView:(id)webView didFinishDocumentLoadForFrame:(WebFrame *)frame
{
    if ([[[[[frame dataSource] initialRequest] URL] absoluteString] isEqualToString:@"http://ax.su.itunes.apple.com/WebObjects/MZSoftwareUpdate.woa/wa/viewSoftwareUpdates"])
    {
        NSUInteger numBlocked = 0;
        
        DOMDocument *doc = [frame DOMDocument];
        DOMNodeList *appDivs = [doc.body getElementsByClassName:@"lockup application"];
        NSUInteger numOfUpdates = [[doc.body getAttribute:@"update-count"] intValue];
        
        if (numOfUpdates == 0)
            return %orig;
        
        NSMutableIndexSet *indexesToRemove = [[NSMutableIndexSet alloc] init];
        
        for (NSUInteger i = 0; i < appDivs.length; i++)
        {
            DOMElement *app = [appDivs item:i];
            DOMElement *appInfoDiv = [[[app getElementsByClassName:@"buy-line"] item:0] firstElementChild];
            
            NSString *bundleID = [appInfoDiv getAttribute:@"bundle-id"];
            NSString *versionID = [appInfoDiv getAttribute:@"versionID"];
            
            if (isUpdateBlocked(bundleID, versionID))
            {
                numBlocked++;
                [indexesToRemove addIndex:i];
            }
        }
        
        [indexesToRemove enumerateIndexesWithOptions:NSEnumerationReverse usingBlock:^(NSUInteger idx, BOOL *stop){
            DOMElement *app = [appDivs item:idx];
            [app.parentNode removeChild:app];
        }];
        
        [indexesToRemove release];
        
        if (numOfUpdates == numBlocked)
        {
            // Do this using JavaScript because I can't figure out how to create a new DOMElement instance
            NSString *js = [NSString stringWithFormat:@" %@ \
                                var noUpdatesDiv = document.createElement(\"div\"); \
                                noUpdatesDiv.setAttribute(\"class\", \"no-updates\"); \
                                noUpdatesDiv.innerHTML = \"%@\"; \
                                %@.appendChild(noUpdatesDiv); \
                                iTunes.viewController.navigationItem.rightItem=null;",
                                (IS_IPAD == YES) ? @"document.body.removeChild(document.body.getElementsByClassName(\"stack\")[0]);" : @"",
                                NO_UPDATES_STRING, (IS_IPAD == YES) ? @"document.body" : @"document.body.getElementsByClassName(\"stack\")[0]"];
            
            [frame _stringByEvaluatingJavaScriptFromString:js];
        }
        
        NSString *js = [NSString stringWithFormat:@" \
                            var num = %i; \
                            var updatesSection = iTunes.sectionsController.sectionWithIdentifier(\"updates\"); \
                            if (num > 0) { \
                                updatesSection.badgeValue = num+\"\"; \
                                iTunes.application.iconBadgeNumber = num; \
                            } else { \
                                updatesSection.badgeValue = null; \
                                iTunes.application.iconBadgeNumber = 0; \
                        }", (numOfUpdates - numBlocked)];
                            
        
        [frame _stringByEvaluatingJavaScriptFromString:js];
    }
    
    %orig;
}

%end

%hook SUApplication

- (void)_applicationDidFinishLaunching:(UIApplication *)arg1
{
    %orig;
    
    blockedUpdates = [[NSArray alloc] initWithContentsOfFile:@"/var/mobile/Library/Preferences/com.whomer.UpdateHideriOS5.plist"];
}

- (void)applicationWillEnterForeground:(UIApplication *)arg1
{
    %orig;
    
    if (blockedUpdates != nil)
        [blockedUpdates release];
    
    blockedUpdates = [[NSArray alloc] initWithContentsOfFile:@"/var/mobile/Library/Preferences/com.whomer.UpdateHideriOS5.plist"];
}

%end

%end

%group iTunesStoreDHooks

%hook SoftwareUpdateStore

- (void)setSoftwareUpdates:(NSArray *)updates
{
    if (blockedUpdates != nil)
        [blockedUpdates release];
    
    blockedUpdates = [[NSArray alloc] initWithContentsOfFile:@"/var/mobile/Library/Preferences/com.whomer.UpdateHideriOS5.plist"];
    
    NSMutableArray *updatesToKeep = [[NSMutableArray alloc] init];
    
    for (SoftwareUpdate *su in updates)
    {
        NSString *bundleID = [[su dictionary] objectForKey:@"bundle-id"];
        NSString *versionID = [[su _versionIdentifier] stringValue];
        
        if (!isUpdateBlocked(bundleID, versionID))
        {
            [updatesToKeep addObject:su];
        }
    }
    
    %orig([updatesToKeep autorelease]);
}

%end

%end

%ctor
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];
    
    if ([bundleID isEqualToString:@"com.apple.AppStore"])
        %init(AppStoreHooks);
    else if ([bundleID isEqualToString:@"com.apple.itunesstored"])
        %init(iTunesStoreDHooks);
    
    [pool drain];
}