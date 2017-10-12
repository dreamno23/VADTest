//
//  AEUtils.m
//  VADTEST
//
//  Created by zhangyu on 2017/10/12.
//  Copyright © 2017年 Michong. All rights reserved.
//

#import "AEUtils.h"
#import "TheAmazingAudioEngine.h"
#import "VoiceActiveCheck.h"

@interface AEUtils() {
    
}

@property (nonatomic, strong) AEAudioUnitInputModule *input;
@property (nonatomic, strong) AEAudioUnitOutput *output;
@property (nonatomic, strong) AERenderer *renderer;

@end

@implementation AEUtils {
    webrtc::VoiceActiveCheck *m_ivad;
    
    int16_t *m_ibuffer;
}

- (instancetype)init
{
    self = [super init];
    self.renderer = [[AERenderer alloc]init];
    self.output = [[AEAudioUnitOutput alloc] initWithRenderer:self.renderer];
    self.input = self.output.inputModule;
    __weak AEUtils *THIS = self;
    self.renderer.block =  ^(const AERenderContext * _Nonnull context) {
        [THIS rendererBlock:(void *)context];
    };
    
    m_ivad = new webrtc::VoiceActiveCheck(48000);
    
    m_ibuffer = (int16_t *)malloc(sizeof(int16_t) * 1024);
    return self;
}

- (void)rendererBlock:(void *)acontext
{
    AERenderContext *context = (AERenderContext *)acontext;
    AEModuleProcess(self.input, context);
    const AudioBufferList *bufferList = AEBufferStackGet(context->stack,0);
    if (bufferList == NULL) {
        return;
    }
    float *tBuffer = (float*)bufferList->mBuffers[0].mData;
    for (int idx = 0; idx < context->frames; idx ++) {
        m_ibuffer[idx] = tBuffer[idx] * 32768.0f;
    }
    int valid = m_ivad->isActiveVoice(m_ibuffer);
    NSLog(@"vad status:%d",valid);
}

- (void)start
{
    if (![[AVAudioSession sharedInstance].category isEqualToString:AVAudioSessionCategoryPlayAndRecord]) {
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord
                                         withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker | AVAudioSessionCategoryOptionDuckOthers
                                               error:NULL];
    }
    if (![[AVAudioSession sharedInstance].mode isEqualToString:AVAudioSessionModeDefault]) {
        [[AVAudioSession sharedInstance] setMode:AVAudioSessionModeDefault error:NULL];
    }
    [[AVAudioSession sharedInstance] setPreferredSampleRate:48000 error:nil];
    [self.output setSampleRate:48000];
    
    [[AVAudioSession sharedInstance] setPreferredIOBufferDuration:1024.0 / 48000 error:NULL];
    [[AVAudioSession sharedInstance] setActive:YES error:NULL];
    
    [self.output start:NULL];
    [self.input start:NULL];
}
@end
