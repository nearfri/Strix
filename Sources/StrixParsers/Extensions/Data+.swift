import Foundation

extension Data {
    func hexStringRepresentation(uppercase: Bool = false) -> String {
        let hexDigits: [Unicode.Scalar] = {
            let hexString = uppercase ? "0123456789ABCDEF" : "0123456789abcdef"
            return Array(hexString.unicodeScalars)
        }()
        
        return String(reduce(into: "".unicodeScalars, { hexList, byte in
            hexList.append(hexDigits[Int(byte / 0x10)])
            hexList.append(hexDigits[Int(byte % 0x10)])
        }))
    }
}
