//
//  DEKaraokeController.m
//  KaraokeDemo
//
//  Created by CHENWANFEI on 05/06/2017.
//  Copyright © 2017 SwordFish. All rights reserved.
//

#import "DEKaraokeController.h"
#import <AVFoundation/AVFoundation.h>
#import <Accelerate/Accelerate.h>
@interface DEKaraokeController()


@property (nonatomic) float averagePowerForChannel1;
@property (nonatomic) float averagePowerForChannel0;



@property(nonatomic,strong) AVAudioEngine *audioEngine;

@property(nonatomic,copy) NSURL *bgMusicURL;
@property(nonatomic,copy) NSURL *outputURL;

@property(nonatomic,weak) AVAudioNode *audioMixer;

@end
@implementation DEKaraokeController
-(instancetype)initWithBgMusic:(NSURL *)bgMusicURL outputURL:(NSURL *)outputURL{
    if(self = [super init]){
        
        _bgMusicURL = bgMusicURL;
        _outputURL = outputURL;
        _audioEngine = [[AVAudioEngine alloc] init];
        
    }
    return self;
}
-(void)startWithPowerLevelChangeCallback:(void (^)(float))powerLevelChangedCallback musicFinishCallback:(void (^)(void))musicFinishCallback{
    
    [[NSFileManager defaultManager] removeItemAtURL:self.outputURL error:NULL];
    
    
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:(AVAudioSessionCategoryOptionMixWithOthers | AVAudioSessionCategoryOptionAllowBluetooth | AVAudioSessionCategoryOptionDefaultToSpeaker) error:NULL];
    [[AVAudioSession sharedInstance] setActive:YES error:NULL];
    
    
    
    
    AVAudioEngine *engine = _audioEngine;
    AVAudioMixerNode *mainMixer = engine.mainMixerNode;
    AVAudioFormat *mixerOutputFormat = [mainMixer outputFormatForBus:0];
    
    
    
    AVAudioPlayerNode *playerNodeForMixer = [[AVAudioPlayerNode alloc] init];
    [engine attachNode:playerNodeForMixer];
    
    AVAudioMixerNode *audioMixer = [[AVAudioMixerNode alloc] init];
    [engine attachNode:audioMixer];
    
    AVAudioPlayerNode *playerNodeForOutput = [[AVAudioPlayerNode alloc] init];
    [engine attachNode:playerNodeForOutput];
    
    AVAudioMixerNode *micMixer = [[AVAudioMixerNode alloc] init];
    [engine attachNode:micMixer];
    
    
    AVAudioInputNode *mic = [engine inputNode];
    [engine connect:mic to:micMixer format:[mic inputFormatForBus:0]];
    [engine connect:micMixer to:audioMixer format:mixerOutputFormat];
    [engine connect:playerNodeForMixer to:audioMixer format:mixerOutputFormat];
    
    
    
    [engine connect:playerNodeForOutput to:mainMixer format:mixerOutputFormat];
    
   
    AVAudioFile *bgAudioFile = [[AVAudioFile alloc] initForReading:self.bgMusicURL error:NULL];
    
    __weak DEKaraokeController *weakSelf = self;
    [playerNodeForMixer scheduleFile:bgAudioFile atTime:nil completionHandler:^{
        [playerNodeForOutput stop];
        [weakSelf stop];
        if (musicFinishCallback != nil){
            musicFinishCallback();
        }
    }];
    
    [playerNodeForOutput scheduleFile:bgAudioFile atTime:nil completionHandler:nil];
    
    
    
    
    
    
    AVAudioFormat *tapFormat = [audioMixer outputFormatForBus:0];
    
    AVAudioFile *outputFile = [[AVAudioFile alloc] initForWriting:self.outputURL settings:
                               [tapFormat settings] error:NULL];
    
    [audioMixer installTapOnBus:0 bufferSize:4096 format:tapFormat
                          block:^(AVAudioPCMBuffer *buffer, AVAudioTime *when) {
                              NSError *error;
                              BOOL success = NO;
                              
                              success = [outputFile writeFromBuffer:buffer error:&error];
                              NSAssert(success, @"error writing buffer data to file, %@", [error localizedDescription]);
                          }];
    
    self.audioMixer = audioMixer;
    
    [micMixer installTapOnBus:0 bufferSize:4096 format:tapFormat
                        block:^(AVAudioPCMBuffer *buffer, AVAudioTime *when) {
                            [weakSelf meterLevel:buffer callback:powerLevelChangedCallback];
                            
                        }];
    
    
    
    NSError *error;
    [engine reset];
    [engine prepare];
    [engine startAndReturnError:&error];
    
    [playerNodeForMixer play];
    [playerNodeForOutput play];
    
    self.isRunning = YES;
    
    
   
}



-(void)meterLevel:(AVAudioPCMBuffer *)buffer callback:(void (^)(float))callback{
    //  [buffer setFrameLength:[buffer frameLength]];
    UInt32 inNumberFrames = buffer.frameLength;
    
    float LEVEL_LOWPASS_TRIG = 0.2;
    
    if(buffer.format.channelCount > 0)
    {
        Float32* samples = (Float32*)buffer.floatChannelData[0];
        Float32 avgValue = 0;
        
        vDSP_meamgv((Float32*)samples, 1, &avgValue, inNumberFrames);
        self.averagePowerForChannel0 = (LEVEL_LOWPASS_TRIG*((avgValue==0)?-100:20.0*log10f(avgValue))) + ((1-LEVEL_LOWPASS_TRIG)*self.averagePowerForChannel0) ;
        self.averagePowerForChannel1 = self.averagePowerForChannel0;
    }
    
    if(buffer.format.channelCount > 1)
    {
        Float32* samples = (Float32*)buffer.floatChannelData[1];
        Float32 avgValue = 0;
        
        vDSP_meamgv((Float32*)samples, 1, &avgValue, inNumberFrames);
        self.averagePowerForChannel1 = (LEVEL_LOWPASS_TRIG*((avgValue==0)?-100:20.0*log10f(avgValue))) + ((1-LEVEL_LOWPASS_TRIG)*self.averagePowerForChannel1) ;
    }
    
    float power = (self.averagePowerForChannel0 + self.averagePowerForChannel1) / 2;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if(callback != nil){
            callback(power);
        }
        //self.meterLabel.text = [NSString stringWithFormat:@"%f",self.averagePower];
    });
    
}


-(void)stop{
    
    [self.audioMixer removeTapOnBus:0];
    [self.audioEngine stop];
    
    
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:NULL];
    [[AVAudioSession sharedInstance] setActive:YES error:NULL];

    self.isRunning = NO;
}
@end
