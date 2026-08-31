//
//  AudioRemarkManager.swift
//  SpiceMontRetailer
//

import Foundation
import Combine
import AVFoundation

public final class AudioRemarkManager: NSObject, ObservableObject, AVAudioRecorderDelegate, AVAudioPlayerDelegate {
    public static let shared = AudioRemarkManager()

    // MARK: - Recording State
    @Published public var isRecording: Bool = false
    @Published public var recordedAudioBase64: String = ""
    @Published public var recordingDuration: Int = 0
    @Published public var hasRecordedAudio: Bool = false
    @Published public var permissionDenied: Bool = false

    // MARK: - Playback State
    @Published public var isPlaying: Bool = false
    @Published public var currentPlayingSource: String? = nil
    @Published public var playbackCurrentTime: TimeInterval = 0
    @Published public var playbackDuration: TimeInterval = 0
    @Published public var playbackProgress: Double = 0.0

    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?
    private var avPlayer: AVPlayer?
    private var avPlayerTimeObserver: Any?

    private var recordingTimer: Timer?
    private var playbackTimer: Timer?
    private var currentFileURL: URL?

    public override init() {
        super.init()
    }

    private var tempAudioURL: URL {
        let tempDir = FileManager.default.temporaryDirectory
        return tempDir.appendingPathComponent("order_remark_\(UUID().uuidString).m4a")
    }

    // MARK: - Permissions
    public func requestPermission(completion: @escaping (Bool) -> Void) {
        let session = AVAudioSession.sharedInstance()
        if #available(iOS 17.0, *) {
            AVAudioApplication.requestRecordPermission { [weak self] granted in
                DispatchQueue.main.async {
                    self?.permissionDenied = !granted
                    completion(granted)
                }
            }
        } else {
            session.requestRecordPermission { [weak self] granted in
                DispatchQueue.main.async {
                    self?.permissionDenied = !granted
                    completion(granted)
                }
            }
        }
    }

    // MARK: - Recording Controls
    public func startRecording() {
        stopAudio()

        requestPermission { [weak self] granted in
            guard let self = self, granted else { return }

            let session = AVAudioSession.sharedInstance()
            do {
                try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetoothHFP])
                try session.setActive(true)

                let fileURL = self.tempAudioURL
                self.currentFileURL = fileURL

                let settings: [String: Any] = [
                    AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                    AVSampleRateKey: 16000.0,
                    AVNumberOfChannelsKey: 1,
                    AVEncoderAudioQualityKey: AVAudioQuality.medium.rawValue
                ]

                self.audioRecorder = try AVAudioRecorder(url: fileURL, settings: settings)
                self.audioRecorder?.delegate = self
                self.audioRecorder?.record()

                self.isRecording = true
                self.recordingDuration = 0

                self.recordingTimer?.invalidate()
                self.recordingTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                    guard let self = self else { return }
                    self.recordingDuration += 1
                    if self.recordingDuration >= 60 {
                        self.stopRecording()
                    }
                }
            } catch {
                print("Failed to start audio recording: \(error)")
            }
        }
    }

    public func stopRecording() {
        recordingTimer?.invalidate()
        recordingTimer = nil
        audioRecorder?.stop()
        audioRecorder = nil
        isRecording = false

        if let url = currentFileURL, let data = try? Data(contentsOf: url), !data.isEmpty {
            let base64 = data.base64EncodedString()
            recordedAudioBase64 = "data:audio/mp4;base64,\(base64)"
            hasRecordedAudio = true
        }
    }

    public func clearRecording() {
        recordingTimer?.invalidate()
        recordingTimer = nil
        audioRecorder?.stop()
        audioRecorder = nil
        isRecording = false
        recordedAudioBase64 = ""
        recordingDuration = 0
        hasRecordedAudio = false

        if let url = currentFileURL {
            try? FileManager.default.removeItem(at: url)
        }
        currentFileURL = nil
    }

    // MARK: - Audio Playback Controls

    public func playAudio(source: String) {
        if isPlaying && currentPlayingSource == source {
            pauseAudio()
            return
        }

        if !isPlaying && currentPlayingSource == source && audioPlayer != nil {
            resumeAudio()
            return
        }

        stopAudio()
        currentPlayingSource = source

        let cleanSource = source.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanSource.isEmpty else { return }

        // Setup audio session for playback
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .default, options: [.duckOthers, .defaultToSpeaker])
        try? session.setActive(true)

        // Check if source is a URL or Base64 string
        if cleanSource.lowercased().hasPrefix("http://") || cleanSource.lowercased().hasPrefix("https://") {
            playRemoteAudioURL(cleanSource)
        } else {
            playBase64Audio(cleanSource)
        }
    }

    private func playBase64Audio(_ base64String: String) {
        var cleanBase64 = base64String
        if let commaIndex = cleanBase64.firstIndex(of: ",") {
            cleanBase64 = String(cleanBase64[cleanBase64.index(after: commaIndex)...])
        }

        guard let audioData = Data(base64Encoded: cleanBase64, options: .ignoreUnknownCharacters) else {
            print("Failed to decode base64 audio data")
            return
        }

        do {
            audioPlayer = try AVAudioPlayer(data: audioData)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()

            isPlaying = true
            playbackDuration = audioPlayer?.duration ?? 0
            playbackCurrentTime = 0
            playbackProgress = 0.0

            startPlaybackTimer()
        } catch {
            print("Failed to initialize AVAudioPlayer: \(error)")
        }
    }

    private func playRemoteAudioURL(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }

        // Download audio data asynchronously and play via AVAudioPlayer for smooth progress tracking
        URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            guard let self = self, let data = data, error == nil else {
                print("Failed to load remote audio: \(String(describing: error))")
                return
            }

            DispatchQueue.main.async {
                do {
                    self.audioPlayer = try AVAudioPlayer(data: data)
                    self.audioPlayer?.delegate = self
                    self.audioPlayer?.prepareToPlay()
                    self.audioPlayer?.play()

                    self.isPlaying = true
                    self.playbackDuration = self.audioPlayer?.duration ?? 0
                    self.playbackCurrentTime = 0
                    self.playbackProgress = 0.0

                    self.startPlaybackTimer()
                } catch {
                    print("Error playing downloaded audio: \(error)")
                }
            }
        }.resume()
    }

    public func pauseAudio() {
        audioPlayer?.pause()
        isPlaying = false
        playbackTimer?.invalidate()
        playbackTimer = nil
    }

    public func resumeAudio() {
        guard let player = audioPlayer else { return }
        player.play()
        isPlaying = true
        startPlaybackTimer()
    }

    public func stopAudio() {
        playbackTimer?.invalidate()
        playbackTimer = nil
        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying = false
        currentPlayingSource = nil
        playbackCurrentTime = 0
        playbackProgress = 0.0
        playbackDuration = 0
    }

    private func startPlaybackTimer() {
        playbackTimer?.invalidate()
        playbackTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, let player = self.audioPlayer else { return }
            self.playbackCurrentTime = player.currentTime
            if player.duration > 0 {
                self.playbackProgress = min(1.0, player.currentTime / player.duration)
            }
        }
    }

    // MARK: - AVAudioPlayerDelegate
    public func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        stopAudio()
    }

    // MARK: - Duration Helpers
    public var formattedDuration: String {
        let mins = recordingDuration / 60
        let secs = recordingDuration % 60
        return String(format: "%02d:%02d", mins, secs)
    }

    public func formatTime(_ time: TimeInterval) -> String {
        let totalSecs = Int(max(0, time))
        let mins = totalSecs / 60
        let secs = totalSecs % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}
