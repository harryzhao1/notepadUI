//
//  CircleGestureRecognizer.m
//  NBPad
//
//  Created by Keith Zhou on 2013-10-12.
//  Copyright (c) 2013 keith. All rights reserved.
//

#import "CircleGestureRecognizer.h"
#import <UIKit/UIGestureRecognizerSubclass.h>

#define DETECTION_THRESHOLD 0.2
#define VERBOSE 0

@interface CircleGestureRecognizer ()
@property (nonatomic, strong) NSMutableArray* pointPath;
@property (nonatomic) CGPoint startingPoint;
@property (nonatomic) CGRect runningBoundingBox;
@end

@implementation CircleGestureRecognizer
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    if ([[event touchesForGestureRecognizer:self] count] > 1) {
        NSLog(@"More than one touches. Not circle gesture");
        self.state = UIGestureRecognizerStateFailed;
        return;
    }
    if (VERBOSE)
        NSLog(@"touch began");
    UITouch * touch = [touches anyObject];
    CGPoint point = [touch locationInView:self.view];
    [self initalizeDetectionWithPoint:point];
}

- (void)initalizeDetectionWithPoint:(CGPoint) point {
    self.startingPoint = point;
    [self.pointPath addObject:[NSValue valueWithCGPoint:point]];
    self.runningBoundingBox = CGRectMake(point.x, point.y, 0.0f, 0.0f);
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    CGPoint point = [touch locationInView:self.view];
    [self.pointPath addObject:[NSValue valueWithCGPoint:point]];
    self.runningBoundingBox =  [self expandBox:self.runningBoundingBox WithPoint:point];

    if ([self circleIsCompletedForNewPoint:point]) {
        self.state = UIGestureRecognizerStateRecognized;
        if(VERBOSE)
            NSLog(@"detected!");
    }
}

- (BOOL) circleIsCompletedForNewPoint:(CGPoint)point {
    float distanceTravelled = [self distanceBetweenPoint:point andPoint:self.startingPoint];
    float radius = MAX(self.runningBoundingBox.size.width, self.runningBoundingBox.size.height);
    float target = radius = radius * DETECTION_THRESHOLD;
    if (VERBOSE)
        NSLog(@"touches moved, distance:%.4f, target:%.4f", distanceTravelled, target);
    return distanceTravelled < target;
}

- (float) distanceBetweenPoint:(CGPoint)p1 andPoint:(CGPoint) p2 {
    float diffx = p1.x - p2.x;
    float diffy = p1.y - p2.y;
    return sqrtf(diffx * diffx + diffy * diffy);
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    self.state = UIGestureRecognizerStateFailed;
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    self.state = UIGestureRecognizerStateCancelled;
}

- (void)reset {
    [self.pointPath removeAllObjects];
    self.runningBoundingBox = CGRectZero;
}

- (BOOL) formedClosedPath{
    return NO;
}

- (CGRect)expandBox:(CGRect)inital WithPoint:(CGPoint)point {
    float minX = inital.origin.x, minY = inital.origin.y, maxX = inital.origin.x + inital.size.width, maxY = inital.origin.y + inital.size.height;
    if (point.x < minX)
        minX = point.x;
    else if(point.x > maxX)
        maxX = point.x;
    if (point.y < minY)
        minY = point.y;
    else if(point.y > maxY)
        maxY = point.y;
    return CGRectMake(minX, minY, maxX - minX, maxY - minY);
}

- (CGRect)boundingBoxInView:(UIView *)view {
    return [self.view convertRect:self.runningBoundingBox toView:view];
}

@end