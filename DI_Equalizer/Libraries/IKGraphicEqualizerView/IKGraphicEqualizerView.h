//
//  IKGraphicEqualizerView.h
//  DI_Equalizer
//
//  Created by Igor Kamenev on 7/17/13.
//  Copyright (c) 2013 Igor Kamenev. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface IKGraphicEqualizerView : UIView

@property (nonatomic) int barsCount;
@property (nonatomic) int barsLevelCount;

@property (nonatomic) CGFloat minBarValue;
@property (nonatomic) CGFloat maxBarValue;

@property (nonatomic) CGFloat barOffsetHorizontal;
@property (nonatomic) CGFloat barOffsetVertical;


- (void) setFFTValues: (float*) fftValues length: (int) length;

@end
