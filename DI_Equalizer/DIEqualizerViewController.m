//
//  DIEqualizerViewController.m
//  DI_Equalizer
//
//  Created by Igor Kamenev on 7/17/13.
//  Copyright (c) 2013 Igor Kamenev. All rights reserved.
//

#import "DIEqualizerViewController.h"
#import "IKGraphicEqualizerView.h"
#import "IKMusicPlayer.h"
#import <QuartzCore/QuartzCore.h>
#import <Foundation/Foundation.h>

@interface DIEqualizerViewController ()

@property (nonatomic, strong) IKGraphicEqualizerView* eqView;
@property (nonatomic, strong) NSTimer* timer;
@property (nonatomic, strong) IKMusicPlayer* player;
@property (nonatomic, strong) CADisplayLink* displayLink;
@end

static int barsCount=40;

@implementation DIEqualizerViewController

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
    
    self.eqView = [[IKGraphicEqualizerView alloc] initWithFrame:CGRectMake(0, 0, 80, 40)];
    self.eqView.barsCount = barsCount;
    self.eqView.minBarValue = 0;
    self.eqView.maxBarValue = 1;
    
    
    self.eqView.barsLevelCount = 10;
    [self.view addSubview:self.eqView];
    
    self.player = [[IKMusicPlayer alloc] initWithPath:[[NSBundle mainBundle] pathForResource:@"test" ofType:@"mp3"]];

    [self.player initPlayer];
    [self.player play];

    self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateEQ)];
    [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    
}

- (void) updateEQ
{

    if (!self.player.isFFTDataValid) return;

    float * fftValues = [self.player getFFTBarsWithBarsCount:barsCount];
    [self.eqView setFFTValues:fftValues length:barsCount];

    free(fftValues);

//   
//    float *values = malloc(sizeof(float) * barsCount);
//    
//    for (int i=0; i < barsCount; i++) {
//        
//        values[i] = sin(v*M_PI + sin(i*M_PI_2/90.0))-0.3;
//        //printf("%0.2f ", values[i]);
//    }
//    
//    v += 0.03;
//    
//    [self.eqView setFFTValues:values length:barsCount];
//    
//    free(values);
    
}

@end
