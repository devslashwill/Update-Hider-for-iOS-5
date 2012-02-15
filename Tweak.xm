#import "Header.h"

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

%hook SUWebViewController

- (void)webViewDidFinishLoad:(SUWebView *)webView
{
    %orig;
    
    if ([[[[[webView webDataSource] initialRequest] URL] absoluteString] isEqualToString:@"http://ax.su.itunes.apple.com/WebObjects/MZSoftwareUpdate.woa/wa/viewSoftwareUpdates"])
    {        
        NSUInteger numBlocked = 0;
        UIViewController *updatesVC = [[(SUTabBarController *)[[%c(SUClientApplicationController) sharedController] tabBarController] viewControllerForSectionIdentifier:@"updates"] topViewController];
        
        DOMDocument *doc = [webView _DOMDocument];
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
            if (IS_IPAD)
                [doc.body removeChild:[[doc.body getElementsByClassName:@"stack"] item:0]];
            
            DOMHTMLElement *noUpdatesDiv = (DOMHTMLElement *)[doc createElement:@"div"];
            [noUpdatesDiv setClassName:@"no-updates"];
            [noUpdatesDiv setInnerHTML:NO_UPDATES_STRING];
            [IS_IPAD ? doc.body : [[doc.body getElementsByClassName:@"stack"] item:0] appendChild:noUpdatesDiv];
            
            updatesVC.tabBarItem.badgeValue = nil;
            [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
            updatesVC.navigationItem.rightBarButtonItem = nil;
        }
        else
        {
            updatesVC.tabBarItem.badgeValue = [NSString stringWithFormat:@"%i", (numOfUpdates - numBlocked)];
            [UIApplication sharedApplication].applicationIconBadgeNumber = (numOfUpdates - numBlocked);
        }
    }
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
    NSArray *blockedUpdates = [[NSArray alloc] initWithContentsOfFile:@"/var/mobile/Library/Preferences/com.whomer.UpdateHideriOS5.plist"];
    
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
    
    [blockedUpdates release];
    
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