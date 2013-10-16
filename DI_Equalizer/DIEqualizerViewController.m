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
@property (nonatomic) BOOL isPlaying;
@end

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
    
    self.eqView = [[IKGraphicEqualizerView alloc] initWithFrame:self.view.bounds];
    self.eqView.barsCount = 80;
    self.eqView.minBarValue = 0;
    self.eqView.maxBarValue = 1;
    self.eqView.barsLevelCount = 40;
    
    UITapGestureRecognizer* tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapHandler)];
    
    [self.eqView addGestureRecognizer:tapRecognizer];
    self.eqView.userInteractionEnabled = YES;
    
    [self.view addSubview:self.eqView];
    self.eqView.backgroundColor = [UIColor redColor];
    
    self.player = [[IKMusicPlayer alloc] initWithPath:[[NSBundle mainBundle] pathForResource:@"test" ofType:@"mp3"]];

    [self.player initPlayer];
    [self.player play];

    self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateEQ)];
    [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    
}

- (void) startPlayer
{
    NSLog(@"Start player");
    [self.player play];
    self.isPlaying = YES;
}

- (void) stopPlayer
{
    NSLog(@"Stop player");
    [self.player stop];
    self.isPlaying = NO;
}

- (void) tapHandler
{
    if (self.isPlaying)
        [self stopPlayer];
    else
        [self startPlayer];
}

- (void) updateEQ
{

    if (!self.player.isFFTDataValid) return;

    float * fftValues = [self.player getFFTBarsWithBarsCount:self.eqView.barsCount];
    [self.eqView setFFTValues:fftValues length:self.eqView.barsCount];

    free(fftValues);    
}

@end
