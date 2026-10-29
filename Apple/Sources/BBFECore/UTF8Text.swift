import Foundation

/// Strict UTF-8 loading without treating a leading U+FEFF as disposable metadata.
public enum UTF8Text {
    public static func decode(_ data: Data) throws -> String {
        let text = String(decoding: data, as: UTF8.self)
        guard text.utf8.elementsEqual(data) else { throw BBFEError("Input is not valid UTF-8.") }
        return text
    }
}
