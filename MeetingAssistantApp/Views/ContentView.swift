import SwiftUI

struct AppLogo: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 60, height: 60)
                .shadow(radius: 5)
            
            Image(systemName: "brain.head.profile")
                .font(.system(size: 30))
                .foregroundColor(.white)
            
            Circle()
                .stroke(Color.white.opacity(0.3), lineWidth: 2)
                .frame(width: 50, height: 50)
        }
    }
}

struct MeetingEntry: Identifiable, Codable {
    let id = UUID()
    let question: String
    let answer: String
    let explanation: String?
    let timestamp: Date
}

struct ContentView: View {
    @StateObject private var speechManager = SpeechRecognitionManager()
    @StateObject private var pipManager = PiPManager()
    @AppStorage("gemini_api_key") private var apiKey: String = ""
    @State private var history: [MeetingEntry] = []
    @State private var showSettings = false
    @State private var showAlert = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 15) {
                // Header with Logo
                VStack(spacing: 10) {
                    AppLogo()
                        .padding(.top, 10)
                    
                    Text("Smart Assistant")
                        .font(.system(size: 22, weight: .black, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text("مساعدك الذكي في الاجتماعات")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Divider().padding(.horizontal)

                // Status Indicator & Keyword Alert
                VStack {
                    HStack {
                        Circle()
                            .fill(speechManager.isRecording ? Color.red : Color.gray)
                            .frame(width: 10, height: 10)
                        Text(speechManager.isRecording ? "جاري الاستماع والتحليل..." : "الجلسة متوقفة")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(speechManager.isRecording ? .red : .secondary)
                    }
                    
                    if speechManager.detectedKeyword {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                            Text("تم رصد كلمة مفتاحية هامة!")
                        }
                        .font(.caption)
                        .bold()
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.orange)
                        .cornerRadius(20)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
                .frame(height: 50)

                // Main Control Button
                Button(action: {
                    if apiKey.isEmpty {
                        showAlert = true
                        return
                    }
                    
                    if speechManager.isRecording {
                        speechManager.stopRecording()
                        pipManager.stopPiP()
                    } else {
                        speechManager.startRecording(apiKey: apiKey) { question, answer, explanation in
                            let newEntry = MeetingEntry(question: question, answer: answer, explanation: explanation, timestamp: Date())
                            withAnimation {
                                history.insert(newEntry, at: 0)
                            }
                            pipManager.updateContent(question: question, answer: answer, explanation: explanation)
                        }
                        pipManager.startPiP()
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(speechManager.isRecording ? Color.red.opacity(0.1) : Color.blue.opacity(0.1))
                            .frame(width: 140, height: 140)
                        
                        Circle()
                            .fill(speechManager.isRecording ? Color.red : Color.blue)
                            .frame(width: 100, height: 100)
                            .shadow(color: (speechManager.isRecording ? Color.red : Color.blue).opacity(0.5), radius: 10)
                        
                        Image(systemName: speechManager.isRecording ? "stop.fill" : "mic.fill")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .padding(.vertical, 10)

                // History Section
                VStack(alignment: .leading) {
                    HStack {
                        Text("سجل الجلسة")
                            .font(.headline)
                        Spacer()
                        if !history.isEmpty {
                            Button("مسح") { history.removeAll() }
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                    .padding(.horizontal)
                    
                    if history.isEmpty {
                        VStack {
                            Spacer()
                            Image(systemName: "bubble.left.and.bubble.right")
                                .font(.largeTitle)
                                .foregroundColor(.gray.opacity(0.3))
                            Text("لا توجد بيانات بعد")
                                .foregroundColor(.gray)
                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                    } else {
                        List(history) { entry in
                            VStack(alignment: .leading, spacing: 8) {
                                Label(entry.question, systemImage: "questionmark.circle.fill")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(.blue)
                                
                                Label(entry.answer, systemImage: "checkmark.circle.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.primary)
                                
                                if let explanation = entry.explanation {
                                    Text(explanation)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .padding(.leading, 28)
                                }
                                
                                Text(entry.timestamp, style: .time)
                                    .font(.system(size: 10))
                                    .foregroundColor(.gray)
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                            }
                            .padding(.vertical, 4)
                            .listRowSeparator(.hidden)
                            .background(RoundedRectangle(cornerRadius: 10).fill(Color.secondary.opacity(0.05)))
                            .padding(.vertical, 2)
                        }
                        .listStyle(PlainListStyle())
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showSettings = true }) {
                        Image(systemName: "gearshape.circle.fill")
                            .font(.title3)
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView(apiKey: $apiKey)
            }
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("مفتاح API مفقود"),
                    message: Text("يرجى إدخال مفتاح Gemini API في الإعدادات للبدء."),
                    dismissButton: .default(Text("فتح الإعدادات")) {
                        showSettings = true
                    }
                )
            }
        }
    }
}

struct SettingsView: View {
    @Binding var apiKey: String
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("إعدادات الذكاء الاصطناعي")) {
                    SecureField("أدخل مفتاح Gemini API", text: $apiKey)
                    Text("يتم حفظ المفتاح محلياً على جهازك فقط.")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Section {
                    Link(destination: URL(string: "https://aistudio.google.com/app/apikey")!) {
                        HStack {
                            Image(systemName: "key.fill")
                            Text("احصل على مفتاح API مجاني")
                        }
                    }
                }
                
                Section(header: Text("عن التطبيق")) {
                    HStack {
                        Text("الإصدار")
                        Spacer()
                        Text("1.0.0")
                    }
                }
            }
            .navigationTitle("الإعدادات")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("إغلاق") { dismiss() }
                }
            }
        }
    }
}
