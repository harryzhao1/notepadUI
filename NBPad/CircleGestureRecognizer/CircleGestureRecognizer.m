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
#define FRONT_END_ENLARGE_FACTOR_PERCENTAGE_OF_TOTAL_PATH_LENGTH 0.2
#define VERBOSE 0

@interface CircleGestureRecognizer ()
@property (nonatomic, strong) NSMutableArray* pointPath;
@property (nonatomic) CGPoint startingPoint;
@property (nonatomic) CGRect runningBoundingBox;
@end

@implementation CircleGestureRecognizer

- (NSMutableArray *)pointPath {
    if (!_pointPath)
        _pointPath = [[NSMutableArray alloc] init];
    return _pointPath;
}

#pragma mark - touches
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

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    CGPoint point = [touch locationInView:self.view];
    [self.pointPath addObject:[NSValue valueWithCGPoint:point]];
    self.runningBoundingBox =  [self expandBox:self.runningBoundingBox WithPoint:point];

    if ([self circleIsComplete]) {
        self.state = UIGestureRecognizerStateRecognized;
        if(VERBOSE)
            NSLog(@"detected! (in touches moved)");
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    if ([self lengthenedPathWillCross]) {
        self.state = UIGestureRecognizerStateRecognized;
        if(VERBOSE)
            NSLog(@"detected! (in touches ended)");
    }
    else
        self.state = UIGestureRecognizerStateFailed;
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    self.state = UIGestureRecognizerStateCancelled;
}

- (void)reset {
    [self.pointPath removeAllObjects];
    self.runningBoundingBox = CGRectZero;
}

- (void)initalizeDetectionWithPoint:(CGPoint) point {
    self.startingPoint = point;
    [self.pointPath addObject:[NSValue valueWithCGPoint:point]];
    self.runningBoundingBox = CGRectMake(point.x, point.y, 0.0f, 0.0f);
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

- (BOOL) circleIsComplete {
    return [self lastPointisCloseToStartingPoint] || [self lastPointIsCrossingPath];
}

- (BOOL)lastPointisCloseToStartingPoint {
    CGPoint point = [[self.pointPath lastObject] CGPointValue];
    float distanceTravelled = [self distanceBetweenPoint:point andPoint:self.startingPoint];
    float radius = MAX(self.runningBoundingBox.size.width, self.runningBoundingBox.size.height);
    float target = radius = radius * DETECTION_THRESHOLD;
    return distanceTravelled < target;
}

- (float) distanceBetweenPoint:(CGPoint)p1 andPoint:(CGPoint) p2 {
    float diffx = p1.x - p2.x;
    float diffy = p1.y - p2.y;
    return sqrtf(diffx * diffx + diffy * diffy);
}

- (BOOL)lastPointIsCrossingPath {
    return [self intersectionIndexForArray:self.pointPath] != nil;
}

- (NSNumber *)intersectionIndexForArray:(NSArray *)array {
    CGPoint last = [[array lastObject] CGPointValue];
    CGPoint secondlast = [array[[array count] - 2] CGPointValue];
    for (int i = 1; i < [array count] - 2; i ++) {
        CGPoint pt1 = [array[i - 1] CGPointValue];
        CGPoint pt2 = [array[i] CGPointValue];
        NSValue *intersection = [self intersectionOfLineFrom:last to:secondlast withLineFrom:pt1 to:pt2];
        if (intersection)
            return @(i-1);
    }
    return nil;
}

- (NSValue *)intersectionOfLineFrom:(CGPoint)p1 to:(CGPoint)p2 withLineFrom:(CGPoint)p3 to:(CGPoint)p4
{
    CGFloat d = (p2.x - p1.x)*(p4.y - p3.y) - (p2.y - p1.y)*(p4.x - p3.x);
    if (d == 0)
        return nil; // parallel lines
    CGFloat u = ((p3.x - p1.x)*(p4.y - p3.y) - (p3.y - p1.y)*(p4.x - p3.x))/d;
    CGFloat v = ((p3.x - p1.x)*(p2.y - p1.y) - (p3.y - p1.y)*(p2.x - p1.x))/d;
    if (u < 0.0 || u > 1.0)
        return nil; // intersection point not between p1 and p2
    if (v < 0.0 || v > 1.0)
        return nil; // intersection point not between p3 and p4
    CGPoint intersection;
    intersection.x = p1.x + u * (p2.x - p1.x);
    intersection.y = p1.y + u * (p2.y - p1.y);
    
    return [NSValue valueWithCGPoint:intersection];
}

- (BOOL)lengthenedPathWillCross {
    if ([self.pointPath count] < 2)
        return NO;
    float lengthenBy = [self getTotalLength] * FRONT_END_ENLARGE_FACTOR_PERCENTAGE_OF_TOTAL_PATH_LENGTH;
    NSMutableArray * testArray = [self.pointPath mutableCopy];
    [self lengthenStartForArray:testArray withLength:lengthenBy];
    [self lengthenEndForArray:testArray withLength:lengthenBy];
    NSArray *testArrayReverse = [[testArray reverseObjectEnumerator] allObjects];
    return [self intersectionIndexForArray:testArray] != nil || [self intersectionIndexForArray:testArrayReverse];
}

- (void)lengthenStartForArray:(NSMutableArray *)target withLength:(float)length{
    CGPoint pt1 = [target[1] CGPointValue];
    CGPoint pt2 = [target[0] CGPointValue];
    [target insertObject:[NSValue valueWithCGPoint:[self extendPoint:pt1 andPoint:pt2 withLength:length]] atIndex:0];
}

- (void)lengthenEndForArray:(NSMutableArray *)target withLength:(float)length{
    CGPoint pt1 = [target[[target count] - 2] CGPointValue];
    CGPoint pt2 = [target[[target count] - 1] CGPointValue];
    [target addObject:[NSValue valueWithCGPoint:[self extendPoint:pt1 andPoint:pt2 withLength:length]]];
}

- (CGPoint)extendPoint:(CGPoint)pt1 andPoint:(CGPoint)pt2 withLength:(float)length {
    CGVector direction = [self unitVectorFromVector:CGVectorMake(pt2.x - pt1.x, pt2.y - pt1.y)];
    CGPoint pt = CGPointMake(pt2.x + direction.dx * length, pt2.y + direction.dy * length);
    return pt;
}

- (CGVector)unitVectorFromVector:(CGVector)vector {
    float length = sqrtf(vector.dx * vector.dx + vector.dy * vector.dy);
    return CGVectorMake(vector.dx/length, vector.dy/length);
}

- (float)getTotalLength {
    float result = 0;
    CGPoint lastPoint = [self.pointPath[0] CGPointValue];
    for (int i =1; i < [self.pointPath count]; i++) {
        CGPoint currentPoint = [self.pointPath[i] CGPointValue];
        result += [self distanceBetweenPoint:lastPoint andPoint:currentPoint];
        lastPoint = currentPoint;
    }
    return result;
}

#pragma mark - target action
- (CGRect)boundingBoxInView:(UIView *)view {
    CGRect result = CGRectZero;
    if ([self lastPointisCloseToStartingPoint] || [self lengthenedPathWillCross])
        result = self.runningBoundingBox;
    else if ([self lastPointIsCrossingPath])
        result = [self boundingBoxForSelfCrossingPath];
    return [self.view convertRect:result toView:view];
}

- (CGRect)boundingBoxForSelfCrossingPath {
    NSNumber *crossingIndex = [self intersectionIndexForArray:self.pointPath];
    if (!crossingIndex)
        return CGRectZero;
    CGPoint initialPoint = [self.pointPath[[crossingIndex integerValue]] CGPointValue];
    CGRect result = CGRectMake(initialPoint.x, initialPoint.y, 0.0f, 0.0f);
    for (int i = [crossingIndex integerValue]; i < [self.pointPath count]; i++) {
        CGPoint currentPoint = [self.pointPath[i] CGPointValue];
        result = [self expandBox:result WithPoint:currentPoint];
    }
    return result;
}
@end