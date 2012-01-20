#import "AppCell.h"

@implementation AppCell

@synthesize topLineColor = _topLineColor;
@synthesize bottomLineColor = _bottomLineColor;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)identifier
{
    if ((self = [super initWithStyle:style reuseIdentifier:identifier]))
    {   
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        self.imageView.layer.masksToBounds = YES;
        self.imageView.layer.cornerRadius = 9.0f;
        
        self.textLabel.font = [UIFont boldSystemFontOfSize:16.0f];
        self.textLabel.shadowColor = RGB(206, 206, 208);
        self.textLabel.shadowOffset = CGSizeMake(0, 1);
        
        self.detailTextLabel.font = [UIFont boldSystemFontOfSize:12.5f];
        self.detailTextLabel.textColor = RGB(58, 58, 58);
        self.detailTextLabel.shadowColor = RGB(206, 206, 208);
        self.detailTextLabel.shadowOffset = CGSizeMake(0, 1);
    }
    return self;
}

- (void)dealloc
{
    self.topLineColor = nil;
    self.bottomLineColor = nil;
    [super dealloc];
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    self.imageView.bounds = CGRectMake(10, 6, 57, 57);
    self.imageView.frame = CGRectMake(10, 6, 57, 57);
    
    if (self.imageView.image != nil)
    {
        CGRect frame = self.textLabel.frame;
        frame.origin.x = 77;
        self.textLabel.frame = frame;
        
        frame = self.detailTextLabel.frame;
        frame.origin.x = 77;
        self.detailTextLabel.frame = frame;
    }
}

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, self.topLineColor.CGColor);
    CGContextFillRect(context, CGRectMake(0, 0, self.bounds.size.width, 1));
    
    CGContextSetFillColorWithColor(context, self.bottomLineColor.CGColor);
    CGContextFillRect(context, CGRectMake(0, self.bounds.size.height - 1, self.bounds.size.width, 1));
}

@end
