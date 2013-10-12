//
//  CircleGestureSampleVC.m
//  NBPad
//
//  Created by Keith Zhou on 2013-10-12.
//  Copyright (c) 2013 keith. All rights reserved.
//

#import "CircleGestureSampleVC.h"
#import "CircleGestureRecognizer.h"

@interface CircleGestureSampleVC ()

@property (nonatomic, strong) UIView *highlightedBox;

@end

@implementation CircleGestureSampleVC

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [self setupHighlightBox];
    [self setupCircleGestureRecognizer];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setupHighlightBox {
    self.highlightedBox = [[UIView alloc]initWithFrame:CGRectZero];
    [self.highlightedBox setBackgroundColor:[UIColor redColor]];
    [self.view addSubview:self.highlightedBox];
}

- (void)setupCircleGestureRecognizer{
    CircleGestureRecognizer * recognizer = [[CircleGestureRecognizer alloc] initWithTarget:self action:@selector(circleDetected:)];
    [self.view addGestureRecognizer:recognizer];
}

#pragma mark - circle gesture recognizer callback when detected
- (void)circleDetected:(CircleGestureRecognizer *)recognizer {
    CGRect boundingBox = [recognizer boundingBoxInView:recognizer.view];
    [self.highlightedBox setFrame:boundingBox];
}

@end
