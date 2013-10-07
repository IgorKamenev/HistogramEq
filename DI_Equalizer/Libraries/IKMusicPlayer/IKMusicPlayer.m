//
//  IKMusicPlayer.m
//  DI_Equalizer
//
//  Created by Igor Kamenev on 7/17/13.
//  Copyright (c) 2013 Igor Kamenev. All rights reserved.
//

#import "IKMusicPlayer.h"

@interface IKMusicPlayer ()

@property (nonatomic) FFTSetup fftSetup;
@property (nonatomic, strong) NSString* soundItemPath;
@property (nonatomic) int framesCount;

@end

static float *fftWindow;
static DSPSplitComplex fftLeft;
static AudioStreamBasicDescription outputAudioFormat;
static ExtAudioFileRef sourceAudioFile;

@implementation IKMusicPlayer

- (id) initWithPath:(NSString *)path
{
    
    self = [super init];
    
    if (self) {
        self.soundItemPath = path;
        
        [self initPlayer];
    }

    return self;
}

- (void) openAudioFile
{
    OSStatus result = noErr;
    UInt32 size;
    
    AudioStreamBasicDescription clientFormat;
    
    NSURL * sourceURL = [NSURL fileURLWithPath:self.soundItemPath];
    
    result = ExtAudioFileOpenURL( (__bridge CFURLRef)sourceURL, &sourceAudioFile );
    if( result != noErr )
    {
        NSLog( @"Error in ExtAudioFileOpenURL: %ld", result );
    }
    
    size = sizeof( clientFormat );
    result = ExtAudioFileSetProperty( sourceAudioFile, kExtAudioFileProperty_ClientDataFormat, size, &outputAudioFormat );
    if( result != noErr )
    {
        NSLog( @"Error while setting client format in source file: %ld", result );
    }
    
    return;
}

- (void) initPlayer
{
    
    // Create the canonical PCM client format.
    memset(&outputAudioFormat, 0, sizeof(outputAudioFormat));
    outputAudioFormat.mSampleRate			= 44100.00;
    outputAudioFormat.mFormatID			= kAudioFormatLinearPCM;
    outputAudioFormat.mFormatFlags		= kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked ;
    outputAudioFormat.mFramesPerPacket	= 1;
    outputAudioFormat.mChannelsPerFrame	= 2;
    outputAudioFormat.mBitsPerChannel		= sizeof(short) * 8;
    outputAudioFormat.mBytesPerPacket		= sizeof(short) * 2;
    outputAudioFormat.mBytesPerFrame		= sizeof(short) * 2;
    
    [self openAudioFile];
    [self createAudioUnit];
}

- (void) closePlayer
{
    ExtAudioFileDispose( sourceAudioFile );
}

- (void) play
{
    
	OSStatus result = AudioSessionInitialize(NULL, NULL, NULL, NULL);
	if (result == kAudioSessionNoError)
	{
		UInt32 sessionCategory = kAudioSessionCategory_MediaPlayback;
		AudioSessionSetProperty(kAudioSessionProperty_AudioCategory, sizeof(sessionCategory), &sessionCategory);
	}
	AudioSessionSetActive(true);
    
    // set preferred buffer size
    Float32 preferredBufferSize = .1; // in seconds
    result = AudioSessionSetProperty(kAudioSessionProperty_PreferredHardwareIOBufferDuration, sizeof(preferredBufferSize), &preferredBufferSize);
    
    [self initFFT];
    
    AudioUnitInitialize(toneUnit);
    AudioOutputUnitStart(toneUnit);
}

- (void)createAudioUnit
{
    
	AudioComponentDescription defaultOutputDescription;
	defaultOutputDescription.componentType = kAudioUnitType_Output;
	defaultOutputDescription.componentSubType = kAudioUnitSubType_RemoteIO;
	defaultOutputDescription.componentManufacturer = kAudioUnitManufacturer_Apple;
	defaultOutputDescription.componentFlags = 0;
	defaultOutputDescription.componentFlagsMask = 0;
	
	// Get the default playback output unit
	AudioComponent defaultOutput = AudioComponentFindNext(NULL, &defaultOutputDescription);
	NSAssert(defaultOutput, @"Can't find default output");
	
	// Create a new unit based on this that we'll use for output
	OSStatus err = AudioComponentInstanceNew(defaultOutput, &toneUnit);
	NSAssert1(toneUnit, @"Error creating unit: %ld", err);
	
	// Set our tone rendering function on the unit
	AURenderCallbackStruct input;
	input.inputProc = playbackCallback;
	input.inputProcRefCon = (__bridge void *)(self);
	err = AudioUnitSetProperty(toneUnit,
                               kAudioUnitProperty_SetRenderCallback,
                               kAudioUnitScope_Input,
                               0,
                               &input,
                               sizeof(input));
	NSAssert1(err == noErr, @"Error setting callback: %ld", err);
    
	err = AudioUnitSetProperty (toneUnit,
                                kAudioUnitProperty_StreamFormat,
                                kAudioUnitScope_Input,
                                0,
                                &outputAudioFormat,
                                sizeof(AudioStreamBasicDescription));
}

static OSStatus playbackCallback(void *inRefCon,
                                 AudioUnitRenderActionFlags *ioActionFlags,
                                 const AudioTimeStamp *inTimeStamp,
                                 UInt32 inBusNumber,
                                 UInt32 inNumberFrames,
                                 AudioBufferList *ioData) {
    
    
    IKMusicPlayer* p = (__bridge IKMusicPlayer*) inRefCon;

    UInt32 framesRead = inNumberFrames * sizeof(SInt16);
    ExtAudioFileRead(sourceAudioFile, &framesRead, ioData );

    
    p.framesCount = inNumberFrames;

    float *Signal = malloc(inNumberFrames*sizeof(float));
    float *BufferMemory = malloc(inNumberFrames*sizeof(float));
    DSPSplitComplex Buffer = { BufferMemory, BufferMemory + inNumberFrames/2 };
    vDSP_vflt16(ioData->mBuffers[0].mData, 2, Signal, 1, inNumberFrames);
    
    float *SignalW = malloc(inNumberFrames*sizeof(float));

    float f = 1.0 / 32768.0;

    vDSP_vmul (Signal,1,fftWindow,1,SignalW,1,inNumberFrames);
    vDSP_vsmul(SignalW, 1, &f, Signal, 1, inNumberFrames);
	vDSP_ctoz((DSPComplex *) Signal, 2, &Buffer, 1, inNumberFrames/2);
    vDSP_fft_zrop(p.fftSetup, &Buffer, 1, &fftLeft, 1, log2(inNumberFrames), FFT_FORWARD);

    free(SignalW);
    free(Signal);
    free(BufferMemory);
    
    p.isFFTDataValid = 1;
     
    return noErr;
}

- (void) initFFT {
    
    // get actuall buffer size
    Float32 audioBufferSize;
    UInt32 size = sizeof (audioBufferSize);
    AudioSessionGetProperty(kAudioSessionProperty_CurrentHardwareIOBufferDuration, &size, &audioBufferSize);
    
    self.framesCount = ceil(outputAudioFormat.mSampleRate * audioBufferSize);
    
    self.fftSetup = vDSP_create_fftsetup(log2(self.framesCount),kFFTRadix2);
    fftLeft.realp = malloc(sizeof(float)*self.framesCount);
    fftLeft.imagp = malloc(sizeof(float)*self.framesCount);
    
    fftWindow = malloc(sizeof(float)*self.framesCount);
    vDSP_hamm_window(fftWindow, self.framesCount, 0);
}

- (float*) getFFTBarsWithBarsCount: (int) barsCount
{
    float* fftValues = malloc(sizeof(float) * barsCount);
    memset(fftValues, 0, sizeof(float) * barsCount);
    
    int usefullFramesCount = self.framesCount/2;

    for (int bar=0; bar < barsCount; bar++) {

        float v = 0;
        
        for (int j=bar * usefullFramesCount / barsCount; j < (bar+1) * usefullFramesCount / barsCount; j++) {
            
            float s = fftLeft.realp[j] / usefullFramesCount;
            float c = fftLeft.imagp[j] / usefullFramesCount;

            float a = sqrt((s*s+c*c)/2.0);

            v += a;
        }

        v *= 1.5;
        
        float base = 2+500 * bar / barsCount;

        v = [self logBase:base value:(1 + v*(base-1))];

// TODO:
// на симуляторе буфер 512, на девайсе 4096 (иначе бывают фризы).
// подебить FFT так и не удалось (из-за разного размера окна, FFT выдает разные попугаи... потом надо доделать)
        
#if TARGET_IPHONE_SIMULATOR
        v *= 2;
#else
        v /= 2;
#endif
        v -= 0.01;

        fftValues[bar] = v;
    }
    
    return fftValues;
}

- (float) logBase: (float) base value: (float) value
{
    return log10f(value) / log10f(base);
}

@end
