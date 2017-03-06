//
//  TWHTTPClient.h
//  TestWikipedia
//
//  Created by Alyona Zaikina on 03/03/2017.
//  Copyright © 2017 Alyona Zaikina. All rights reserved.
//

#import <AFNetworking/AFNetworking.h>

@interface TWHTTPClient : AFHTTPSessionManager

+ (TWHTTPClient *)sharedHTTPClient;
@property (strong, nonatomic) AFHTTPRequestOperationManager *manager;

- (void)getArticlesWithParameters:(NSDictionary *)paramDic
                          success:(void(^)(NSArray *resultArr))success
                          failure:(void(^)(NSString *errorString))failure;

@end
