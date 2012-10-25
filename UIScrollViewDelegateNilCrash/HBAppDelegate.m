//
//  HBAppDelegate.m
//  UIScrollViewDelegateNilCrash
//
//  Created by dev1 on 10/25/12.
//  Copyright (c) 2012 Heath Borders. All rights reserved.
//

#import "HBAppDelegate.h"

/*
 *
 *
 *
 * Switch to
 * WORKAROUND 1
 * to demonstrate the workaround
 *
 *
 */

#define WORKAROUND 0

@interface ScrollViewDelegate : NSObject<UIScrollViewDelegate>

@property (nonatomic, strong) UIScrollView *scrollView;

- (id) initWithScrollView:(UIScrollView *)scrollView;

@end

@implementation ScrollViewDelegate

- (id) initWithScrollView:(UIScrollView *)scrollView {
    self = [super init];
    if (self) {
        self.scrollView = scrollView;
        self.scrollView.delegate = self;
    }

    return self;
}

- (void) dealloc {
#if WORKAROUND
    self.scrollView.delegate = nil;
#endif
    
    NSLog(@"%@ dealloced", self);
}

@end

@interface ScrollViewController : UIViewController<UIScrollViewDelegate>

@property (nonatomic, readonly) UIScrollView *scrollView;
@property (nonatomic, strong) ScrollViewDelegate *scrollViewDelegate;
@property (nonatomic) BOOL disappeared;
@property (nonatomic, copy) void (^setContentOffsetBlock)(void);

@end

@implementation ScrollViewController

- (void) dealloc {
    NSLog(@"%@ dealloced", self);
}

- (void) loadView {
    self.view = [UIScrollView new];
    self.scrollView.contentSize = CGSizeMake(2000, 4000);

    self.scrollViewDelegate = [[ScrollViewDelegate alloc] initWithScrollView:self.scrollView];

    UILabel *pushBackLabel = [[UILabel alloc] initWithFrame:CGRectMake(200, 1000, 200, 200)];
    pushBackLabel.text = @"Push Back";
    [self.scrollView addSubview:pushBackLabel];
}

- (void) viewDidAppear:(BOOL)animated {
    [self.scrollView setContentOffset:CGPointMake(0, 1000)
                             animated:YES];

    [super viewDidAppear:animated];
}

- (void) viewWillDisappear:(BOOL)animated {
    __weak ScrollViewController *weakSelf = self;
    self.setContentOffsetBlock = ^{
        if (weakSelf && !weakSelf.disappeared) {
            [weakSelf.scrollView setContentOffset:CGPointZero
                                         animated:YES];
            dispatch_async(dispatch_get_main_queue(),
                           weakSelf.setContentOffsetBlock);
        }
    };
    self.setContentOffsetBlock();

    [super viewWillDisappear:animated];
}

- (void) viewDidDisappear:(BOOL)animated {
    self.disappeared = YES;
    
    [super viewDidDisappear:animated];
}

- (UIScrollView *) scrollView {
    return (UIScrollView *) self.view;
}

@end

@interface PushScrollViewController : UIViewController

@property (nonatomic, unsafe_unretained) ScrollViewController *scrollViewController;

@end

@implementation PushScrollViewController

- (void) loadView {
    UIButton *pushScrollViewControllerButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [pushScrollViewControllerButton addTarget:nil
                                       action:@selector(pushScrollViewControllerButtonTouchUpInside)
                             forControlEvents:UIControlEventTouchUpInside];
    [pushScrollViewControllerButton setTitle:@"Push"
                                    forState:UIControlStateNormal];

    self.view = pushScrollViewControllerButton;
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [self.scrollViewController.scrollView setContentOffset:CGPointMake(0,
                                                                       1000)
                                                  animated:YES];
}

- (void) pushScrollViewControllerButtonTouchUpInside {
    ScrollViewController *scrollViewController = [ScrollViewController new];
    self.scrollViewController = scrollViewController;
    [self.navigationController pushViewController:scrollViewController
                                         animated:YES];
}

@end

@interface HBAppDelegate()

@end

@implementation HBAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor whiteColor];

    PushScrollViewController *pushScrollViewController = [PushScrollViewController new];
    self.window.rootViewController = [[UINavigationController alloc] initWithRootViewController:pushScrollViewController];

    [self.window makeKeyAndVisible];
    return YES;
}

@end
