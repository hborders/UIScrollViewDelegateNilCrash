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
 * Switch to
 * WORKAROUND 1
 * to demonstrate the workaround
 *
 * Switch to USE_ARC 0
 * to demonstrate NSZombieEnabled finding the problem.
 *
 */

#define NORMAL_USAGE 1
#define WORKAROUND 0


@implementation LoggingScrollView

- (void) dealloc {
    NSLog(@"%@ dealloced", self);

#if !__has_feature(objc_arc)
    [super dealloc];
#endif
}

@end

@interface ScrollViewDelegate : NSObject<UIScrollViewDelegate>

@property (nonatomic, retain) UIScrollView *scrollView;

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

#if !__has_feature(objc_arc)
#if WORKAROUND
    // this would be required either way, but turning it off demonstrates that turning on NSZombieEnabled catches the bug.
    self.scrollView.delegate = nil;
#endif
    self.scrollView = nil;
    
    [super dealloc];
#endif
}

@end

@interface ScrollViewController : UIViewController<UIScrollViewDelegate>

@property (nonatomic, readonly) UIScrollView *scrollView;
@property (nonatomic, retain) ScrollViewDelegate *scrollViewDelegate;
@property (nonatomic) BOOL disappeared;
@property (nonatomic, copy) void (^setContentOffsetBlock)(void);

@end

@implementation ScrollViewController

- (void) dealloc {
    NSLog(@"%@ dealloced", self);

#if !__has_feature(objc_arc)
    self.scrollViewDelegate = nil;
    self.setContentOffsetBlock = nil;

    [super dealloc];
#endif
}

- (void) loadView {
#if __has_feature(objc_arc)
    self.view = ((HBAppDelegate *)[UIApplication sharedApplication].delegate).scrollView;
    self.scrollView.contentSize = CGSizeMake(2000, 4000);

    self.scrollViewDelegate = [[ScrollViewDelegate alloc] initWithScrollView:self.scrollView];

    UILabel *pushBackLabel = [[UILabel alloc] initWithFrame:CGRectMake(200, 1000, 200, 200)];
    pushBackLabel.text = @"Push Back";
    [self.scrollView addSubview:pushBackLabel];
#else
    self.view = ((HBAppDelegate *)[UIApplication sharedApplication].delegate).scrollView;
    self.scrollView.contentSize = CGSizeMake(2000, 4000);

    self.scrollViewDelegate = [[[ScrollViewDelegate alloc] initWithScrollView:self.scrollView] autorelease];

    UILabel *pushBackLabel = [[[UILabel alloc] initWithFrame:CGRectMake(200, 1000, 200, 200)] autorelease];
    pushBackLabel.text = @"Push Back";
    [self.scrollView addSubview:pushBackLabel];
#endif
}

- (void) viewDidAppear:(BOOL)animated {
    [self.scrollView setContentOffset:CGPointMake(0, 1000)
                             animated:YES];

    [super viewDidAppear:animated];
}

- (void) viewWillDisappear:(BOOL)animated {
#if NORMAL_USAGE
    [self.scrollView setContentOffset:CGPointZero
                             animated:YES];
#else
#if __has_feature(objc_arc)
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
#else
    __block ScrollViewController *manualSelf = [self retain];
    self.setContentOffsetBlock = ^{
        if (!manualSelf.disappeared) {
            [manualSelf.scrollView setContentOffset:CGPointZero
                                         animated:YES];
            dispatch_async(dispatch_get_main_queue(),
                           manualSelf.setContentOffsetBlock);
        } else {
            [manualSelf release];
        }
    };

    self.setContentOffsetBlock();
#endif
#endif

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

#if __has_feature(objc_arc)
@property (nonatomic, unsafe_unretained) ScrollViewController *scrollViewController;
#else
@property (nonatomic, assign) ScrollViewController *scrollViewController;
#endif

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

    int64_t delayInSeconds = 2.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        NSLog(@"ScrollView.delegate=%p", ((HBAppDelegate *)[UIApplication sharedApplication].delegate).scrollView.delegate);
    });
}

- (void) pushScrollViewControllerButtonTouchUpInside {
#if __has_feature(objc_arc)
    ScrollViewController *scrollViewController = [ScrollViewController new];
#else
    ScrollViewController *scrollViewController = [[ScrollViewController new] autorelease];
#endif
    self.scrollViewController = scrollViewController;
    [self.navigationController pushViewController:scrollViewController
                                         animated:YES];
}

@end

@interface HBAppDelegate()

@end

@implementation HBAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
#if __has_feature(objc_arc)
    NSLog(@"Using Automatic Reference Counting");
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor whiteColor];

    self.scrollView = [LoggingScrollView new];

    PushScrollViewController *pushScrollViewController = [PushScrollViewController new];
    self.window.rootViewController = [[UINavigationController alloc] initWithRootViewController:pushScrollViewController];
#else
    NSLog(@"Using Manual Reference Counting");
    self.window = [[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];
    self.window.backgroundColor = [UIColor whiteColor];

    self.scrollView = [[LoggingScrollView new] autorelease];

    PushScrollViewController *pushScrollViewController = [[PushScrollViewController new] autorelease];
    self.window.rootViewController = [[[UINavigationController alloc] initWithRootViewController:pushScrollViewController] autorelease];
#endif

    [self.window makeKeyAndVisible];
    return YES;
}

@end
