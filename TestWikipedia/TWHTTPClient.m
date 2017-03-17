//
//  TWHTTPClient.m
//  TestWikipedia
//
//  Created by Alyona Zaikina on 03/03/2017.
//  Copyright © 2017 Alyona Zaikina. All rights reserved.
//

#import "TWHTTPClient.h"
#import "TWJSONToObjectTransformer.h"

static NSString * const baseUrlStr = @"https://en.wikipedia.org//w/";

@implementation TWHTTPClient

+ (TWHTTPClient *)sharedHTTPClient{
    static TWHTTPClient *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[self alloc]initWithBaseURL:[NSURL URLWithString:baseUrlStr]];
        shared.manager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:[NSURL URLWithString:baseUrlStr]];
    });
    return shared;
}

- (instancetype)initWithBaseURL:(NSURL *)url
{
    self = [super initWithBaseURL:url];
    
    if (self) {
        self.responseSerializer = [AFJSONResponseSerializer serializer];
        self.requestSerializer = [AFJSONRequestSerializer serializer];
        self.manager.responseSerializer = [AFJSONResponseSerializer serializer];
        self.manager.requestSerializer = [AFJSONRequestSerializer serializer];
        self.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"text/html", @"application/json", nil];
        self.manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/json", @"text/javascript",@"text/html",@"text/plain", nil];
        
        self.securityPolicy.allowInvalidCertificates = YES;
        
    }
    return self;
}

- (void)getArticlesWithParameters:(NSDictionary *)paramDic
                          success:(void(^)(NSArray *resultArr))success
                          failure:(void(^)(NSString *errorString))failure{
    
    NSString *locationStr = [NSString stringWithFormat:@"%@|%@",
                          [paramDic objectForKey:@"latitude"],
                          [paramDic objectForKey:@"longitude"]];
    
    NSString *itemsCount = @"50";
    NSDictionary *parametersDic = @{@"action":@"query",
                                    @"format":@"json",
                                    @"prop":@"pageimages|pageterms|images",
                                    @"imlimit":@"500",
                                    @"generator":@"geosearch",
                                    @"piprop":@"name",
                                    @"pilimit":itemsCount,
                                    @"wbptterms":@"description",
                                    @"ggscoord":locationStr,
                                    @"ggsradius":@"10000",
                                    @"ggslimit":itemsCount
                                    };
    
    [self.manager POST:@"api.php" parameters:parametersDic success:^(AFHTTPRequestOperation *operation, id responseObject){
        NSArray *articlesArr = [TWJSONToObjectTransformer getImagesNamesFromJSONArray:responseObject];
        success(articlesArr);
    }failure:^(AFHTTPRequestOperation *operation, NSError *error){
        failure(error.localizedDescription);
    }];
}

@end
