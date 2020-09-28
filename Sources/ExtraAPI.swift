//
//  ExtraAPI.swift
//  Example iOS
//
//  Created by PAN on 2020/9/28.
//  Copyright © 2020 Shogo Endo. All rights reserved.
//

import AVFoundation
import Foundation

public extension RTMPStream {
    func pushVideoPixelBuffer(_ imageBuffer: CVImageBuffer, presentationTimeStamp: CMTime, duration: CMTime) {
        mixer.videoIO.encoder.encodeImageBuffer(
            imageBuffer,
            presentationTimeStamp: presentationTimeStamp,
            duration: duration
        )
    }

    func pushAudioSampleBuffer(_ buffer: CMSampleBuffer) {
        mixer.audioIO.encoder.encodeSampleBuffer(buffer)
    }

    func pushAudioUnitBuffer(_ audioBufferList: AudioBufferList, description: AudioStreamBasicDescription) {
        if audioBufferList.mBuffers.mDataByteSize > 0 {
            var audioBufferList = audioBufferList
            let encoder = mixer.audioIO.encoder
            encoder.destination = .aac
            encoder.inSourceFormat = description

            if _startTimeStamp == 0 {
                _startTimeStamp = CFAbsoluteTimeGetCurrent()
            }
            let presentationTimeStamp = CFAbsoluteTimeGetCurrent() - _startTimeStamp
            encoder.delegate?.sampleOutput(audio: UnsafeMutableAudioBufferListPointer(&audioBufferList), presentationTimeStamp: CMTimeMake(value: Int64(presentationTimeStamp * description.mSampleRate), timescale: Int32(description.mSampleRate)))
        }
    }
}

private var aduioTimeStampeKey: Void?

extension RTMPStream {
    fileprivate var _startTimeStamp: CFAbsoluteTime {
        set {
            objc_setAssociatedObject(self, &aduioTimeStampeKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            objc_getAssociatedObject(self, &aduioTimeStampeKey) as? CFAbsoluteTime ?? 0
        }
    }
}
