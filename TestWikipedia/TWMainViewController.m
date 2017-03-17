//
//  TWMainViewController.m
//  TestWikipedia
//
//  Created by Alyona Zaikina on 03/03/2017.
//  Copyright © 2017 Alyona Zaikina. All rights reserved.
//

#import "TWMainViewController.h"
#import "TWArticle.h"

@interface TWMainViewController ()
@property (nonatomic, strong) NSMutableArray *groupedImagesArr;
@property (nonatomic, strong) NSMutableArray *levArr;
@property (nonatomic, strong) NSArray *articlesArr;
@property (strong, nonatomic) CLLocation *currentLocation;
@property (strong, nonatomic) CLLocation *lastLocation;
@property (strong, nonatomic) CLLocationManager *locationManager;
@property (assign, nonatomic) BOOL firstLoading;

@end

@implementation TWMainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    self.firstLoading = YES;
    
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    self.locationManager.distanceFilter = 1000;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    
    if ([self.locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
        [self.locationManager requestWhenInUseAuthorization];
    }
    
    self.articlesArr = [[NSMutableArray alloc]init];
    
    if (TARGET_IPHONE_SIMULATOR) {
        self.preloaderLabel.text = @"Choose your location, please";
    }
    [[AFNetworkReachabilityManager sharedManager] startMonitoring];
    [[AFNetworkReachabilityManager sharedManager] setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        switch (status) {
            case AFNetworkReachabilityStatusReachableViaWWAN:
                break;
            case AFNetworkReachabilityStatusReachableViaWiFi:
                if (self.firstLoading){
                    self.firstLoading = NO;
                    [self downloadData];
                }
                break;
            case AFNetworkReachabilityStatusNotReachable:
                self.firstLoading = YES;
                self.preloaderLabel.text = @"Check Internet connection";
                [self.locationManager stopUpdatingLocation];
                break;
            default:
                break;
        }
    }];
    
    [self downloadData];
}

- (void)viewWillAppear:(BOOL)animated{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self.locationManager startUpdatingLocation];
    });
}

- (void)viewDidDisappear:(BOOL)animated
{
    [self.locationManager stopUpdatingLocation];
}

#pragma mark - Data
- (void)downloadData{
    if (self.currentLocation) {
        NSDictionary *paramDic = @{@"latitude":[[NSString alloc] initWithFormat:@"%f", self.currentLocation.coordinate.latitude],
                                   @"longitude":[[NSString alloc] initWithFormat:@"%f", self.currentLocation.coordinate.longitude]};
        self.tableView.hidden = YES;
        self.preloaderLabel.hidden = NO;
        self.preloaderLabel.text = @"Loading data...";

        [ApplicationDelegate.client getArticlesWithParameters:paramDic success:^(NSArray *resultArr) {
            self.articlesArr = [[NSArray alloc]initWithArray:resultArr];
            self.groupedImagesArr = [[NSMutableArray alloc]init];
            [self sortingArray];
            self.preloaderLabel.hidden = YES;
            [self.tableView reloadData];
            self.tableView.hidden = NO;
        } failure:^(NSString *errorString) {
            [self showAlertWithText:@"Error loading data"];
            self.preloaderLabel.text = @"Check Internet connection";
        }];
        self.lastLocation = self.currentLocation;
    }
}

#pragma mark - UITableView
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return self.groupedImagesArr.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    NSArray *arr = [self.groupedImagesArr objectAtIndex:section];
    return arr.count;

}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    return [NSString stringWithFormat:@"%ld group",(long)section + 1];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *identifierStr = @"GroupedImageCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifierStr];
    if (!cell) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifierStr];
    }
    
    NSArray *arr = [self.groupedImagesArr objectAtIndex:indexPath.section];
    cell.textLabel.text = [arr objectAtIndex:indexPath.row];

    return cell;
}

#pragma mark - Location Manager
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    self.currentLocation = [locations lastObject];
    if ((self.currentLocation != self.lastLocation) || self.firstLoading){
        self.firstLoading = NO;
        [self downloadData];
    }
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied){
        NSLog(@"User has denied location services");
        self.preloaderLabel.text = @"Allow access to your location, please";
    }
}

#pragma mark - Alert
- (void)showAlertWithText:(NSString *)textStr{
    UIAlertController * alert = [UIAlertController
                                 alertControllerWithTitle:nil
                                 message:textStr
                                 preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){
        [alert dismissViewControllerAnimated:YES completion:nil];
    }];
    [alert addAction:okAction];
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - Sorting
- (void)sortingArray{
    NSMutableArray *sortingArr = [[NSMutableArray alloc]init];
    NSMutableArray *namesTmpArr = [[NSMutableArray alloc]initWithArray:self.articlesArr];
    self.levArr = [[NSMutableArray alloc]initWithArray:namesTmpArr];
    NSDictionary *dic = [self findLevArrFor];
    int max = [[dic objectForKey:@"max"] intValue];
    int k = [[dic objectForKey:@"min"] intValue];
    
    while (namesTmpArr.count > 2) {
        
        BOOL find = NO;
        
        while ((k <= max) && !find) {
            NSMutableArray *tmpArrOccurrences = [[NSMutableArray alloc]init];
            for (int i = 0; i < self.levArr.count; i++) {
                int occurrences = 0;
                
                NSArray *arrNumbers = [self.levArr objectAtIndex:i];
                for (int j = 0; j < arrNumbers.count; j++) {
                    NSNumber *number = [arrNumbers objectAtIndex:j];
                    if (i != j) {
                        occurrences += ([number intValue] == k?1:0);
                    }
                }
                
                if (occurrences != 0) {
                    find = YES;
                }
                [tmpArrOccurrences addObject:[NSNumber numberWithInt:occurrences]];
                occurrences = 0;
            }
            
            if (find) {
                NSNumber *maxOfK = [tmpArrOccurrences valueForKeyPath:@"@max.self"];
                NSUInteger index = [tmpArrOccurrences indexOfObject:maxOfK];
                NSArray *arrNumbers = [self.levArr objectAtIndex:index];
                NSMutableArray *arrDeleteIndex = [[NSMutableArray alloc]init];
                NSMutableArray *arr = [[NSMutableArray alloc]init];
                
                for (int m = 0; m < arrNumbers.count; m++) {
                    NSNumber *num = [arrNumbers objectAtIndex:m];
                    if (m != index) {
                        if ([num intValue] == k) {
                            [sortingArr addObject:namesTmpArr[m]];
                            [arrDeleteIndex addObject:[NSNumber numberWithInt:m]];
                        }
                        else{
                            [arr addObject:[namesTmpArr objectAtIndex:m]];
                        }
                    }
                }
                
                [sortingArr addObject:namesTmpArr[index]];
                [self.groupedImagesArr addObject:[[NSArray alloc]initWithArray:sortingArr]];
                [sortingArr removeAllObjects];
                
                namesTmpArr = [[NSMutableArray alloc]initWithArray:arr];
                
                [arrDeleteIndex addObject:[NSNumber numberWithUnsignedInteger:index]];
                NSSortDescriptor *highestToLowest = [NSSortDescriptor sortDescriptorWithKey:@"self" ascending:YES];
                [arrDeleteIndex sortUsingDescriptors:[NSArray arrayWithObject:highestToLowest]];
                
                for (int i = 0; i < self.levArr.count; i++) {
                    NSMutableArray *arrNumbersTmp = [[NSMutableArray alloc]initWithArray:[self.levArr objectAtIndex:i]];
                    for (int j = 0; j < arrDeleteIndex.count; j++) {
                        int delIndex = [arrDeleteIndex[j] intValue] - j;
                        [arrNumbersTmp removeObjectAtIndex:delIndex];
                    }
                    
                    [self.levArr replaceObjectAtIndex:i withObject:[[NSMutableArray alloc]initWithArray:arrNumbersTmp]];
                }
                
                for (int j = 0; j < arrDeleteIndex.count; j++){
                    int delIndex = [arrDeleteIndex[j] intValue] - j;
                    [self.levArr removeObjectAtIndex:delIndex];
                }
            }
            
            k++;
        }
    }
    
    if (namesTmpArr.count) {
        for (int i = 0; i < namesTmpArr.count; i++){
            [sortingArr addObject:namesTmpArr[i]];
        }
        [self.groupedImagesArr addObject:[[NSArray alloc]initWithArray:sortingArr]];
    }
}

- (NSDictionary *)findLevArrFor{
    NSMutableArray *arr = [[NSMutableArray alloc]init];
    int max = 0;
    int min = 0;
    for (int i = 0; i < self.levArr.count; i++) {
        NSMutableArray *tmpArr = [[NSMutableArray alloc]init];
        for (int j = 0; j < self.levArr.count; j++) {
            NSNumber *tmpNum = [self levenshteinDistanceWith:self.levArr[i] withString:self.levArr[j]];
            if (max < [tmpNum intValue]) {
                max = [tmpNum intValue];
            }
            if (min > [tmpNum intValue]) {
                min = [tmpNum intValue];
            }
            [tmpArr addObject:tmpNum];
        }
        [arr addObject:tmpArr];
    }
    
    self.levArr = [[NSMutableArray alloc]initWithArray:arr];
    
    return @{@"max":[NSNumber numberWithInt:max],@"min":[NSNumber numberWithInt:min]};
}

- (NSNumber *)levenshteinDistanceWith:(NSString *)firstString withString:(NSString *)secondString{
    [firstString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    [secondString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    firstString = [firstString lowercaseString];
    secondString = [secondString lowercaseString];
    
    NSInteger * d;
    
    NSInteger n = [firstString length];
    NSInteger m = [secondString length];
    
    if( (n != 0) && (m != 0) ) {
        
        n++;
        m++;
        
        d = malloc( sizeof(NSInteger) * m * n );
        
        for(int k = 0; k < n; k++)
            d[k] = k;
        
        for(int k = 0; k < m; k++)
            d[ k * n ] = k;
        
        for(int i = 1; i < n; i++ )
            for(int j = 1; j < m; j++ ) {
                int cost;
                if( [firstString characterAtIndex: i-1] == [secondString characterAtIndex: j-1] )
                    cost = 0;
                else
                    cost = 1;
                
                d[ j * n + i ] = MIN(d [ (j - 1) * n + i ] + 1,
                                     MIN(d[ j * n + i - 1 ] +  1, d[ (j - 1) * n + i - 1 ] + cost));
                
                if( (i > 1) &&
                   (j > 1) &&
                   ([firstString characterAtIndex: i-1] == [secondString characterAtIndex: j-2]) &&
                   ([firstString characterAtIndex: i-2] == [secondString characterAtIndex: j-1]) )
                {
                    d[ j * n + i] = MIN(d[ j * n + i ], d[ (j - 2) * n + i - 2 ] + cost);
                }
            }
        
        float distance = d[ n * m - 1 ];
        
        free( d );
        
        return [NSNumber numberWithFloat:distance];
    }
    return [NSNumber numberWithInt:0];
}

@end
