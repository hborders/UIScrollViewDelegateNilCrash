//
//  HBAppDelegate.h
//  UIScrollViewDelegateNilCrash
//
//  Created by dev1 on 10/25/12.
//  Copyright (c) 2012 Heath Borders. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LoggingScrollView : UIScrollView

@end

@interface HBAppDelegate : UIResponder <UIApplicationDelegate>

@property (nonatomic, retain) UIWindow *window;
@property (nonatomic, retain) LoggingScrollView *scrollView;

@end
