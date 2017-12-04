//
//  ViewController.m
//  DigitalImageDemonstration
//
//  Created by liubo on 2017/11/29.
//  Copyright © 2017年 devliubo. All rights reserved.
//

#import "ViewController.h"

#define ViewControllerTitle @"DigitalImageDemonstration"

@interface ViewController ()<UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) NSArray *sections;
@property (nonatomic, strong) NSArray *classNames;
@property (nonatomic, strong) UITableView *tableView;

@end

@implementation ViewController

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return _sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_sections[section][1] count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return _sections[section][0];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *mainCellIdentifier = @"mainCellIdentifier";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:mainCellIdentifier];
    
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:mainCellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    cell.textLabel.text = _sections[indexPath.section][1][indexPath.row];
    
    cell.detailTextLabel.text = self.classNames[indexPath.section][indexPath.row];
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSString *className = self.classNames[indexPath.section][indexPath.row];
    
    UIViewController *subViewController = [[NSClassFromString(className) alloc] init];
    NSString *xibBundlePath = [[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"%@",className] ofType:@"xib"];
    if (xibBundlePath.length) {
        subViewController = [[NSClassFromString(className) alloc] initWithNibName:className bundle:nil];
    }
    
    subViewController.title = _sections[indexPath.section][1][indexPath.row];
    
    [self.navigationController pushViewController:subViewController animated:YES];
}

#pragma mark - Initialization

- (void)initTitles
{
    NSString *sec1Title = @"Core Motion";
    NSArray *sec1CellTitles = @[@"CoreMotionAndPanorama"];
    NSArray *section1 = @[sec1Title, sec1CellTitles];
    
    NSString *sec2Title = @"AVFoundation";
    NSArray *sec2CellTitles = @[@"CameraBufferToTexture"];
    NSArray *section2 = @[sec2Title, sec2CellTitles];
    
    self.sections = [NSArray arrayWithObjects:section1, section2, nil];
}

- (void)initClassNames
{
    NSArray *sec1ClassNames = @[@"CoreMotionAndPanorama"];
    
    NSArray *sec2ClassNames = @[@"CameraBufferToTexture"];
    
    self.classNames = [NSArray arrayWithObjects:sec1ClassNames, sec2ClassNames, nil];
}

- (void)initTableView
{
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    self.tableView.delegate   = self;
    self.tableView.dataSource = self;
    
    [self.view addSubview:self.tableView];
}

#pragma mark - Life Cycle

- (id)init
{
    if (self = [super init])
    {
        self.title = ViewControllerTitle;
        
        [self initTitles];
        
        [self initClassNames];
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self initTableView];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.navigationController.navigationBarHidden       = NO;
    self.navigationController.navigationBar.translucent = NO;
    self.navigationController.toolbarHidden             = YES;
}

@end
