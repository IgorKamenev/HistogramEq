//
//  IKMusicPlayer.h
//  DI_Equalizer
//
//  Created by Igor Kamenev on 7/17/13.
//  Copyright (c) 2013 Igor Kamenev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import <Accelerate/Accelerate.h>


@interface IKMusicPlayer : NSObject {
   

}

@property (nonatomic) int isFFTDataValid;

- (id) initWithPath: (NSString*) path;
- (void) initPlayer;
- (void) play;
- (void) stop;

//- (NSArray*) getFFTBarsWithBarsCount: (int) barsCount;
- (float*) getFFTBarsWithBarsCount: (int) barsCount;


@end
