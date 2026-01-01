import Foundation

struct GeminiResponse: Codable {
    struct Candidate: Codable {
        struct Content: Codable {
            struct Part: Codable {
                let text: String
            }
            let parts: [Part]
        }
        let content: Content
    }
    let candidates: [Candidate]
}

class GeminiService {
    private let endpoint = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent"
    
    func getAnswer(for text: String, apiKey: String, completion: @escaping (String, String, String?) -> Void) {
        guard !apiKey.isEmpty, let url = URL(string: "\(endpoint)?key=\(apiKey)") else { return }
        
        let systemPrompt = """
        أنت مساعد دراسي ذكي في اجتماع أو حصة دراسية. 
        مهمتك هي استخراج الأسئلة من النص المحول من الصوت والإجابة عليها باختصار شديد جداً.
        يجب أن يكون الرد بتنسيق JSON كالتالي:
        {
          "question": "السؤال المستخرج",
          "answer": "الإجابة المختصرة",
          "explanation": "شرح بسيط جداً (اختياري)"
        }
        إذا لم تجد سؤالاً واضحاً، حاول تلخيص أهم نقطة ذكرت.
        """
        
        let body: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": "\(systemPrompt)\n\nالنص المستخرج: \(text)"]
                    ]
                ]
            ]
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else { return }
            
            if let decodedResponse = try? JSONDecoder().decode(GeminiResponse.self, from: data),
               let resultText = decodedResponse.candidates.first?.content.parts.first?.text {
                
                // محاولة استخراج JSON من رد النموذج
                if let jsonData = resultText.data(using: .utf8),
                   let jsonObject = try? JSONSerialization.jsonObject(with: jsonData) as? [String: String] {
                    let q = jsonObject["question"] ?? "غير معروف"
                    let a = jsonObject["answer"] ?? "لا توجد إجابة"
                    let e = jsonObject["explanation"]
                    completion(q, a, e)
                } else {
                    completion("سؤال مرصود", resultText, nil)
                }
            }
        }.resume()
    }
}
