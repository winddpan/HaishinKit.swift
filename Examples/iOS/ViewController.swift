//
//  ViewController.swift
//  MVPStreamingKit
//
//  Created by PAN on 2020/9/27.
//

import HaishinKit
import UIKit
import VideoToolbox

class ViewController: UIViewController {
    var camera: STCamera!
    var renderView: STGLPreview!

    var rtmpConnection = RTMPConnection()
    var rtmpStream: RTMPStream!
    lazy var audioCapture = AudioCaptureCenter()

    override func viewDidLoad() {
        super.viewDidLoad()

        let session = AVAudioSession.sharedInstance()
        do {
            // https://stackoverflow.com/questions/51010390/avaudiosession-setcategory-swift-4-2-ios-12-play-sound-on-silent
            if #available(iOS 10.0, *) {
                try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            } else {
                session.perform(NSSelectorFromString("setCategory:withOptions:error:"), with: AVAudioSession.Category.playAndRecord, with: [
                    AVAudioSession.CategoryOptions.allowBluetooth,
                    AVAudioSession.CategoryOptions.defaultToSpeaker,
                ])
                try session.setMode(.default)
            }
            try session.setActive(true)
        } catch {
            print(error)
        }

        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                if granted {
                } else {
                    print("camera not avaiable!")
                }
            }
        }

        rtmpStream = RTMPStream(connection: rtmpConnection)

        let present: AVCaptureSession.Preset = .hd1280x720
        camera = STCamera(devicePosition: .front, sessionPresset: present, fps: Int32(30), needYuvOutput: false)
        camera.mirrored = true
        camera.delegate = self

        renderView = STGLPreview(frame: UIScreen.main.bounds, context: EAGLContext(api: .openGLES2))
        renderView.mirrored = false
        view.addSubview(renderView)

        audioCapture.didOutputAudioSampleBuffer = { [weak self] in
            self?.rtmpStream?.pushAudioSampleBuffer($0)
        }

        rtmpConnection.addEventListener(.rtmpStatus, selector: #selector(rtmpStatusHandler), observer: self)
        rtmpConnection.addEventListener(.ioError, selector: #selector(rtmpErrorHandler), observer: self)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        rtmpStream.videoSettings = [
            .width: 720, // video output width
            .height: 1280, // video output height
            .bitrate: 1600 * 1000, // video output bitrate
            .maxKeyFrameIntervalDuration: 3,
        ]
        rtmpStream.audioSettings = [
            .muted: false, // mute audio
            .bitrate: 128 * 1000,
        ]

        rtmpConnection.connect(url)
        rtmpStream.publish("OKOKOK")

        camera.startRunning()
        audioCapture.startCapture()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        camera.stopRunning()
        audioCapture.stopCapture()

        rtmpConnection.close()
        rtmpStream.close()
        rtmpStream.dispose()
    }

    let url = "rtmp://pili-publish.yuanyuan128.com/ihuajian/159121543?e=1601375094&token=sg1-tgSpSG8q2WnTuDTax9aIYYyUIfre4RccaEr9:IdeAUjy-yEh57o5Ce8UekuNsYks%3D&serialnum=1601288707596&addtssei=true"
    private var retryCount: Int = 0

    @objc
    private func rtmpStatusHandler(_ notification: Notification) {
        let e = Event.from(notification)
        guard let data: ASObject = e.data as? ASObject, let code: String = data["code"] as? String else {
            return
        }
        logger.info(code)
        switch code {
        case RTMPConnection.Code.connectSuccess.rawValue:
            retryCount = 0
            rtmpStream!.publish(Preference.defaultInstance.streamName!)
        // sharedObject!.connect(rtmpConnection)
        case RTMPConnection.Code.connectFailed.rawValue, RTMPConnection.Code.connectClosed.rawValue:
            guard retryCount <= 3 else {
                return
            }
            Thread.sleep(forTimeInterval: pow(2.0, Double(retryCount)))
            rtmpConnection.connect(url)
            retryCount += 1
        default:
            break
        }
    }

    @objc
    private func rtmpErrorHandler(_ notification: Notification) {
        logger.error(notification)
        rtmpConnection.connect(url)
    }
}

extension ViewController: STCameraDelegate {
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
        guard let buffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        renderView?.renderSampleBuffer(sampleBuffer)
        rtmpStream?.pushVideoPixelBuffer(buffer, presentationTimeStamp: CMSampleBufferGetPresentationTimeStamp(sampleBuffer), duration: CMSampleBufferGetOutputDuration(sampleBuffer))
    }
}
