import Foundation
import Speech
import AVFoundation

class SpeechRecognitionManager: ObservableObject {
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "ar-SA"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    private let geminiService = GeminiService()
    
    @Published var isRecording = false
    @Published var transcribedText = ""
    @Published var detectedKeyword = false
    
    private let keywords = ["مهم", "امتحان", "اختبار", "ركزوا", "كرر", "مطلوب"]
    
    func startRecording(apiKey: String, onResult: @escaping (String, String, String?) -> Void) {
        isRecording = true
        
        let audioSession = AVAudioSession.sharedInstance()
        try? audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try? audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        let inputNode = audioEngine.inputNode
        guard let recognitionRequest = recognitionRequest else { return }
        
        recognitionRequest.shouldReportPartialResults = true
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { result, error in
            if let result = result {
                let latestText = result.bestTranscription.formattedString
                self.transcribedText = latestText
                self.checkForKeywords(in: latestText)
                
                if result.isFinal || latestText.count % 100 == 0 {
                    self.geminiService.getAnswer(for: latestText, apiKey: apiKey, completion: onResult)
                }
            }
            
            if error != nil || result?.isFinal == true {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                self.recognitionRequest = nil
                self.recognitionTask = nil
            }
        }
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        try? audioEngine.start()
    }
    
    func stopRecording() {
        audioEngine.stop()
        recognitionRequest?.endAudio()
        isRecording = false
    }
    
    private func checkForKeywords(in text: String) {
        let words = text.lowercased().components(separatedBy: .whitespacesAndNewlines)
        for keyword in keywords {
            if words.contains(keyword) {
                DispatchQueue.main.async {
                    self.detectedKeyword = true
                    let generator = UIImpactFeedbackGenerator(style: .heavy)
                    generator.impactOccurred()
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        self.detectedKeyword = false
                    }
                }
                break
            }
        }
    }
}
