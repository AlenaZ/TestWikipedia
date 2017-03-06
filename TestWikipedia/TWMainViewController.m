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
        [ApplicationDelegate.client getArticlesWithParameters:paramDic success:^(NSArray *resultArr) {
            self.articlesArr = [[NSArray alloc]initWithArray:resultArr];
            [self sortImagesByGroups];
            self.preloaderLabel.hidden = YES;
            [self.tableView reloadData];
            self.tableView.hidden = NO;
            self.preloaderLabel.text = @"Loading data...";
        } failure:^(NSString *errorString) {
            [self showAlertWithText:@"Error loading data"];
            self.preloaderLabel.text = @"Check Internet connection";
        }];
        self.lastLocation = self.currentLocation;
    }
}

#pragma mark - Sorting
- (void)sortImagesByGroups{
    NSMutableArray *arrNumbers = [[NSMutableArray alloc]init];
    NSMutableArray *arrOthers = [[NSMutableArray alloc]init];
    NSMutableDictionary *groupedImagesDic = [[NSMutableDictionary alloc]init];
    
    for (TWArticle *article in self.articlesArr) {
        if (article.pageImageStr.length) {
            NSString *firstLetter = [article.pageImageStr substringToIndex:1];
            unichar firstChar = [[firstLetter uppercaseString] characterAtIndex:0];
            if (firstChar >= 'A' && firstChar <= 'Z') {
                [self addString:article.pageImageStr toDic:groupedImagesDic forKey:firstLetter];
            }
            else if (firstChar >= '0' && firstChar <= '9'){
                [arrNumbers addObject:article.pageImageStr];
            }
            else{
                [arrOthers addObject:article.pageImageStr];
            }
        }
    }
    
    self.groupedImagesArr = [[NSMutableArray alloc]init];
    for (NSString *keyStr in groupedImagesDic) {
        [self addSpecialArr:[groupedImagesDic objectForKey:keyStr] withKey:keyStr];
    }
    
    NSSortDescriptor *sortByName = [NSSortDescriptor sortDescriptorWithKey:@"title" ascending:YES];
    NSArray *sortDescriptors = [NSArray arrayWithObject:sortByName];
    self.groupedImagesArr = [NSMutableArray arrayWithArray:[self.groupedImagesArr sortedArrayUsingDescriptors:sortDescriptors]];
    [self addSpecialArr:arrNumbers withKey:@"Numbers"];
    [self addSpecialArr:arrOthers withKey:@"Others"];
}

- (void)addString:(NSString *)str toDic:(NSMutableDictionary *)dic forKey:(NSString *)key{
    if ([dic objectForKey:key]) {
        NSMutableArray *tmpArr = [NSMutableArray arrayWithArray:[dic objectForKey:key]];
        [tmpArr addObject:str];
        [dic setObject:tmpArr forKey:key];
    }
    else{
        [dic setObject:@[str] forKey:key];
    }
}

- (void)addSpecialArr:(NSMutableArray *)arr withKey:(NSString *)keyStr{
    if (arr.count) {
        arr = [NSMutableArray arrayWithArray:[arr sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)]];
        [self.groupedImagesArr addObject:@{@"title":keyStr, @"images":arr}];
    }
}

#pragma mark - UITableView
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return self.groupedImagesArr.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    NSDictionary *dic = [self.groupedImagesArr objectAtIndex:section];
    NSArray *arr = [dic objectForKey:@"images"];
    return arr.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    NSDictionary *dic = [self.groupedImagesArr objectAtIndex:section];
    return [dic objectForKey:@"title"];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *identifierStr = @"GroupedImageCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifierStr];
    if (!cell) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifierStr];
    }
    
    NSDictionary *dic = [self.groupedImagesArr objectAtIndex:indexPath.section];
    NSArray *arr = [dic objectForKey:@"images"];
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

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
