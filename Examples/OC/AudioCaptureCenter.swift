//
//  AudioCaptureCenter.swift
//  LiveApp
//
//  Created by PAN on 2020/6/9.
//  Copyright © 2020 YR. All rights reserved.
//

import Foundation

class AudioCaptureCenter {
    private let echoCancellation = XBEchoCancellation.shared()!
    private var isRunning = false

    /// 音量倍数，默认1
    var volumeScaleFactor: Float = 1 {
        didSet {
            echoCancellation.volumeScale = volumeScaleFactor * 1.5
        }
    }

    var didOutputAudioBufferList: ((AudioBufferList, AudioStreamBasicDescription) -> Void)?
    var didOutputAudioSampleBuffer: ((CMSampleBuffer) -> Void)?

    deinit {
        echoCancellation.stop()
    }

    func startCapture() {
        guard !isRunning else { return }
        isRunning = true

        echoCancellation.volumeScale = volumeScaleFactor * 1.5
        if didOutputAudioBufferList != nil {
            echoCancellation.bl_input = { [weak self, unowned echoCancellation] buffer in
                guard let self = self else { return }
                if let buffer = buffer?.pointee {
                    self.didOutputAudioBufferList?(buffer, echoCancellation.streamFormat)
                }
            }
        }
        if didOutputAudioSampleBuffer != nil {
            echoCancellation.bl_input2 = { [weak self] buffer in
                guard let self = self, let buffer = buffer else { return }
                self.didOutputAudioSampleBuffer?(buffer)
            }
        }

        echoCancellation.startInput()
        echoCancellation.open()
    }

    func stopCapture() {
        guard isRunning else { return }
        isRunning = false

        echoCancellation.stop()
    }
}
