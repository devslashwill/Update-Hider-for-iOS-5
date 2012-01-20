#import "Common.h"

@interface Update : NSObject
{
    NSString *_name;
    NSString *_bundleID;
    NSString *_version;
    NSString *_versionID;
    NSString *_iconURL;
    UIImage *_iconImage;
}

@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *bundleID;
@property (nonatomic, retain) NSString *version;
@property (nonatomic, retain) NSString *versionID;
@property (nonatomic, retain) NSString *iconURL;
@property (nonatomic, retain) UIImage *iconImage;

- (NSDictionary *)dictionaryRepresentation;

@end
