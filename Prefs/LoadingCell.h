#import "Common.h"

@interface SULoadingView : UIView

- (void)setStyle:(int)style;
@property (nonatomic, retain) UIColor *textShadowColor;

@end

@interface LoadingCell : UITableViewCell
{
    SULoadingView *_loadingView;
    BOOL _loading;
}

@property (nonatomic, assign, getter=isLoading) BOOL loading;

- (void)_setScreenWidth:(CGFloat)width;

@end
