//
//  ViewController.m
//  topiosapps
//
//  Created by Mickey on 3/20/16.
//  Copyright © 2016 Mickey Raj. All rights reserved.
//

#import "TableViewController.h"
#import "CustomTableCell.h"
#import "App.h"

#define kTopTwentyFiveAppsURL  [NSURL URLWithString:@"http://ax.itunes.apple.com/WebObjects/MZStoreServices.woa/ws/RSS/topfreeapplications/limit=25/json"]

@interface TableViewController ()
{
    NSMutableArray *appsArray;
}
@end

@implementation TableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self appTitleAndSubtitle];
    [self getTopTwentyFiveApps];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)getTopTwentyFiveApps
{
    [NSURLConnection sendAsynchronousRequest:[[NSURLRequest alloc] initWithURL:kTopTwentyFiveAppsURL] queue:[[NSOperationQueue alloc] init] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        
        if (!error) {
            NSDictionary *latestTopApps = [self fetchData:data];
            appsArray = [NSMutableArray arrayWithCapacity:10];
            
            if (latestTopApps) {
                for (NSDictionary *appsDict in latestTopApps) {
                    
                    App *app = [[App alloc] init];
                    app.name = [appsDict valueForKeyPath:@"im:name.label"];
                    app.summary = [appsDict valueForKeyPath:@"summary.label"];
                    app.iconURL = [[[appsDict valueForKeyPath:@"im:image"] objectAtIndex:2] objectForKey:@"label"];
                    app.appURL=[appsDict valueForKeyPath:@"link.attributes.href"];
                    
                    [appsArray addObject:app];
                }
            }
            [self performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
            
        }
    }];
}

- (void)reloadData
{
    // Reload table data
    [self.tableView reloadData];
}

- (NSDictionary *)fetchData:(NSData *)response
{
    
    NSError *jsonError = nil;
    NSDictionary *parsedData = [NSJSONSerialization JSONObjectWithData:response options:0 error:&jsonError];
    
    if (jsonError) {
        return nil;
    }
   
    NSDictionary* latestTopApps = [parsedData valueForKeyPath:@"feed.entry"];
  
    
    return latestTopApps;
}

-(void)appTitleAndSubtitle
{
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
    titleLabel.backgroundColor = [UIColor clearColor];
    titleLabel.textColor = [UIColor blackColor];
    titleLabel.font = [UIFont boldSystemFontOfSize:20];
    titleLabel.text = @"Top 25 Free Apps";
    [titleLabel sizeToFit];
 
    UILabel *subTitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 22, 0, 0)];
    subTitleLabel.backgroundColor = [UIColor clearColor];
    subTitleLabel.textColor = [UIColor blackColor];
    subTitleLabel.font = [UIFont systemFontOfSize:12];
    subTitleLabel.text=@"updated date";
   
    [subTitleLabel sizeToFit];
    
    UIView *twoLineTitleView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, MAX(subTitleLabel.frame.size.width, titleLabel.frame.size.width), 30)];
    [twoLineTitleView addSubview:titleLabel];
    [twoLineTitleView addSubview:subTitleLabel];
    
    float widthDiff = subTitleLabel.frame.size.width - titleLabel.frame.size.width;
    
    if (widthDiff > 0) {
        CGRect frame = titleLabel.frame;
        frame.origin.x = widthDiff / 2;
        titleLabel.frame = CGRectIntegral(frame);
    }else{
        CGRect frame = subTitleLabel.frame;
        frame.origin.x = abs(widthDiff) / 2;
        subTitleLabel.frame = CGRectIntegral(frame);
    }
    
    self.navigationItem.titleView = twoLineTitleView;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    if (appsArray) {
        return [appsArray count];
    }
    
    return 0;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    if (appsArray) {
        
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
        return 1;
        
    }
    
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CustomTableCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    
    // Configure the cell...
    App *app = [appsArray objectAtIndex:indexPath.row];
    cell.appName.text = app.name;
    cell.appSummary.text = app.summary;
    
    
    

    
    return cell;
}


@end
