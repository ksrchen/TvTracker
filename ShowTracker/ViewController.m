//
//  RWViewController.m
//  ShowTracker
//
//  Created by Joshua on 3/1/14.
//  Copyright (c) 2014 Ray Wenderlich. All rights reserved.
//

#import "ViewController.h"
#import "TraktAPIClient.h"
#import <AFNetworking/UIKit+AFNetworking.h>
#import <Nimbus/NIAttributedLabel.h>
#import <SAMCategories/UIScreen+SAMAdditions.h>

@interface ViewController ()

@end

@implementation ViewController

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.previousPage = -1;
    
    TraktAPIClient *client = [TraktAPIClient sharedClient];
    
    [client getShowsForDate:[NSDate date]
                   username:@"rwtestuser"
               numberOfDays:3
                    success:^(NSURLSessionDataTask *task, id responseObject) {
                        NSLog(@"Success -- %@", responseObject);
                        // Save response object
                        self.jsonResponse = responseObject;
                        
                        // Get the number of shows
                        NSInteger shows = 0;
                        for (NSString  *day in self.jsonResponse)
                        {
                            NSArray * showsRecord = self.jsonResponse[day];
                            shows += [showsRecord count];
                        }
                        // Set up page control
                        self.showsPageControl.numberOfPages = shows;
                        self.showsPageControl.currentPage = 0;
                        
                        // Set up scroll view
                        self.showsScrollView.contentSize = CGSizeMake(CGRectGetWidth(self.view.bounds) * shows, CGRectGetHeight(self.showsScrollView.frame));
                        
                        // Load first show
                        [self loadShow:0];
                    }
                    failure:^(NSURLSessionDataTask *task, NSError *error) {
                        NSLog(@"Failure -- %@", error);
                    }];
}

- (void)loadShow:(NSInteger)index
{
    // 1 - Find the show for the given index
    NSDictionary *show = nil;
    NSInteger shows = 0;
    NSDictionary *showDict;
    
    for (NSString *day in self.jsonResponse) {
        
        NSArray * showsRecord = self.jsonResponse[day];
        NSInteger count = [showsRecord count];
        
        // 2 - Did you find the right show?
        if (index < shows + count) {
            show = showsRecord[index - shows];
            showDict = show[@"show"];
            break;
        }
        
        // 3 - Increment the shows counter
        shows += count;
    }
    
    
    // 5 - Display the show title
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(index * CGRectGetWidth(self.showsScrollView.bounds) + 20, 40, CGRectGetWidth(self.showsScrollView.bounds) - 40, 40)];
    titleLabel.text = showDict[@"title"];
    titleLabel.backgroundColor = [UIColor clearColor];
    titleLabel.textColor = [UIColor whiteColor];
    titleLabel.font = [UIFont boldSystemFontOfSize:18];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    
    // 5.1 - Create formatted airing date
    static NSDateFormatter *formatter = nil;
    if (!formatter) {
        formatter = [[NSDateFormatter alloc] init];
        formatter.dateStyle = NSDateFormatterLongStyle;
        formatter.timeStyle = NSDateFormatterShortStyle;
        formatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"PST"];
    }
    
    NSDictionary *episodeDict = show[@"episode"];
    
    NSTimeInterval showAired = [episodeDict[@"first_aired_localized"] doubleValue];
    NSString *showDate = [formatter stringFromDate:[NSDate dateWithTimeIntervalSince1970: showAired]];
    
    // 5.2 - Create label to display episode info
    UILabel *episodeLabel = [[UILabel alloc] initWithFrame:CGRectMake(index * CGRectGetWidth(self.showsScrollView.bounds),
                                                                      360, CGRectGetWidth(self.showsScrollView.bounds), 40)];
    NSString* episode  = [NSString stringWithFormat:@"%02dx%02d - \"%@\"",
                          [[episodeDict valueForKey:@"season"] intValue],
                          [[episodeDict valueForKey:@"number"] intValue],
                          [episodeDict objectForKey:@"title"]];
    episodeLabel.text = [NSString stringWithFormat:@"%@\n%@", episode, showDate];
    episodeLabel.numberOfLines = 0;
    episodeLabel.textAlignment = NSTextAlignmentCenter;
    episodeLabel.textColor = [UIColor whiteColor];
    episodeLabel.backgroundColor = [UIColor clearColor];
    
    CGSize size = [episodeLabel sizeThatFits:CGSizeMake(CGRectGetWidth(self.view.frame),
                                                        CGRectGetHeight(self.view.frame) - CGRectGetMinY(episodeLabel.frame))];
    CGRect frame = episodeLabel.frame;
    frame.size.width = self.view.frame.size.width;
    frame.size.height = size.height;
    episodeLabel.frame = frame;
    
    [self.showsScrollView addSubview:episodeLabel];
    
    // 5.3 - Get image
    NSString *posterUrl = showDict[@"images"][@"poster"][@"medium"];
//    if ([[UIScreen mainScreen] sam_isRetina]) {
//        posterUrl = [posterUrl stringByReplacingOccurrencesOfString:@".jpg" withString:@"-300.jpg"];
//    } else {
//        posterUrl = [posterUrl stringByReplacingOccurrencesOfString:@".jpg" withString:@"-138.jpg"];
//    }
    
    // 5.4 - Display image using image view
    UIImageView *posterImage = [[UIImageView alloc] init];
    posterImage.frame = CGRectMake(index * CGRectGetWidth(self.showsScrollView.bounds) + 90, 105, 150, 225);
    [self.showsScrollView addSubview:posterImage];
    
    // 5.5 - Asynchronously load the image
    if (![posterUrl isKindOfClass:[NSNull class]])
    {
        [posterImage setImageWithURL:[NSURL URLWithString:posterUrl] placeholderImage:[UIImage imageNamed:@"placeholder.png"]];
    }
    
    // 6 - Add to scroll view
    [self.showsScrollView addSubview:titleLabel];
}

#pragma mark - Actions

- (IBAction)pageChanged:(id)sender
{
    // Set flag
    self.pageControlUsed = YES;
    
    // Get previous page number
    NSInteger page = self.showsPageControl.currentPage;
    self.previousPage = page;
    
    // Call loadShow for the new page
    [self loadShow:page];
    
    // Scroll scroll view to new page
    CGRect frame = self.showsScrollView.frame;
    frame.origin.x = frame.size.width * page;
    frame.origin.y = 0;
    [UIView animateWithDuration:.5 animations:^{
        [self.showsScrollView scrollRectToVisible:frame animated:NO];
    } completion:^(BOOL finished) {
        self.pageControlUsed = NO;
    }];
}

- (void)scrollViewDidScroll:(UIScrollView *)sender
{
    // Was the scrolling initiated via page control?
    if (self.pageControlUsed)
        return;
    
    // Figure out page to scroll to
    CGFloat pageWidth = sender.frame.size.width;
    NSInteger page = floor((sender.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
    
    // Do not do anything if we're trying to go beyond the available page range
    if (page == self.previousPage || page < 0 || page >= self.showsPageControl.numberOfPages)
        return;
    self.previousPage = page;
    
    // Set the page control page display
    self.showsPageControl.currentPage = page;
    
    // Load the page
    [self loadShow:page];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    self.pageControlUsed = NO;
}


@end
