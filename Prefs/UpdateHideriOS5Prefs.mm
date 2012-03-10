#import "UpdateHideriOS5Prefs.h"

@interface NSIndexPath (AltDesc)
- (NSString *)altDescription;
@end

@implementation NSIndexPath (AltDesc)

- (NSString *)altDescription
{
    return [NSString stringWithFormat:@"[%d, %d]", [self indexAtPosition:0], [self indexAtPosition:1]];
}

@end

@implementation UpdateHideriOS5PrefsController

- (void)dealloc
{
    [_loadingCell release];
    [_blockedUpdates release];
    [_realUpdates release];
    [_iconDownloaders release];
    [_pullToRefreshLabel release];
    [_tableView release];
    [super dealloc];
}

- (void)saveBlockedUpdates
{
    NSMutableArray *saves = [[NSMutableArray alloc] init];
    
    for (Update *upd in _blockedUpdates)
    {
        [saves addObject:[upd dictionaryRepresentation]];
    }
    
    [saves writeToFile:@"/var/mobile/Library/Preferences/com.whomer.UpdateHideriOS5.plist" atomically:YES];
    [saves release];
}

- (BOOL)isUpdateBlocked:(NSDictionary *)update
{
    NSString *bundleID = [update objectForKey:@"bundle-id"];
    NSString *versionID = [NSString stringWithFormat:@"%i", [[update objectForKey:@"version-external-identifier"] intValue]];
    
    for (Update *blockedUpdate in _blockedUpdates)
    {
        if ([blockedUpdate.bundleID isEqualToString:bundleID] && [blockedUpdate.versionID isEqualToString:versionID])
            return YES;
    }
    
    return NO;
}

- (void)runUpdatesRequest
{
    [_loadingCell setLoading:YES];
    
    NSDictionary *encoding = [NSDictionary dictionaryWithObjectsAndKeys:[NSArray arrayWithObject:@"regular"], @"0", nil];
    SSSoftwareUpdatesRequest *updateRequest = [[objc_getClass("SSSoftwareUpdatesRequest") alloc] initWithPropertyListEncoding:encoding];
    [updateRequest setDelegate:self];
    [updateRequest start];
}

- (void)updateQueueRequest:(SSSoftwareUpdatesRequest *)request didReceiveResponse:(SSSoftwareUpdatesResponse *)response
{
    [_realUpdates removeAllObjects];
    [_loadingCell setLoading:NO];
    
    if ([response isFailed])
    {
        _loadingCell.textLabel.text = [[response error] localizedDescription];
        [_tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
        [request release];
        return;
    }
    
    NSArray *updateItems = [response updateItems];
    
    if ([updateItems count] == 0)
    {
        _loadingCell.textLabel.text = NO_UPDATES_STRING;
        [_tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
        [request release];
        return;
    }
    
    for (NSUInteger i = 0; i < [updateItems count]; i++)
    {
        NSDictionary *updateDict = [(SSItem *)[updateItems objectAtIndex:i] rawItemDictionary];
        if (![self isUpdateBlocked:updateDict])
        {
            Update *upd = [[Update alloc] init];
            upd.name = [updateDict objectForKey:@"title"];
            upd.bundleID = [updateDict objectForKey:@"bundle-id"];
            upd.version = [updateDict objectForKey:@"version"];
            upd.versionID = [NSString stringWithFormat:@"%i", [[updateDict objectForKey:@"version-external-identifier"] intValue]];
            upd.iconURL = [[[updateDict objectForKey:@"artwork-urls"] objectAtIndex:(int)[[UIScreen mainScreen] scale] - 1] objectForKey:@"url"];
            [_realUpdates addObject:upd];
            [upd release];
        }
    }
    
    if ([_realUpdates count] > 0)
    {
        NSSortDescriptor *titleSort = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES selector:@selector(caseInsensitiveCompare:)];
        [_realUpdates sortUsingDescriptors:[NSArray arrayWithObject:titleSort]];
        
        [_tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
        [self loadImagesForVisibleCells];
    }
    else
    {
        _loadingCell.textLabel.text = NO_UPDATES_STRING;
        [_tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
        [self loadImagesForVisibleCells];
    }
}

- (void)downloadIconImageForIndexPath:(NSIndexPath *)indexPath
{
    IconImageDownloader *downloader = [_iconDownloaders objectForKey:[indexPath altDescription]];
    if (downloader == nil)
    {
        NSURL *url = [NSURL URLWithString:[[indexPath.section == 0 ? _realUpdates : _blockedUpdates objectAtIndex:indexPath.row] iconURL]];
        
        if (url == nil)
            return;
        
        downloader = [[IconImageDownloader alloc] initWithURL:url];
        downloader.delegate = self;
        downloader.indexPath = indexPath;
        [_iconDownloaders setObject:downloader forKey:[indexPath altDescription]];
        [downloader start];
        [downloader release];
    }
}

- (void)loadImagesForVisibleCells
{
    if ([_realUpdates count] > 0 || [_blockedUpdates count] > 0)
    {
        NSArray *visibleIndexes = [_tableView indexPathsForVisibleRows];
        for (NSIndexPath *indexPath in visibleIndexes)
        {
            if (indexPath.section == 0 && [_realUpdates count] == 0)
                continue;
            
            if ([[indexPath.section == 0 ? _realUpdates : _blockedUpdates objectAtIndex:indexPath.row] iconImage] == nil)
                [self downloadIconImageForIndexPath:indexPath];
        }
    }
}

- (void)iconImageDownloader:(IconImageDownloader *)downloader didFinishLoadingImage:(UIImage *)image
{
    [[downloader.indexPath.section == 0 ? _realUpdates : _blockedUpdates objectAtIndex:downloader.indexPath.row] setIconImage:image];
    [_tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:downloader.indexPath] withRowAnimation:UITableViewRowAnimationNone];
    [_iconDownloaders removeObjectForKey:[downloader.indexPath altDescription]];
}

- (void)iconImageDownloader:(IconImageDownloader *)downloader didFailWithError:(NSError *)error
{
    [_iconDownloaders removeObjectForKey:[downloader.indexPath altDescription]];
}

- (void)ignoreButtonPressed:(UINavigationButton *)button
{
    NSIndexPath *oldIndexPath = [NSIndexPath indexPathForRow:button.tag inSection:0];
    NSIndexPath *newIndexPath = [NSIndexPath indexPathForRow:[_blockedUpdates count] inSection:1];
    
    [_tableView beginUpdates];
    
    if ([_iconDownloaders objectForKey:[oldIndexPath altDescription]] != nil)
        [[_iconDownloaders objectForKey:[oldIndexPath altDescription]] setIndexPath:newIndexPath];
    
    Update *upd = [_realUpdates objectAtIndex:oldIndexPath.row];
    [upd retain];
    [_realUpdates removeObjectAtIndex:oldIndexPath.row];
    [_blockedUpdates addObject:upd];
    [upd release];
    
    [_tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:oldIndexPath] withRowAnimation:UITableViewRowAnimationFade];
    
    if ([_blockedUpdates count] == 1)
        [_tableView insertSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationFade];
    else
        [_tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
    
    if ([_realUpdates count] == 0)
    {
        [_tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
        _loadingCell.textLabel.text = NO_UPDATES_STRING;
    }
    
    [_tableView endUpdates];
    
    [_tableView reloadData];
    
    [self saveBlockedUpdates];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"Update Hider";
    
    _blockedUpdates = [[NSMutableArray alloc] init];
    
    for (NSDictionary *dict in [[NSMutableArray alloc] initWithContentsOfFile:@"/var/mobile/Library/Preferences/com.whomer.UpdateHideriOS5.plist"])
    {
        Update *upd = [[Update alloc] init];
        upd.name = [dict objectForKey:@"name"];
        upd.bundleID = [dict objectForKey:@"bundleID"];
        upd.version = [dict objectForKey:@"version"];
        upd.versionID = [dict objectForKey:@"versionID"];
        upd.iconURL = [dict objectForKey:@"iconURL"];
        [_blockedUpdates addObject:upd];
        [upd release];
    }
    
    _realUpdates = [[NSMutableArray alloc] init];
    _iconDownloaders = [[NSMutableDictionary alloc] init];
    
    _loadingCell = [[LoadingCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"LoadingCell"];
    [_loadingCell _setScreenWidth:self.view.frame.size.width];
    
    _tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    _tableView.backgroundColor = RGB(173, 173, 176);
    _tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:_tableView];
    
    UIView *headerBG = [[UIView alloc] initWithFrame:CGRectMake(0, -(self.view.frame.size.height), self.view.frame.size.width, self.view.frame.size.height)];
    headerBG.backgroundColor = RGB(152, 152, 156);
    [_tableView addSubview:headerBG];
    [headerBG release];
    
    _pullToRefreshLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, -44, self.view.frame.size.width, 44)];
    _pullToRefreshLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    _pullToRefreshLabel.textColor = RGB(58, 58, 58);
    _pullToRefreshLabel.shadowColor = RGB(194, 194, 194);
    _pullToRefreshLabel.shadowOffset = CGSizeMake(0, 1);
    _pullToRefreshLabel.font = [UIFont boldSystemFontOfSize:16.0f];
    _pullToRefreshLabel.backgroundColor = [UIColor clearColor];
    _pullToRefreshLabel.textAlignment = UITextAlignmentCenter;
    _pullToRefreshLabel.text = @"Pull to reload updates";
    [_tableView addSubview:_pullToRefreshLabel];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self runUpdatesRequest];
    [self loadImagesForVisibleCells];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    for (IconImageDownloader *downloader in [_iconDownloaders allValues])
    {
        [downloader cancel];
        [downloader release];
    }
    
    for (Update *upd in _realUpdates)
    {
        upd.iconImage = nil;
    }
    
    for (Update *upd in _blockedUpdates)
    {
        upd.iconImage = nil;
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)orientation
{
    return (orientation == UIInterfaceOrientationPortrait);
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if ([_blockedUpdates count])
        return 2;
    
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0)
    {
        if ([_realUpdates count] > 0)
            return [_realUpdates count];
        
        return 1;
    }
    
    return [_blockedUpdates count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 0)
        return @"Recent Updates";
    
    return @"Hidden Updates";
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 69.0f;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0 && [_realUpdates count] == 0)
    {
        return _loadingCell;
    }
     
    AppCell *cell = [tableView dequeueReusableCellWithIdentifier:@"AppCell"];
        
    if (!cell)
        cell = [[[AppCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"AppCell"] autorelease];
    
    Update *upd = [indexPath.section == 0 ? _realUpdates : _blockedUpdates objectAtIndex:indexPath.row];
    
    cell.textLabel.text = upd.name;
    cell.detailTextLabel.text = [NSString stringWithFormat:VERSION_FORMAT_STRING, upd.version];
    cell.imageView.image = (upd.iconImage != nil) ? upd.iconImage : [UIImage imageWithContentsOfFile:@"/System/Library/PrivateFrameworks/AppStoreUI.framework/PlaceholderApp.png"];
    
    cell.accessoryView = nil;
    
    if (indexPath.section == 0)
    {
        UINavigationButton *navButton = [[objc_getClass("UINavigationButton") alloc] initWithTitle:HIDE_STRING];
        
        navButton.style = 3;
        navButton.barStyle = 0;
        navButton.tag = indexPath.row;
        [navButton sizeToFit];
        
        [navButton addTarget:self action:@selector(ignoreButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        
        cell.accessoryView = navButton;
        [navButton release];
    }
    
    return (UITableViewCell *)cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0 && [_realUpdates count] == 0)
    {
        cell.backgroundColor = RGB(152, 152, 156);
        return;
    }
            
    if (indexPath.row % 2 != 0)
    {
        cell.backgroundColor = RGB(173, 173, 176);
        ((AppCell *)cell).topLineColor = RGB(189, 189, 192);
        ((AppCell *)cell).bottomLineColor = RGB(153, 153, 155);
    }
    else
    {
        cell.backgroundColor = RGB(152, 152, 156);
        ((AppCell *)cell).topLineColor = RGB(173, 173, 176);
        ((AppCell *)cell).bottomLineColor = RGB(134, 134, 138);
    }
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 1)
    {
        IconImageDownloader *dler = [_iconDownloaders objectForKey:[indexPath altDescription]];
        if (dler != nil)
        {
            [dler cancel];
            [_iconDownloaders removeObjectForKey:[indexPath altDescription]];
        }
        
        [_blockedUpdates removeObjectAtIndex:indexPath.row];
        [self saveBlockedUpdates];
        
        [tableView beginUpdates];
        
        if ([_blockedUpdates count] == 0)
            [tableView deleteSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationFade];
        else
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
        
        [tableView endUpdates];
        
        [tableView reloadData];
        
        if (![_loadingCell isLoading])
            [self runUpdatesRequest];
    }
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0)
        return UITableViewCellEditingStyleNone;
    
    return UITableViewCellEditingStyleDelete;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (scrollView.dragging == YES)
    {
        if (scrollView.contentOffset.y <= -65.0f)
            _pullToRefreshLabel.text = @"Release to reload updates";
        else if (scrollView.contentOffset.y < 0.0f)
            _pullToRefreshLabel.text = @"Pull to reload updates";
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (scrollView.contentOffset.y <= -65.0f && [_loadingCell isLoading] == NO)
    {
        [self runUpdatesRequest];
    }
    
    if (!decelerate)
        [self loadImagesForVisibleCells];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [self loadImagesForVisibleCells];
}

@end
