//
//  PodcastTableViewController.m
//  topiosapps
//
//  Created by Mickey on 3/20/16.
//  Copyright © 2016 Mickey Raj. All rights reserved.
//

#import "Podcast.h"
#import "CustomTableCell.h"
#import "PodcastTableViewController.h"
#import "UIImageView+AFNetworking.h"

#define kTopTwentyFivePodcastsURL [NSURL URLWithString:@"https://itunes.apple.com/us/rss/toppodcasts/limit=25/json"]

@interface PodcastTableViewController () {
    NSMutableArray* podcastsArray;
    NSUserDefaults* nsDefaults;
}
@end

@implementation PodcastTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    nsDefaults = [NSUserDefaults standardUserDefaults];
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    self.refreshControl.backgroundColor = [UIColor grayColor];
    self.refreshControl.tintColor = [UIColor whiteColor];
    [self.refreshControl addTarget:self
                            action:@selector(getTopTwentyFivePodcasts)
                  forControlEvents:UIControlEventValueChanged];
    
    [self podcastTitleAndSubtitle];
    
    NSData* cachedPodcastData = [nsDefaults dataForKey:@"cachedPodcastData"];
    
    if (cachedPodcastData != nil) {
        NSLog(@"getting data from cached results");
        [self getTopTwentyFivePodcastsFromcachedPodcastData:cachedPodcastData];
    }
    else {
        [self getTopTwentyFivePodcasts];
        NSLog(@"No cached data");
    }
}

- (void)getTopTwentyFivePodcasts
{
    
    [NSURLConnection sendAsynchronousRequest:[[NSURLRequest alloc] initWithURL:kTopTwentyFivePodcastsURL] queue:[[NSOperationQueue alloc] init] completionHandler:^(NSURLResponse* response, NSData* data, NSError* error) {
        
        if (!error) {
            NSDictionary* latestTopPodcasts = [self fetchData:response data:data error:error];
            podcastsArray = [NSMutableArray arrayWithCapacity:10];
            
            if (latestTopPodcasts) {
                for (NSDictionary* podcastsDict in latestTopPodcasts) {
                    
                    Podcast* podcast = [[Podcast alloc] init];
                    podcast.name = [podcastsDict valueForKeyPath:@"im:name.label"];
                    podcast.summary = [podcastsDict valueForKeyPath:@"summary.label"];
                    podcast.iconURL = [[[podcastsDict valueForKeyPath:@"im:image"] objectAtIndex:2] objectForKey:@"label"];
                    podcast.podcastURL = [podcastsDict valueForKeyPath:@"link.attributes.href"];
                    
                    [podcastsArray addObject:podcast];
                }
            }
            [self performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
        }else{
            [self showRetryAlertWithError:error];
        }
    }];
}


- (void)getTopTwentyFivePodcastsFromcachedPodcastData:(NSData*)cached
{
    NSDictionary* latestTopPodcasts = [self fetchDataFromCached:cached];
    podcastsArray = [NSMutableArray arrayWithCapacity:10];
    
    if (latestTopPodcasts) {
        for (NSDictionary* podcastsDict in latestTopPodcasts) {
            
            Podcast* podcast = [[Podcast alloc] init];
            podcast.name = [podcastsDict valueForKeyPath:@"im:name.label"];
            podcast.summary = [podcastsDict valueForKeyPath:@"summary.label"];
            podcast.iconURL = [[[podcastsDict valueForKeyPath:@"im:image"] objectAtIndex:2] objectForKey:@"label"];
            podcast.podcastURL = [podcastsDict valueForKeyPath:@"link.attributes.href"];
            
            [podcastsArray addObject:podcast];
        }
    }
    
    [self performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
}

- (NSDictionary*)fetchDataFromCached:(NSData*)response

{
    NSError* jsonError = nil;
    NSDictionary* parsedData = [NSJSONSerialization JSONObjectWithData:response options:0 error:&jsonError];
    
    if (jsonError) {
        [self showRetryAlertWithError:jsonError];
        return nil;
    }
    
    NSDictionary* latestTopPodcasts = [parsedData valueForKeyPath:@"feed.entry"];
    
    return latestTopPodcasts;
}

- (void)reloadData
{
    // Reload table data
    [self.tableView reloadData];
    if (self.refreshControl) {
        
        NSString* title = @"Getting new data";
        NSDictionary* attrsDictionary = [NSDictionary dictionaryWithObject:[UIColor whiteColor]
                                                                    forKey:NSForegroundColorAttributeName];
        NSAttributedString* attributedTitle = [[NSAttributedString alloc] initWithString:title attributes:attrsDictionary];
        self.refreshControl.attributedTitle = attributedTitle;
        
        [self.refreshControl endRefreshing];
    }
}

- (NSDictionary*)fetchData:(NSURLResponse*)response
                      data:(NSData*)data
                     error:(NSError*)error
{
    
    if (error) {
        [self showRetryAlertWithError:error];
        return nil;
    }
    
    NSError* jsonError = nil;
    NSDictionary* parsedData = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
    
    if (jsonError) {
        [self showRetryAlertWithError:jsonError];
        return nil;
    }
    
    [nsDefaults setObject:data forKey:@"cachedPodcastData"];
    
    NSDate* date = [NSDate date];
    [nsDefaults setObject:date forKey:@"lastPodcastUpdated"];
    
    NSDictionary* latestTopPodcasts = [parsedData valueForKeyPath:@"feed.entry"];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self podcastTitleAndSubtitle];
    });
    
    return latestTopPodcasts;
}

- (void)podcastTitleAndSubtitle
{
    UILabel* titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
    titleLabel.backgroundColor = [UIColor clearColor];
    titleLabel.textColor = [UIColor blackColor];
    titleLabel.font = [UIFont boldSystemFontOfSize:20];
    titleLabel.text = @"Top 25 Podcasts";
    [titleLabel sizeToFit];
    
    UILabel* subTitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 22, 0, 0)];
    subTitleLabel.backgroundColor = [UIColor clearColor];
    subTitleLabel.textColor = [UIColor blackColor];
    subTitleLabel.font = [UIFont systemFontOfSize:12];
    
    NSDate* updatedDate = [nsDefaults objectForKey:@"lastPodcastUpdated"];
    
    if (updatedDate) {
        
        NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"EEEE, MMMM dd, yyyy 'at' h:mm a"];
        
        NSLocale* locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
        [formatter setLocale:locale];
        
        subTitleLabel.text = [NSString stringWithFormat:@"updated on %@", [formatter stringFromDate:updatedDate]];
    }
    else {
        subTitleLabel.text = @"";
    }
    
    [subTitleLabel sizeToFit];
    
    UIView* twoLineTitleView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, MAX(subTitleLabel.frame.size.width, titleLabel.frame.size.width), 30)];
    [twoLineTitleView addSubview:titleLabel];
    [twoLineTitleView addSubview:subTitleLabel];
    
    float widthDiff = subTitleLabel.frame.size.width - titleLabel.frame.size.width;
    
    if (widthDiff > 0) {
        CGRect frame = titleLabel.frame;
        frame.origin.x = widthDiff / 2;
        titleLabel.frame = CGRectIntegral(frame);
    }
    else {
        CGRect frame = subTitleLabel.frame;
        frame.origin.x = abs(widthDiff) / 2;
        subTitleLabel.frame = CGRectIntegral(frame);
    }
    
    self.navigationItem.titleView = twoLineTitleView;
}
- (CGFloat)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath
{
    return 97.0;
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    if (podcastsArray) {
        return [podcastsArray count];
    }
    
    return 0;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
    // Return the number of sections.
    if (podcastsArray) {
        
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
        return 1;
    }
    
    return 0;
}

- (void)tableView:(UITableView*)tableView
didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
    
    Podcast *podcast = [podcastsArray objectAtIndex:indexPath.row];
    
    NSURL* url = [NSURL URLWithString:podcast.podcastURL];
    [[UIApplication sharedApplication] openURL:url];
    
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    CustomTableCell* cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    
    // Configure the cell...
    Podcast* podcast = [podcastsArray objectAtIndex:indexPath.row];
    cell.appName.text = podcast.name;
    cell.appSummary.text = podcast.summary;
    
    NSURL* url = [NSURL URLWithString:podcast.iconURL];
    NSURLRequest* request = [NSURLRequest requestWithURL:url];
    UIImage* placeholderImage = [UIImage imageNamed:@"app-icon-placeholder"];
    
    __weak CustomTableCell* weakCell = cell;
    
    [cell.appIcon
     setImageWithURLRequest:request
     placeholderImage:placeholderImage
     success:^(NSURLRequest* request,
               NSHTTPURLResponse* response, UIImage* image) {
         
         weakCell.appIcon.image = image;
         [weakCell setNeedsLayout];
         
     }
     failure:nil];
    
    return cell;
}

- (void)showRetryAlertWithError:(NSError*)error
{
    
    if (self.refreshControl) {
        [self.refreshControl endRefreshing];
    }
    
    
    UIAlertController* alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error fetching data", @"") message:error.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
    
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Dismiss", @"") style:UIAlertActionStyleCancel handler:^(UIAlertAction* _Nonnull action){
        
    }]];
    
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Retry", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction* _Nonnull action) {
        [self getTopTwentyFivePodcasts];
    }]];
    
    [self presentViewController:alertController animated:YES completion:nil];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
