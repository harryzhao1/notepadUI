//
//  CircleGestureRecognizer.h
//  NBPad
//
//  Created by Keith Zhou on 2013-10-12.
//  Copyright (c) 2013 keith. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CircleGestureRecognizer : UIGestureRecognizer
- (CGRect)boundingBoxInView:(UIView *)view;
@end
