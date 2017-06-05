#KaraokeDemo


This project illustrates how to use AVAudioEngine to mix background music and microphone input, just like karaoke.

![ScreenShot](https://raw.github.com/JagieChen/KaraokeDemo/master/KaraokeDemo/snapshot.jpg)





## Features

* Using Accelerate framework to meter input power level

## How to use
<pre><code>

self.karaoke = [[DEKaraokeController alloc] initWithBgMusic:[self bgMp3FileURL] outputURL:[self recordFileURL]];
 
....

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




</code></pre>

## References
https://blog.metova.com/audio-manipulation-using-avaudioengine
https://stackoverflow.com/questions/30641439/level-metering-with-avaudioengine

## License

This code is distributed under the terms and conditions of the [MIT license](LICENSE).


 
  
