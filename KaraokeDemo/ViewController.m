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
#import "DEKaraokeController.h"
@interface ViewController ()<AVAudioPlayerDelegate>


@property(nonatomic,strong) AVAudioPlayer *previewPlayer;

@property (weak, nonatomic) IBOutlet UIButton *replayBtn;

@property (weak, nonatomic) IBOutlet UILabel *meterLabel;

@property (weak, nonatomic) IBOutlet UIButton *recordBtn;




@property(nonatomic,strong) DEKaraokeController *karaoke;

@end

@implementation ViewController

-(void)alertSth:(NSString *)alert{
    UIAlertController *ac = [UIAlertController alertControllerWithTitle:nil message:alert preferredStyle:(UIAlertControllerStyleAlert)];
    [ac addAction:[UIAlertAction actionWithTitle:@"Ok" style:(UIAlertActionStyleDefault) handler:nil]];
    [self presentViewController:ac animated:YES completion:nil];
}



- (void)viewDidLoad {
    [super viewDidLoad];
    self.karaoke = [[DEKaraokeController alloc] initWithBgMusic:[self bgMp3FileURL] outputURL:[self recordFileURL]];
    
    
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
    
    return [[NSBundle mainBundle] URLForResource:@"bg" withExtension:@"m4a"];
}


- (IBAction)onStart:(id)sender {
    UIButton *btn = sender;
    if(self.karaoke.isRunning == NO){
        __weak ViewController *weakSelf = self;
        [self.karaoke startWithPowerLevelChangeCallback:^(float p)  {
            weakSelf.meterLabel.text = [NSString stringWithFormat:@"%f",p];
        } musicFinishCallback:^{
            weakSelf.recordBtn.selected = NO;
            weakSelf.replayBtn.enabled = YES;
        }];
        btn.selected = YES;
        self.replayBtn.enabled = NO;
        
    }else{
        //stop
        [self.karaoke stop];
        self.recordBtn.selected = NO;
        self.replayBtn.enabled = YES;

    }
    
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
