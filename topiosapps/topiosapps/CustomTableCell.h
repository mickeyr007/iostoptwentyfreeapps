//
//  ViewController.h
//  topiosapps
//
//  Created by Mickey on 3/20/16.
//  Copyright © 2016 Mickey Raj. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CustomTableCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *appName;
@property (weak, nonatomic) IBOutlet UILabel *appSummary;
@property (strong, nonatomic) IBOutlet UIImageView *appIcon;

@end