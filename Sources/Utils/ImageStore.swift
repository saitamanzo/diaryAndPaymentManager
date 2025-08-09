import Foundation
import UIKit

enum ImageStore {
    static func documentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    static func save(image: UIImage, quality: CGFloat = 0.9) throws -> String {
        let filename = UUID().uuidString + ".jpg"
        let url = documentsDirectory().appendingPathComponent(filename)
        guard let data = image.jpegData(compressionQuality: quality) else {
            throw NSError(domain: "ImageStore", code: -1, userInfo: [NSLocalizedDescriptionKey: "JPEG変換に失敗"])
        }
        try data.write(to: url, options: .atomic)
        return url.lastPathComponent
    }

    static func load(path: String) -> UIImage? {
        let url = documentsDirectory().appendingPathComponent(path)
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        return UIImage(contentsOfFile: url.path)
    }
}


