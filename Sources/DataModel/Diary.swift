import Foundation
import CoreData

@objc(Diary)
public class Diary: NSManagedObject, Identifiable {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Diary> {
        NSFetchRequest<Diary>(entityName: "Diary")
    }

    @NSManaged public var id: UUID
    @NSManaged public var date: Date
    @NSManaged public var title: String
    @NSManaged public var text: String?
    @NSManaged public var rating: Int16
    @NSManaged public var tags: [String]?
    @NSManaged public var placeName: String?
    @NSManaged public var imagePath: String?
}


