import SwiftUI
import AVKit
import WebKit

class PiPManager: NSObject, ObservableObject, AVPictureInPictureControllerDelegate {
    private var pipController: AVPictureInPictureController?
    private var playerLayer = AVPlayerLayer()
    private let player = AVQueuePlayer()
    private var playerLooper: AVPlayerLooper?
    
    // UI State for PiP
    @Published var currentQuestion: String = "في انتظار الأسئلة..."
    @Published var currentAnswer: String = ""
    @Published var currentExplanation: String = ""
    
    private var hostingController: UIHostingController<PiPContentView>?

    override init() {
        super.init()
        setupPlayer()
    }

    private func setupPlayer() {
        // PiP requires a video to be playing. We use a blank video loop.
        guard let url = Bundle.main.url(forResource: "blank", withExtension: "mp4") else { return }
        let playerItem = AVPlayerItem(url: url)
        playerLooper = AVPlayerLooper(player: player, templateItem: playerItem)
        playerLayer.player = player
        
        if AVPictureInPictureController.isPictureInPictureSupported() {
            pipController = AVPictureInPictureController(playerLayer: playerLayer)
            pipController?.delegate = self
            pipController?.canStartPictureInPictureAutomaticallyFromInline = true
        }
    }

    func startPiP() {
        player.play()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.pipController?.startPictureInPicture()
        }
    }

    func stopPiP() {
        pipController?.stopPictureInPicture()
        player.pause()
    }

    func updateContent(question: String, answer: String, explanation: String?) {
        DispatchQueue.main.async {
            self.currentQuestion = question
            self.currentAnswer = answer
            self.currentExplanation = explanation ?? ""
            
            // In a real implementation, we would update the view being rendered into the PiP buffer
            // Since standard PiP only supports video, we often use a workaround like rendering 
            // a SwiftUI view into a video stream or using the newer Buffer-based PiP API in iOS 15+
        }
    }
}

// The view that will be shown inside the PiP window
struct PiPContentView: View {
    var question: String
    var answer: String
    var explanation: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("س: \(question)")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
                .lineLimit(2)
            
            Divider().background(Color.white.opacity(0.5))
            
            Text("ج: \(answer)")
                .font(.system(size: 12))
                .foregroundColor(.green)
                .lineLimit(3)
            
            if !explanation.isEmpty {
                Text(explanation)
                    .font(.system(size: 10))
                    .foregroundColor(.gray)
                    .lineLimit(2)
            }
        }
        .padding(8)
        .background(Color.black.opacity(0.8))
        .cornerRadius(10)
    }
}
