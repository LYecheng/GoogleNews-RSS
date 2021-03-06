//
//  MasterViewController.m
//  Google News RSS
//
//  Created by Yecheng Li on 02/11/15.
//  Copyright (c) 2015 Yecheng Li. All rights reserved.
//


#import "MasterViewController.h"
#import "SharedNetworking.h"
#import "MasterCell.h"
#import "Article.h"

@interface MasterViewController ()

@property NSDictionary* links;
@property (nonatomic, strong) NSMutableArray *objects;

@end


@implementation MasterViewController

- (void)awakeFromNib {
    [super awakeFromNib];

    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        self.clearsSelectionOnViewWillAppear = NO;
        self.preferredContentSize = CGSizeMake(320.0, 600.0);
    }
}

- (void)viewWillAppear:(BOOL)animated{
    self.tableView.estimatedRowHeight = 100;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
}

- (void)viewDidLoad {
    
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.detailViewController = (DetailViewController *)[[self.splitViewController.viewControllers lastObject] topViewController];
    [self downloadDataFromWeb];
    
    UIRefreshControl *pullToRefresh = [[UIRefreshControl alloc] init];
    pullToRefresh.tintColor = [UIColor magentaColor];
    [pullToRefresh addTarget:self action:@selector(refreshAction)
            forControlEvents:UIControlEventValueChanged];
    self.refreshControl = pullToRefresh;
    
    // last view page
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSData *articleData = [defaults objectForKey:@"lastItem"];
    Article *article = [NSKeyedUnarchiver unarchiveObjectWithData:articleData];
    NSString *URL = [defaults objectForKey:@"lastUrl"];
    
    if (URL == nil) {
        URL = @"http://news.google.com";
    }
    else{
        [self.detailViewController setItem:article];
    }
    [self.detailViewController setUrl:URL];

    BOOL nightMode = [[NSUserDefaults standardUserDefaults] boolForKey:@"enabled_nightmode"];
    if (nightMode == true) {
        self.tableView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.6];
    }
    
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self
               selector:@selector(stateChanged)
                   name:UIContentSizeCategoryDidChangeNotification
                 object:nil];
    [center addObserver:self
               selector:@selector(stateChanged)
                   name:NSUserDefaultsDidChangeNotification
                 object:nil];
}

-(void)stateChanged{
    
    [self.tableView reloadData];
    BOOL nightMode = [[NSUserDefaults standardUserDefaults] boolForKey:@"enabled_nightmode"];
    UINavigationController *navigationController = (UINavigationController *)self.parentViewController;
    UINavigationController *detailNavigationController = (UINavigationController *)self.detailViewController.parentViewController;
    if (nightMode == true) {
        [navigationController.navigationBar setTintColor:[UIColor whiteColor]];
        [navigationController.navigationBar setBarStyle:UIBarStyleBlackTranslucent];
        [navigationController.navigationBar setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                    [UIColor whiteColor], NSForegroundColorAttributeName,
                                                                    [UIFont fontWithName:@"HelveticaNeue-Light" size:20.0], NSFontAttributeName,nil]];
        [navigationController.navigationBar setNeedsDisplay];
        
        
        [detailNavigationController.navigationBar setBarStyle:UIBarStyleBlackTranslucent];
        [detailNavigationController.navigationBar setTintColor:[UIColor whiteColor]];
        [detailNavigationController.navigationBar setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                          [UIColor whiteColor], NSForegroundColorAttributeName,
                                                                          [UIFont fontWithName:@"HelveticaNeue-Light" size:20.0], NSFontAttributeName,nil]];
        [detailNavigationController.navigationBar setNeedsDisplay];
        
        [detailNavigationController.toolbar setBarStyle:UIBarStyleBlackTranslucent];
        [detailNavigationController.toolbar setTintColor:[UIColor whiteColor]];
        [detailNavigationController.toolbar setNeedsDisplay];
        self.tableView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.6];
        [self.tableView reloadData];
    }
    else {
        self.tableView.backgroundColor = [UIColor colorWithWhite:1 alpha:0.6];
        [navigationController.navigationBar setTintColor:[UIColor blueColor]];
        [navigationController.navigationBar setBarStyle:UIBarStyleDefault];
        [navigationController.navigationBar setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                    [UIColor blackColor], NSForegroundColorAttributeName,
                                                                    [UIFont fontWithName:@"HelveticaNeue-Light" size:20.0], NSFontAttributeName,nil]];
        [detailNavigationController.navigationBar setNeedsDisplay];
        [detailNavigationController.navigationBar setTintColor:[UIColor colorWithRed:0 green:0.4 blue:0.4 alpha:1.0]];
        
        [detailNavigationController.navigationBar setBarStyle:UIBarStyleDefault];
        [detailNavigationController.navigationBar setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                          [UIColor blackColor], NSForegroundColorAttributeName,
                                                                          [UIFont fontWithName:@"HelveticaNeue-Light" size:20.0], NSFontAttributeName,nil]];
        [detailNavigationController.navigationBar setNeedsDisplay];
        
        [detailNavigationController.toolbar setBarStyle:UIBarStyleDefault];
        [detailNavigationController.toolbar setTintColor:[UIColor colorWithRed:0 green:0.4 blue:0.4 alpha:1.0]];
        [detailNavigationController.toolbar setNeedsDisplay];
        
        [self.tableView reloadData];
    }
}


-(void)downloadDataFromWeb{
    
    [[SharedNetworking sharedSharedWorking]getFeedForURL:nil
                                                 success:^(NSDictionary *dictionary, NSError *error){
                                                     self.links = dictionary[@"responseData"][@"feed"][@"entries"];
                                                     
                                                     if (self.objects == nil) {
                                                         self.objects = [[NSMutableArray alloc]init];
                                                     }
                                                     
                                                     [self.objects removeAllObjects];
                                                     for (NSDictionary *link in self.links) {
                                                         Article *article = [[Article alloc]init];
                                                         article.title = [link objectForKey:@"title"];
                                                         article.publishedDate = [link objectForKey:@"publishedDate"];
                                                         article.contentSnippet = [link objectForKey:@"contentSnippet"];
                                                         article.link = [link objectForKey:@"link"];
                                                         [self.objects addObject:article];
                                                     }
                                                     
                                                     dispatch_async(dispatch_get_main_queue(), ^{
                                                         [self.tableView reloadData];
                                                         [[NSNotificationCenter defaultCenter] postNotificationName:@"tableViewdidLoad" object:self];
                                                     });
                                                 }failure:^{
                                                     dispatch_async(dispatch_get_main_queue(), ^{
                                                         NSLog(@"Error");
                                                     });
                                                 }];
    
}


- (void)refreshAction {
    [self downloadDataFromWeb];
    
    [self.tableView reloadData];
    [self.refreshControl endRefreshing];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"showDetail"]) {
        
        if(![SharedNetworking isNetworkAvailable])
        {
            return;
        }
        
        DetailViewController *controller = (DetailViewController *)[[segue destinationViewController] topViewController];
        controller.navigationItem.leftBarButtonItem = self.splitViewController.displayModeButtonItem;
        controller.navigationItem.leftItemsSupplementBackButton = YES;
        
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        
        Article * issueItem = [self.objects objectAtIndex:indexPath.row];
        NSString *link = issueItem.link;
        [controller setUrl:link];
        [controller setItem:issueItem];
    }
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return self.objects.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    MasterCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MasterCell" forIndexPath:indexPath];
    
    BOOL nightMode = [[NSUserDefaults standardUserDefaults] boolForKey:@"enabled_nightmode"];
    if (nightMode == true) {
        cell.backgroundColor = [UIColor clearColor];
        cell.itemDate.textColor = [UIColor lightGrayColor];
        cell.itemTitle.textColor = [UIColor whiteColor];
        cell.itemSnippet.textColor = [UIColor whiteColor];
    }
    else {
        cell.backgroundColor = [UIColor whiteColor];
        cell.itemDate.textColor = [UIColor darkGrayColor];
        cell.itemTitle.textColor = [UIColor blackColor];
        cell.itemSnippet.textColor = [UIColor blackColor];
    }
    
    self.issue = [self.objects objectAtIndex:indexPath.row];
    cell.itemTitle.text = self.issue.title;
    cell.itemSnippet.text = self.issue.contentSnippet;
    
    NSDateFormatter *dateformat = [[NSDateFormatter alloc]init];
    [dateformat setDateFormat:@"eee, dd MMM yyyy HH:mm:ss ZZZZ"];
    NSDate *publishDate = [dateformat dateFromString:self.issue.publishedDate];
    
    [dateformat setDateFormat:@"MM-dd-yyyy"];
    NSString *date = [dateformat stringFromDate:publishDate];
    cell.itemDate.text = date;
    
    cell.itemTitle.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    cell.itemDate.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    cell.itemSnippet.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    [cell layoutIfNeeded];
    
    return cell;
}


@end
