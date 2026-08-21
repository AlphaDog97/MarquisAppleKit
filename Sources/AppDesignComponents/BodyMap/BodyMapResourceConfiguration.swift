import Foundation

public enum BodyMapResourceLocation: Sendable {
    /// Load anatomy artwork packaged with AppDesignComponents.
    /// This is the default so consuming apps do not need their own BodyMap assets.
    case package

    /// Load compatible anatomy artwork from the consuming app's asset catalog.
    /// Kept as an opt-in escape hatch for apps that intentionally override the artwork.
    case hostApp
}

public struct BodyMapResourceConfiguration: Sendable {
    public let model: BodyMapModel
    public let location: BodyMapResourceLocation

    public init(
        model: BodyMapModel,
        location: BodyMapResourceLocation = .package
    ) {
        self.model = model
        self.location = location
    }

    var bundle: Bundle {
        switch location {
        case .package:
            .module
        case .hostApp:
            .main
        }
    }
}
