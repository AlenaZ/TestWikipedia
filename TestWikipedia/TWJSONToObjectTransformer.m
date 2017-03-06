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

+ (NSArray *)transformArticleFromJSONArray:(id)jsonObject{
    NSMutableArray *articles = [[NSMutableArray alloc]init];
    NSDictionary *articlesJSONDic = (NSDictionary*) jsonObject;
    NSDictionary *queryDic = [articlesJSONDic objectForKey:@"query"];
    NSDictionary *pagesDic = [queryDic objectForKey:@"pages"];
    NSMutableArray *allKeys = [[pagesDic allKeys] mutableCopy];
    
    for(NSString *key in allKeys){
        NSDictionary *articleDict = [pagesDic objectForKey:key];        
        if ([articleDict objectForKey:@"pageimage"]) {
            TWArticle *article = [[TWArticle alloc]init];
            article.pageImageStr = [articleDict objectForKey:@"pageimage"];
            [articles addObject:article];
        }
    }
    
    return articles;
}

@end
