//
//  AudioPlayer.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/3/8.
//

import AVFoundation
import Combine
import CoreDataStack
import Foundation
import UIKit

final class AudioPlayer: NSObject {
    var disposeBag = Set<AnyCancellable>()

    var player = AVPlayer()
    var timeObserver: Any?
    var statusObserver: Any?
    var attachment: Attachment?
    var currentURL: URL?
    let session = AVAudioSession.sharedInstance()
    let playbackState = CurrentValueSubject<PlaybackState, Never>(PlaybackState.unknown)
    public static let shared = AudioPlayer()

    let currentTimeSubject = CurrentValueSubject<TimeInterval, Never>(0)

    override init() {
        super.init()
        addObserver()
    }
}

extension AudioPlayer {
    func playAudio(audioAttachment: Attachment) {
        guard let url = URL(string: audioAttachment.url) else {
            return
        }
        do {
            try session.setCategory(.playback)
        } catch {
            print(error)
            return
        }

        if audioAttachment == attachment {
            player.play()
            return
        }

        let playerItem = AVPlayerItem(url: url)
        player.replaceCurrentItem(with: playerItem)
        attachment = audioAttachment
        player.play()
        playbackState.send(PlaybackState.playing)
    }

    func addObserver() {
        UIDevice.current.isProximityMonitoringEnabled = true
        NotificationCenter.default.addObserver(self, selector: #selector(proxumityStateChange), name: UIDevice.proximityStateDidChangeNotification, object: nil)

        timeObserver = player.addPeriodicTimeObserver(forInterval: CMTimeMake(value: 1, timescale: CMTimeScale(NSEC_PER_SEC)), queue: DispatchQueue.main, using: { [weak self] time in
            guard let self = self else { return }
            self.currentTimeSubject.value = time.seconds
        })
        player.publisher(for: \.status, options: .new)
            .sink(receiveValue: { status in
                switch status {
                case .failed:
                    self.playbackState.value = .failed
                case .readyToPlay:
                    self.playbackState.value = .readyToPlay
                case .unknown:
                    self.playbackState.value = .unknown
                @unknown default:
                    fatalError()
                }
            })
            .store(in: &disposeBag)
    }

    @objc func proxumityStateChange(notification: NSNotification) {
        if UIDevice.current.proximityState == true {
            do {
                try session.setCategory(.playAndRecord)
            } catch {
                print(error)
                return
            }
        } else {
            do {
                try session.setCategory(.playback)
            } catch {
                print(error)
                return
            }
        }
    }

    func resume() {
        player.play()
        playbackState.send(PlaybackState.playing)
    }

    func pause() {
        player.pause()
        playbackState.send(PlaybackState.paused)
    }

    func seekToTime(time: TimeInterval) {
        player.seek(to: CMTimeMake(value:Int64(time), timescale: 1))
    }
}
