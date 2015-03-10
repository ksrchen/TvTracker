//
//  TraktAPIClient.h
//  ShowTracker
//
//  Created by Kevin Chen on 2/28/15.
//  Copyright (c) 2015 Ray Wenderlich. All rights reserved.
//

#import <AFNetworking/AFNetworking.h>


extern NSString * const kTraktAPIKey;
extern NSString * const kTraktBaseURLString;


@interface TraktAPIClient : AFHTTPSessionManager


+ (TraktAPIClient *)sharedClient;


- (void)getShowsForDate:(NSDate *)date
               username:(NSString *)username
           numberOfDays:(int)numberOfDays
                success:(void(^)(NSURLSessionDataTask *task, id responseObject))success
                failure:(void(^)(NSURLSessionDataTask *task, NSError *error))failure;

@end