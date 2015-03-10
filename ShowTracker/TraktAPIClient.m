//
//  TraktAPIClient.m
//  ShowTracker
//
//  Created by Kevin Chen on 2/28/15.
//  Copyright (c) 2015 Ray Wenderlich. All rights reserved.
//
#import "TraktAPIClient.h"

// Set this to your Trakt API Key
NSString * const kTraktAPIKey = @"bbf08b241f55f76bb90156f606c2479ca991ce7a25e16d0a88e345e5afb358b3";
NSString * const kTraktBaseURLString = @"http://api-v2launch.trakt.tv";

@implementation TraktAPIClient

+ (TraktAPIClient *)sharedClient {
    static TraktAPIClient *_sharedClient = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        _sharedClient = [[self alloc] initWithBaseURL:[NSURL URLWithString:kTraktBaseURLString]];
    });
    
    return _sharedClient;
}

- (instancetype)initWithBaseURL:(NSURL *)url {
    
    self = [super initWithBaseURL:url];
    if (!self) {
        return nil;
    }
    
    self.responseSerializer = [AFJSONResponseSerializer serializer];
    self.requestSerializer = [AFJSONRequestSerializer serializer];
    
    [self.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Content-Type'"];
    [self.requestSerializer setValue:@"2" forHTTPHeaderField:@"trakt-api-version"];
    [self.requestSerializer setValue:@"bbf08b241f55f76bb90156f606c2479ca991ce7a25e16d0a88e345e5afb358b3" forHTTPHeaderField:@"trakt-api-key"];
    [self.requestSerializer setValue:@"Bearer 0f6c3ef1eece9ae7e3ce3568fec0219a0d81e66d115561307edcf7a0aa3f0c17" forHTTPHeaderField:@"Authorization"];

    return self;
}

- (void)getShowsForDate:(NSDate *)date
               username:(NSString *)username
           numberOfDays:(int)numberOfDays
                success:(void(^)(NSURLSessionDataTask *task, id responseObject))success
                failure:(void(^)(NSURLSessionDataTask *task, NSError *error))failure
{
    NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyy-MM-dd";
    NSString* dateString = [formatter stringFromDate:date];
    
    NSString* path = [NSString stringWithFormat:@"calendars/shows/%@/%d?extended=images",
                    dateString, numberOfDays];
    
    [self GET:path parameters:nil success:^(NSURLSessionDataTask *task, id responseObject) {
        if (success) {
            success(task, responseObject);
        }
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        if (failure) {
            failure(task, error);
        }
    }];
}

@end