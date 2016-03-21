//
//  ViewController.m
//  topiosapps
//
//  Created by Mickey on 3/20/16.
//  Copyright © 2016 Mickey Raj. All rights reserved.
//

#import "App.h"
#import "CustomTableCell.h"
#import "AppTableViewController.h"
#import "UIImageView+AFNetworking.h"

#define kTopTwentyFiveAppsURL [NSURL URLWithString:@"http://ax.itunes.apple.com/WebObjects/MZStoreServices.woa/ws/RSS/topfreeapplications/limit=25/json"]

@interface AppTableViewController () {
    NSMutableArray* appsArray;
    NSUserDefaults* nsDefaults;
}
@end

@implementation AppTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    nsDefaults = [NSUserDefaults standardUserDefaults];

    self.refreshControl = [[UIRefreshControl alloc] init];
    self.refreshControl.backgroundColor = [UIColor grayColor];
    self.refreshControl.tintColor = [UIColor whiteColor];
    [self.refreshControl addTarget:self
                            action:@selector(getTopTwentyFiveApps)
                  forControlEvents:UIControlEventValueChanged];

    [self appTitleAndSubtitle];

    NSData* cachedData = [nsDefaults dataForKey:@"cachedData"];

    if (cachedData != nil) {
        NSLog(@"getting data from cached results");
        [self getTopTwentyFiveAppsFromCachedData:cachedData];
    }
    else {
        [self getTopTwentyFiveApps];
        NSLog(@"No cached data");
    }
}

- (void)getTopTwentyFiveApps
{
    
    [NSURLConnection sendAsynchronousRequest:[[NSURLRequest alloc] initWithURL:kTopTwentyFiveAppsURL] queue:[[NSOperationQueue alloc] init] completionHandler:^(NSURLResponse* response, NSData* data, NSError* error) {

        if (!error) {
            NSDictionary* latestTopApps = [self fetchData:response data:data error:error];
            appsArray = [NSMutableArray arrayWithCapacity:10];

            if (latestTopApps) {
                for (NSDictionary* appsDict in latestTopApps) {

                    App* app = [[App alloc] init];
                    app.name = [appsDict valueForKeyPath:@"im:name.label"];
                    app.summary = [appsDict valueForKeyPath:@"summary.label"];
                    app.iconURL = [[[appsDict valueForKeyPath:@"im:image"] objectAtIndex:2] objectForKey:@"label"];
                    app.appURL = [appsDict valueForKeyPath:@"link.attributes.href"];

                    [appsArray addObject:app];
                }
            }
            [self performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
        }else{
            [self showRetryAlertWithError:error];
        }
    }];
}


- (void)getTopTwentyFiveAppsFromCachedData:(NSData*)cached
{
    NSDictionary* latestTopApps = [self fetchDataFromCached:cached];
    appsArray = [NSMutableArray arrayWithCapacity:10];

    if (latestTopApps) {
        for (NSDictionary* appsDict in latestTopApps) {

            App* app = [[App alloc] init];
            app.name = [appsDict valueForKeyPath:@"im:name.label"];
            app.summary = [appsDict valueForKeyPath:@"summary.label"];
            app.iconURL = [[[appsDict valueForKeyPath:@"im:image"] objectAtIndex:2] objectForKey:@"label"];
            app.appURL = [appsDict valueForKeyPath:@"link.attributes.href"];

            [appsArray addObject:app];
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

    NSDictionary* latestTopApps = [parsedData valueForKeyPath:@"feed.entry"];

    return latestTopApps;
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

    [nsDefaults setObject:data forKey:@"cachedData"];

    NSDate* date = [NSDate date];
    [nsDefaults setObject:date forKey:@"lastUpdated"];

    NSDictionary* latestTopApps = [parsedData valueForKeyPath:@"feed.entry"];

    dispatch_async(dispatch_get_main_queue(), ^{
        [self appTitleAndSubtitle];
    });

    return latestTopApps;
}

- (void)appTitleAndSubtitle
{
    UILabel* titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
    titleLabel.backgroundColor = [UIColor clearColor];
    titleLabel.textColor = [UIColor blackColor];
    titleLabel.font = [UIFont boldSystemFontOfSize:20];
    titleLabel.text = @"Top 25 Free Apps";
    [titleLabel sizeToFit];

    UILabel* subTitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 22, 0, 0)];
    subTitleLabel.backgroundColor = [UIColor clearColor];
    subTitleLabel.textColor = [UIColor blackColor];
    subTitleLabel.font = [UIFont systemFontOfSize:12];

    NSDate* updatedDate = [nsDefaults objectForKey:@"lastUpdated"];

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
    if (appsArray) {
        return [appsArray count];
    }

    return 0;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
    // Return the number of sections.
    if (appsArray) {

        self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
        return 1;
    }

    return 0;
}

- (void)tableView:(UITableView*)tableView
didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
    
    App *app = [appsArray objectAtIndex:indexPath.row];
    
    NSURL* url = [NSURL URLWithString:app.appURL];
    [[UIApplication sharedApplication] openURL:url];
    
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    CustomTableCell* cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];

    // Configure the cell...
    App* app = [appsArray objectAtIndex:indexPath.row];
    cell.appName.text = app.name;
    cell.appSummary.text = app.summary;

    NSURL* url = [NSURL URLWithString:app.iconURL];
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
        [self getTopTwentyFiveApps];
    }]];
    
    [self presentViewController:alertController animated:YES completion:nil];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
