/*: 
# JSONCorePlayground
A playground that imports JSONCore.

Note:
You must run this playground inside the JSONCoreDemo workspace, or the import will fail.
*/

import JSONCore

func extractTestInt(json: String) -> Int64? {
    do {
        let value = try JSONParser.parseData(json.unicodeScalars)
        // value is a JSONValue enum, which for our JSON should be
        // an Object/Dictionary
        guard let test = value.object?["test"]?.int else { return nil }
        return test
    } catch let err {
        if let printableError = err as? CustomStringConvertible {
            print("JSON parse error: \(printableError)")
        }
        return nil
    }
}

let json = "{\"test\": 1}"
let test = extractTestInt(json)
print("test is \(test)")
