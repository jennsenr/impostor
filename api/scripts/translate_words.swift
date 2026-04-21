import Foundation
import Translation
import Darwin

struct CLI {
    let inputPath: String
    let outputPath: String

    init(arguments: [String]) {
        if arguments.count >= 3 {
            inputPath = arguments[1]
            outputPath = arguments[2]
        } else if arguments.count == 2 {
            inputPath = arguments[1]
            outputPath = arguments[1]
        } else {
            inputPath = "api/internal/infrastructure/data/words.json"
            outputPath = inputPath
        }
    }
}

@main
struct TranslateWordsRunner {
    static func main() async {
        do {
            let cli = CLI(arguments: CommandLine.arguments)
            let inputURL = URL(fileURLWithPath: cli.inputPath)
            let outputURL = URL(fileURLWithPath: cli.outputPath)

            let data = try Data(contentsOf: inputURL)
            guard var items = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
                throw NSError(domain: "translate_words", code: 1, userInfo: [
                    NSLocalizedDescriptionKey: "Input JSON is not an array of objects.",
                ])
            }

            let missingTexts = Array(
                Set(
                    items.compactMap { item -> String? in
                        guard let text = item["text"] as? String, !text.isEmpty else {
                            return nil
                        }
                        let existingTranslation = (item["text_en"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                        return existingTranslation.isEmpty ? text : nil
                    }
                )
            ).sorted()

            if missingTexts.isEmpty {
                print("No missing English translations found.")
                return
            }

            let session = TranslationSession(
                installedSource: Locale.Language(identifier: "es"),
                target: Locale.Language(identifier: "en")
            )
            try await session.prepareTranslation()

            var translations: [String: String] = [:]
            let batchSize = 25

            for start in stride(from: 0, to: missingTexts.count, by: batchSize) {
                let end = min(start + batchSize, missingTexts.count)
                let chunk = Array(missingTexts[start..<end])
                let requests = chunk.map { text in
                    TranslationSession.Request(sourceText: text, clientIdentifier: text)
                }

                let responses = try await session.translations(from: requests)
                for response in responses {
                    translations[response.clientIdentifier ?? response.sourceText] = response.targetText
                }

                print("Translated \(end)/\(missingTexts.count)")
                fflush(stdout)
            }

            for index in items.indices {
                guard let text = items[index]["text"] as? String, !text.isEmpty else {
                    continue
                }
                if let translation = translations[text], !translation.isEmpty {
                    items[index]["text_en"] = translation
                } else if items[index]["text_en"] == nil {
                    items[index]["text_en"] = text
                }
            }

            let outputData = try JSONSerialization.data(
                withJSONObject: items,
                options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
            )
            try outputData.write(to: outputURL)
            print("Wrote translated dataset to \(outputURL.path)")
            fflush(stdout)
        } catch {
            fputs("translate_words failed: \(error)\n", stderr)
            exit(1)
        }
    }
}
