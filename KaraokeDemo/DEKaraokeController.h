//
//  DEKaraokeController.h
//  KaraokeDemo
//
//  Created by CHENWANFEI on 05/06/2017.
//  Copyright © 2017 SwordFish. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DEKaraokeController : NSObject
-(instancetype)initWithBgMusic:(NSURL *)bgMusicURL outputURL:(NSURL *)outputURL;
@property(nonatomic) BOOL isRunning;
-(void)startWithPowerLevelChangeCallback:(void (^)(float))powerLevelChangedCallback musicFinishCallback:(void (^)(void))musicFinishCallback;
-(void)stop;
@end
