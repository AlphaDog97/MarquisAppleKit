import Foundation

public enum BodyMapResourceLocation: Sendable {
    /// Load the anatomy artwork from the consuming app's asset catalog.
    /// This matches SomaTrack's existing FitnessBodyParts assets.
    case hostApp

    /// Load anatomy artwork packaged with AppDesignComponents.
    case package
}

public struct BodyMapResourceConfiguration: Sendable {
    public let model: BodyMapModel
    public let location: BodyMapResourceLocation

    public init(
        model: BodyMapModel,
        location: BodyMapResourceLocation = .hostApp
    ) {
        self.model = model
        self.location = location
    }

    var bundle: Bundle {
        switch location {
        case .hostApp:
            .main
        case .package:
            .module
        }
    }
}
