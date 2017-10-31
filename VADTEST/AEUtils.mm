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
#import "WebrtcNS.h"

@interface AEUtils() {
    
}

@property (nonatomic, strong) AEAudioUnitInputModule *input;
@property (nonatomic, strong) AEAudioUnitOutput *output;
@property (nonatomic, strong) AERenderer *renderer;

@end

@implementation AEUtils {
    webrtc::VoiceActiveCheck *m_ivad;
    webrtc::WebrtcNS *m_ns;
    
    int16_t *m_ibuffer;
    
    int16_t **ns_inputBuffer;
    int16_t **ns_outputBuffer;
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
    m_ns = new webrtc::WebrtcNS(16000);
    
    m_ibuffer = (int16_t *)malloc(sizeof(int16_t) * 256);
    
    ns_inputBuffer = (int16_t **)malloc(sizeof(int16_t) * 1);
    ns_inputBuffer[0] = (int16_t *)malloc(sizeof(int16_t) * 160);
    ns_outputBuffer = (int16_t **)malloc(sizeof(int16_t) * 1);
    ns_outputBuffer[0] =(int16_t *)malloc(sizeof(int16_t) * 160);
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
//    long long t1 = [[NSDate date] timeIntervalSince1970] * 1000.0;
//    int valid = m_ivad->isActiveVoice(m_ibuffer);
//    long long t2 = [[NSDate date] timeIntervalSince1970] * 1000.0;
//    NSLog(@"vad status:%d,time = %lld",valid, t2 - t1);
    int fr_length = 0;
    int es_noise = 0;
    
    memcpy(ns_inputBuffer[0], m_ibuffer, 160 * sizeof(short));
    m_ns->processAudio(ns_inputBuffer, ns_outputBuffer, 1);
    int *rvalue = m_ns->noise_estimate(&fr_length, &es_noise);
    NSLog(@"estimate = %d", es_noise);
    if (rvalue) {
        
    }
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
    [[AVAudioSession sharedInstance] setPreferredSampleRate:16000 error:nil];
    [self.output setSampleRate:16000];
    
    [[AVAudioSession sharedInstance] setPreferredIOBufferDuration:256.0 / 16000 error:NULL];
    [[AVAudioSession sharedInstance] setActive:YES error:NULL];
    
    [self.output start:NULL];
    [self.input start:NULL];
}
@end
