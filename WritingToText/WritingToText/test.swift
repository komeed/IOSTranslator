//
//  test.swift
//  WritingToText
//
//  Created by Omeed on 1/3/25.
//

import Foundation
import SQLite
import LibreTranslate

struct MySequel{
    
    func translate(word: String) async -> String? {
        do {
            let translator = Translator("https://libretranslate.de")
            let translation = try await translator.translate(word, from: "en", to: "zh")
            return translation
        }
        catch {
            print(error)
            return nil
        }
    }
    func access(word: String, language: String) -> ChineseData?{
        do{
            print(word)
            if let bundlePath = Bundle.main.path(forResource: "chinese_dict", ofType: "db") {
                let dbFilePath = URL(fileURLWithPath: bundlePath)
                let db = try Connection(dbFilePath.path)
                let entries = Table("words")
                let ttext = Expression<String>("tword")
                let stext = Expression<String>("sword")
                let pinyin = Expression<String>("pinyin")
                let def = Expression<String>("def")
                var uttext:String = "";
                var ustext:String = "";
                var upinyin:String = "";
                let filteredEntries = entries.filter(stext == word)
                var definitions: [String] = []
                var traditional = true
                for entry in try db.prepare(filteredEntries){
                    traditional = false
                    definitions.append(entry[def])
                    uttext = entry[ttext]
                    ustext = entry[stext]
                    upinyin = entry[pinyin]
                }
                if(traditional){
                    let tfilteredEntries = entries.filter(ttext == word)
                    for entry in try db.prepare(tfilteredEntries){
                        definitions.append(entry[def])
                        uttext = entry[ttext]
                        ustext = entry[stext]
                        upinyin = entry[pinyin]
                    }
                }
                if(definitions.count == 0 && word.count > 1){
                    definitions.append("Couldn't find complete defn!")
                    for c in word {
                        let sfilteredEntries = entries.filter(stext == c.description)
                        var traditional = true
                        var tempPinyin = ""
                        for entry in try db.prepare(sfilteredEntries){
                            traditional = false
                            definitions.append(c.description + ": " + entry[def])
                            uttext = entry[ttext]
                            ustext = entry[stext]
                            tempPinyin = entry[pinyin]
                        }
                        if(traditional){
                            let tfilteredEntries = entries.filter(ttext == c.description)
                            for entry in try db.prepare(tfilteredEntries){
                                definitions.append(c.description + ": " + entry[def])
                                uttext = entry[ttext]
                                ustext = entry[stext]
                                tempPinyin = entry[pinyin]
                            }
                        }
                        upinyin += tempPinyin + " "
                    }
                }
                return ChineseData(ttext: uttext, stext: ustext, pinyin: upinyin, def: definitions)
            } else {
                print("Error: Database file not found in bundle")
            }
        }
        catch{
            print("error: " + String(describing: error))
            return nil
        }
        return nil
    }
}
struct ChineseData{
    var ttext: String
    var stext: String
    var pinyin: String
    var def: [String]
    init(ttext: String, stext: String, pinyin: String, def: [String]){
        self.ttext = ttext
        self.stext = stext
        self.pinyin = pinyin
        self.def = def
    }
}
