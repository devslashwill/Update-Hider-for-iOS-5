#import "LoadingCell.h"

@implementation LoadingCell

@synthesize loading = _loading;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)identifier
{
    if ((self = [super initWithStyle:style reuseIdentifier:identifier]))
    {
        _loading = NO;
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        self.textLabel.font = [UIFont boldSystemFontOfSize:15.0f];
        self.textLabel.textColor = RGB(47, 52, 60);
        self.textLabel.textAlignment = UITextAlignmentCenter;
        self.textLabel.shadowColor = RGB(206, 206, 208);
        self.textLabel.shadowOffset = CGSizeMake(0, 1);
        
        _loadingView = [[objc_getClass("SULoadingView") alloc] initWithFrame:CGRectZero];
        [_loadingView setStyle:0];
		[_loadingView sizeToFit];
		_loadingView.frame = CGRectMake((self.frame.size.width - _loadingView.frame.size.width) / 2, (69 - _loadingView.frame.size.height) / 2, _loadingView.frame.size.width, _loadingView.frame.size.height);
		_loadingView.textShadowColor = RGB(206, 206, 208);
    }
    return self;
}

// Not sure how to get screen width for iPad at this point so this hacky thing will do for now
- (void)_setScreenWidth:(CGFloat)width
{
    CGRect frame = _loadingView.frame;
    _loadingView.frame = CGRectMake((width - frame.size.width) / 2, (69 - frame.size.height) / 2, frame.size.width, frame.size.height);
}

- (void)setLoading:(BOOL)loading
{
    if (loading == _loading)
        return;
    
    _loading = loading;
    
    self.textLabel.text = nil;
    
    if (loading)
        [[self contentView] addSubview:_loadingView];
    else
        [_loadingView removeFromSuperview];
}

- (void)dealloc
{
    [_loadingView release];
    [super dealloc];
}

@end
