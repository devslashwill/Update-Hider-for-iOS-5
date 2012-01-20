#import "IconImageDownloader.h"

@implementation IconImageDownloader

@synthesize imgData  =_imgData;
@synthesize urlConnection = _urlConnection;
@synthesize delegate = _delegate;
@synthesize indexPath = _indexPath;

- (id)initWithURL:(NSURL *)url
{
    if ((self = [super init]))
    {
        self.imgData = [NSMutableData data];
        NSURLConnection *con = [[NSURLConnection alloc] initWithRequest:[NSURLRequest requestWithURL:url] delegate:self startImmediately:NO];
        self.urlConnection = con;
        [con release];
    }
    return self;
}

- (void)dealloc
{
    [_urlConnection release];
    [_imgData release];
    [_indexPath release];
    [super dealloc];
}

- (void)start
{
    [self.urlConnection start];
}

- (void)cancel
{
    [self.urlConnection cancel];
    self.imgData = nil;
    self.urlConnection = nil;
    self.indexPath = nil;
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [self.imgData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    self.urlConnection = nil;
    self.imgData = nil;
    [self.delegate iconImageDownloader:self didFailWithError:error];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    UIImage *image = [[UIImage alloc] initWithData:self.imgData];
    self.imgData = nil;
    self.urlConnection = nil;
    [self.delegate iconImageDownloader:self didFinishLoadingImage:[image autorelease]];
}

@end