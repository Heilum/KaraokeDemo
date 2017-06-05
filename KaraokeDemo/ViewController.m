//
//  ViewController.m
//  KaraokeDemo
//
//  Created by CHENWANFEI on 04/06/2017.
//  Copyright © 2017 SwordFish. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <Accelerate/Accelerate.h>
@interface ViewController ()<AVAudioPlayerDelegate>


@property(nonatomic,strong) AVAudioPlayer *previewPlayer;

@property (weak, nonatomic) IBOutlet UIButton *replayBtn;

@property (weak, nonatomic) IBOutlet UILabel *meterLabel;

@property (weak, nonatomic) IBOutlet UIButton *recordBtn;




@property (nonatomic) float averagePowerForChannel1;
@property (nonatomic) float averagePowerForChannel0;

@property (nonatomic) float averagePower;

@property(nonatomic,strong) AVAudioEngine *audioEngine;


@end

@implementation ViewController

-(void)alertSth:(NSString *)alert{
    UIAlertController *ac = [UIAlertController alertControllerWithTitle:nil message:alert preferredStyle:(UIAlertControllerStyleAlert)];
    [ac addAction:[UIAlertAction actionWithTitle:@"Ok" style:(UIAlertActionStyleDefault) handler:nil]];
    [self presentViewController:ac animated:YES completion:nil];
}



- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    
    // Do any additional setup after loading the view, typically from a nib.
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    __weak ViewController *weakSelf = self;
    [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted) {
        if(!granted){
            [weakSelf alertSth:@"Pleast let the App access your micphone"];
        }
    }];
}
- (IBAction)onReplay:(id)sender {
    
    
    
    if(self.previewPlayer == nil){
        
        [[AVAudioSession sharedInstance]
         setCategory:AVAudioSessionCategoryPlayback
         error:NULL];
        
        self.previewPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[self recordFileURL] error:NULL];
        self.previewPlayer.delegate = self;
        [self.previewPlayer play];
        self.replayBtn.selected = YES;
       
        self.recordBtn.enabled = NO;
        
    }else{
        [self audioPlayerDidFinishPlaying:self.previewPlayer successfully:YES];
    }
    
}


-(NSURL *)recordFileURL{
    NSString *tmpFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"Jagie.wav"];
    NSLog(@"%@",tmpFilePath);
    return [NSURL fileURLWithPath:tmpFilePath];
}
-(NSURL *)bgMp3FileURL{
    
    return [[NSBundle mainBundle] URLForResource:@"bg" withExtension:@"mp3"];
}


- (IBAction)onStart:(id)sender {
    
    
    UIButton *btn = sender;
    
    if(self.audioEngine == nil){
        
        
        [[NSFileManager defaultManager] removeItemAtURL:[self recordFileURL] error:NULL];
        
        
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:(AVAudioSessionCategoryOptionMixWithOthers | AVAudioSessionCategoryOptionAllowBluetooth | AVAudioSessionCategoryOptionDefaultToSpeaker) error:NULL];
        [[AVAudioSession sharedInstance] setActive:YES error:NULL];
        
        
        
        
        AVAudioEngine *engine = [[AVAudioEngine alloc] init];
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

        NSURL *bgMp3URL = [self bgMp3FileURL];
        AVAudioFile *bgAudioFile = [[AVAudioFile alloc] initForReading:bgMp3URL error:NULL];
        
        __weak ViewController *weakSelf = self;
        [playerNodeForMixer scheduleFile:bgAudioFile atTime:nil completionHandler:^{
            [playerNodeForOutput stop];
            [weakSelf stopRecording];
        }];
        
        [playerNodeForOutput scheduleFile:bgAudioFile atTime:nil completionHandler:nil];
        
        
        
        
        
        
        AVAudioFormat *tapFormat = [audioMixer outputFormatForBus:0];
        
        AVAudioFile *outputFile = [[AVAudioFile alloc] initForWriting:[self recordFileURL] settings:
                                   [tapFormat settings] error:NULL];
        
        [audioMixer installTapOnBus:0 bufferSize:4096 format:tapFormat
                              block:^(AVAudioPCMBuffer *buffer, AVAudioTime *when) {
                                  NSError *error;
                                  BOOL success = NO;
                                  
                                  success = [outputFile writeFromBuffer:buffer error:&error];
                                  NSAssert(success, @"error writing buffer data to file, %@", [error localizedDescription]);
                              }];
        [micMixer installTapOnBus:0 bufferSize:4096 format:tapFormat
                              block:^(AVAudioPCMBuffer *buffer, AVAudioTime *when) {
                                
                                  NSLog(@"mic mixer");
                                  [weakSelf meterLevel:buffer];
                                  
                              }];
        
        
        NSError *error;
        [engine prepare];
        [engine startAndReturnError:&error];
        
        [playerNodeForMixer play];
        [playerNodeForOutput play];
        
        
        self.audioEngine = engine;
        btn.selected = YES;
        
        self.replayBtn.enabled = NO;
        
        
        
    }else{
        
        //stop
        [self stopRecording];
        
    }
    
    
    
    
    
    
}

-(void)meterLevel:(AVAudioPCMBuffer *)buffer{
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
    
    self.averagePower = (self.averagePowerForChannel0 + self.averagePowerForChannel1) / 2;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.meterLabel.text = [NSString stringWithFormat:@"%f",self.averagePower];
    });
    
}


-(void)stopRecording{
    
    

    
    [self.audioEngine stop];
    self.audioEngine = nil;
    self.recordBtn.selected = NO;
    self.replayBtn.enabled = YES;
    
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:NULL];
    [[AVAudioSession sharedInstance] setActive:YES error:NULL];
    
}

#pragma AVAudioPlayerDelegate
- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag{
    self.previewPlayer.delegate = nil;
    self.previewPlayer = nil;
    self.replayBtn.selected = NO;
    self.recordBtn.enabled = YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
