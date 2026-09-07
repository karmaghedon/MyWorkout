import Foundation

@MainActor
protocol BodyMeasurementLogReplacing {
    func replaceAll(
        with newLogs: [BodyMeasurementLog]
    )
}

extension BodyMeasurementLogStore:
    BodyMeasurementLogReplacing {}
