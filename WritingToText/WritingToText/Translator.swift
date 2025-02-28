import Foundation
import SwiftUI
import Translation
import Combine

struct Translator: View {
    @ObservedObject var broadcaster: MessageBroadcaster
    @State private var configuration: TranslationSession.Configuration?
    @State private var input: String? = nil
    var body: some View {
        if let inp = broadcaster.inputText {
            Color.clear
                .onAppear(){
                    print("works " + inp)
                    self.input = inp
                    //broadcaster.inputText = nil
                    triggerTranslation()
                }
        }
        Color.clear
            .translationTask(configuration) { session in
                do {
                    print(self.input ?? "hi")
                    // Use the session the task provides to translate the text.
                    let response = try await session.translate(self.input ?? "")
                    print("response: " + response.targetText)
                    broadcaster.inputText = nil
                    self.input = nil
                    broadcaster.outputText = response.targetText
                    //configuration?.invalidate()
                   // broadcaster.finishedProcessing = true
                } catch {
                    print("Translating Error: " + String(describing: error))
                    broadcaster.outputText = nil
                    broadcaster.inputText = nil
                  //  broadcaster.finishedProcessing = true
                }
            }
    }
    private func triggerTranslation() {
        guard configuration == nil else {
            print("configuration error")
            configuration?.invalidate()
            return
        }
        
        // Let the framework automatically determine the language pairing.
        configuration = .init()
    }
}
class MessageBroadcaster: ObservableObject {
    @Published var inputText: String? = nil
    @Published var outputText: String? = nil
    @Published var startedProcessing: Bool = false
}
