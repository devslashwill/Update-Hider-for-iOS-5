#import "Common.h"

@protocol IconImageDownloaderDelegate;

@interface IconImageDownloader : NSObject
{
    NSMutableData *_imgData;
    NSURLConnection *_urlConnection;
    NSIndexPath *_indexPath;
    id <IconImageDownloaderDelegate> _delegate;
}

- (id)initWithURL:(NSURL *)url;
- (void)start;
- (void)cancel;

@property (nonatomic, retain) NSMutableData *imgData;
@property (nonatomic, retain) NSURLConnection *urlConnection;
@property (nonatomic, assign) id <IconImageDownloaderDelegate> delegate;
@property (nonatomic, retain) NSIndexPath *indexPath;

@end

@protocol IconImageDownloaderDelegate
- (void)iconImageDownloader:(IconImageDownloader *)downloader didFinishLoadingImage:(UIImage *)image;
- (void)iconImageDownloader:(IconImageDownloader *)downloader didFailWithError:(NSError *)error;
@end

