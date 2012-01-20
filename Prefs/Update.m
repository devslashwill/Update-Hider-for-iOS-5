#import "Update.h"

@implementation Update

@synthesize name = _name;
@synthesize bundleID = _bundleID;
@synthesize version = _version;
@synthesize versionID = _versionID;
@synthesize iconURL = _iconURL;
@synthesize iconImage = _iconImage;

- (void)dealloc
{
    [_name release];
    [_bundleID release];
    [_version release];
    [_versionID release];
    [_iconURL release];
    [_iconImage release];
    [super dealloc];
}

- (NSDictionary *)dictionaryRepresentation
{
    return [NSDictionary dictionaryWithObjectsAndKeys:self.name, @"name",
            self.bundleID, @"bundleID", self.version, @"version",
            self.versionID, @"versionID", self.iconURL, @"iconURL", nil];
}

@end