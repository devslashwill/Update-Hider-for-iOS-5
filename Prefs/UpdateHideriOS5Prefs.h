#import "Common.h"
#import "PSViewController.h"
#import "IconImageDownloader.h"
#import "Update.h"
#import "AppCell.h"
#import "LoadingCell.h"

@interface SSSoftwareUpdatesResponse : NSObject

@property (readonly) NSArray *updateItems;
@property (readonly, getter=isFailed) BOOL failed;
@property (readonly) NSError *error;

@end

@protocol SSSoftwareUpdatesRequestDelegate;

@interface SSSoftwareUpdatesRequest : NSObject

- (id)initWithPropertyListEncoding:(NSDictionary *)encoding;
- (BOOL)start;
@property (nonatomic, assign) id <SSSoftwareUpdatesRequestDelegate> delegate;

@end

@protocol SSSoftwareUpdatesRequestDelegate 
@optional
- (void)updateQueueRequest:(SSSoftwareUpdatesRequest *)request didReceiveResponse:(SSSoftwareUpdatesResponse *)response;
@end

@interface SSItem : NSObject
- (NSDictionary *)rawItemDictionary;
@end

@interface UINavigationButton : UIButton
- (id)initWithTitle:(NSString *)title;
@property (nonatomic, assign) int style;
@property (nonatomic, assign) int barStyle;
@end

@interface UpdateHideriOS5PrefsController: PSViewController <UITableViewDelegate, UITableViewDataSource, SSSoftwareUpdatesRequestDelegate, IconImageDownloaderDelegate, UIScrollViewDelegate>
{
    UITableView *_tableView;
    NSMutableArray *_blockedUpdates;
    NSMutableArray *_realUpdates;
    NSMutableDictionary *_iconDownloaders;
    LoadingCell *_loadingCell;
    UILabel *_pullToRefreshLabel;
}

- (void)loadImagesForVisibleCells;

@end
