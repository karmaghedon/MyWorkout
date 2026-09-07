import Foundation

protocol BodyMeasurementLogRepository {
    func load() throws -> [BodyMeasurementLog]

    func save(
        _ logs: [BodyMeasurementLog]
    ) throws
}
