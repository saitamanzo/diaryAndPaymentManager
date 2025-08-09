import Foundation
import CoreData

@objc(Payment)
public class Payment: NSManagedObject, Identifiable {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Payment> {
        NSFetchRequest<Payment>(entityName: "Payment")
    }

    @NSManaged public var id: UUID
    @NSManaged public var date: Date
    @NSManaged public var amount: NSDecimalNumber
    @NSManaged public var category: String
    @NSManaged public var note: String?
}


