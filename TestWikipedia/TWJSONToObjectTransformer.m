//
//  TWJSONToObjectTransformer.m
//  TestWikipedia
//
//  Created by Alyona Zaikina on 03/03/2017.
//  Copyright © 2017 Alyona Zaikina. All rights reserved.
//

#import "TWJSONToObjectTransformer.h"
#import "TWArticle.h"

@implementation TWJSONToObjectTransformer

+ (NSArray *)getImagesNamesFromJSONArray:(id)jsonObject{
    NSMutableArray *imagesNamesArr = [[NSMutableArray alloc]init];
    NSDictionary *articlesJSONDic = (NSDictionary*) jsonObject;
    NSDictionary *queryDic = [articlesJSONDic objectForKey:@"query"];
    NSDictionary *pagesDic = [queryDic objectForKey:@"pages"];
    NSMutableArray *allKeys = [[pagesDic allKeys] mutableCopy];
    
    for(NSString *key in allKeys){
        NSDictionary *articleDict = [pagesDic objectForKey:key];
        if ([articleDict objectForKey:@"images"]) {
            NSArray *arr = [articleDict objectForKey:@"images"];
            for (NSDictionary *dic in arr) {
                NSString *titleStr = [dic objectForKey:@"title"];
                if ([titleStr containsString:@"File:"]) {
                    titleStr = [titleStr stringByReplacingOccurrencesOfString:@"File:" withString:@""];
                }
                [imagesNamesArr addObject:titleStr];
            }
        }
    }
    
    return imagesNamesArr;
}

@end
