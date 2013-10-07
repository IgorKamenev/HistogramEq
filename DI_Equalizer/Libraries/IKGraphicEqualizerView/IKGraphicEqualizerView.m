//
//  IKGraphicEqualizerView.m
//  DI_Equalizer
//
//  Created by Igor Kamenev on 7/17/13.
//  Copyright (c) 2013 Igor Kamenev. All rights reserved.
//

#import "IKGraphicEqualizerView.h"

@interface IKGraphicEqualizerView ()

@property (nonatomic) CGFloat barItemWidth;
@property (nonatomic) CGFloat barItemHeight;

@property (nonatomic) float* fftValues;

@end

@implementation IKGraphicEqualizerView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {

        self.barsCount = 256;
        self.barsLevelCount = 80;
        
        self.minBarValue = 0;
        self.maxBarValue = 1;
        
        self.barOffsetHorizontal = 1;
        self.barOffsetVertical = 1;
        
        self.backgroundColor = [UIColor blackColor];
        
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
        
    }
    return self;
}

- (void) setBarsCount:(int)barsCount
{
    _barsCount = barsCount;
    if (self.fftValues)
        free(self.fftValues);

    self.fftValues = malloc(sizeof(float) * _barsCount);
    memset(self.fftValues, 0, sizeof(float) * _barsCount);
    
}

- (UIColor*) colorForBar: (int) bar
{

    UIColor* color;

    CGFloat hStep = 360.0 / self.barsCount;
    CGFloat h = 260.0 + hStep*bar;
    CGFloat s = 100;
    CGFloat b = 100;
    
    if (h > 360.0)
        h -= 360.0;
    
    color = [UIColor colorWithHue:h/360.0 saturation:s/100.0 brightness:b/100.0 alpha:1.0];

    return color;
}

- (void) drawRect:(CGRect)rect
{
    
    self.barItemWidth = ceil(self.bounds.size.width / self.barsCount - self.barOffsetHorizontal);
    self.barItemHeight = ceil(self.bounds.size.height / 2 / self.barsLevelCount - self.barOffsetVertical);

    if (self.barItemWidth <= 0) {
        self.barItemWidth = 1.0;
        self.barOffsetHorizontal = 0.0;
    }
    
    if (self.barItemHeight <= 0) {
        self.barItemHeight = 1.0;
        self.barOffsetVertical = 0.0;
    }
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextClearRect(context, CGRectMake(0, 0, self.frame.size.width, self.frame.size.height));
    
    CGFloat dvalue = self.barsLevelCount / (self.maxBarValue - self.minBarValue);
    CGFloat halfHeight = self.bounds.size.height / 2;
    CGFloat barItemHeightWithOffset = self.barItemHeight+self.barOffsetVertical;
    
    for (int bar=0; bar < self.barsCount; bar++) {

        float level = ceilf ((self.fftValues[bar] - self.minBarValue) * dvalue);

        CGColorRef barColor = [self colorForBar: bar].CGColor;
        CGColorRef mirroredBarColor = CGColorCreateCopyWithAlpha(barColor, 0.5);
        
        CGFloat x = ceil(bar * (self.barOffsetHorizontal+self.barItemWidth));
        
        for (int barLevel=1; barLevel < level; barLevel++) {
            
            CGContextSetFillColorWithColor(context, barColor);
            CGFloat y = floor(halfHeight - barLevel*barItemHeightWithOffset);
            CGRect rect = CGRectMake(x, y, self.barItemWidth, self.barItemHeight);
            CGContextFillRect(context, rect);

            //Mirrored bars
            CGContextSetFillColorWithColor(context, mirroredBarColor);
            y = floor(halfHeight + barLevel*barItemHeightWithOffset);
            rect = CGRectMake(x, y-barItemHeightWithOffset, self.barItemWidth, self.barItemHeight);
            CGContextFillRect(context, rect);
        }
        
        CFRelease(mirroredBarColor);
        
    }
}

- (void) setFFTValues: (float*) fftValues length: (int) length {
    
    if (length != self.barsCount) {
        NSLog(@"Count of values should be equal to bars count. (bars count - %d, values given - %d", self.barsCount, length);
        return;
    }
   
    float kIncFilterFactor = 0.7;
    float kFadeFilterFactor = 0.1;
    
    for (int bar=0; bar < length; bar++) {

        if (self.fftValues[bar] < fftValues[bar]) {
            self.fftValues[bar] = (fftValues[bar] * kIncFilterFactor) + (self.fftValues[bar] * (1.0 - kIncFilterFactor));
        } else {
            self.fftValues[bar] = (fftValues[bar] * kFadeFilterFactor) + (self.fftValues[bar] * (1.0 - kFadeFilterFactor));
        }
        
        //self.fftValues[bar] = fftValues[bar];
    }

    [self setNeedsDisplay];
   
}

- (void) dealloc {
    free(self.fftValues);
}

@end
