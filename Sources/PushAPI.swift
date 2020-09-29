//
//  PushAPI.swift
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
}
