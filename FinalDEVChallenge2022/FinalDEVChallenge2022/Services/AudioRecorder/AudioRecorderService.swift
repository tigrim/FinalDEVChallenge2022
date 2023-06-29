//
//  AudioRecorderService.swift
//  FinalDEVChallenge2022
//
//

import Foundation
import CoreAudio
import AVFoundation

protocol AudioRecorderProtocol {
    var level: Float { get }
    var isLoud: Bool { get }
    func configure()
    func updateMeters()
}

final class AudioRecorderService: AudioRecorderProtocol {

    var level: Float {
        recorder?.averagePower(forChannel: 0) ?? 0.0
    }

    var isLoud: Bool {
        level > LEVEL_THRESHOLD
    }

    private let LEVEL_THRESHOLD: Float = -7.0

    private var recorder: AVAudioRecorder?

    func configure() {
        let documents = URL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)[0])
        let url = documents.appendingPathComponent("record.caf")

        let recordSettings: [String: Any] = [
            AVFormatIDKey:              kAudioFormatAppleIMA4,
            AVSampleRateKey:            44100.0,
            AVNumberOfChannelsKey:      2,
            AVEncoderBitRateKey:        12800,
            AVLinearPCMBitDepthKey:     16,
            AVEncoderAudioQualityKey:   AVAudioQuality.max.rawValue
        ]

        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord)
            try audioSession.setActive(true)
            try recorder = AVAudioRecorder(url: url, settings: recordSettings)

        } catch {
            return
        }

        recorder?.prepareToRecord()
        recorder?.isMeteringEnabled = true
        recorder?.record()
    }

    func updateMeters() {
        recorder?.updateMeters()
    }
}
