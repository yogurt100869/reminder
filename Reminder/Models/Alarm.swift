import Foundation
import SwiftData

@Model
final class Alarm {
    @Attribute(.unique) var id: UUID
    var title: String
    var fireDate: Date
    var createdAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        fireDate: Date,
        createdAt: Date = .now
    ) {
        self.id = id
        self.title = title
        self.fireDate = fireDate
        self.createdAt = createdAt
    }
}
