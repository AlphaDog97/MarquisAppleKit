import SwiftUI

/// Selects how `BodyMap` draws its anatomy layers.
///
/// The default mode uses the platform-optimized renderer. Static export mode
/// keeps the complete visual in SwiftUI so offscreen renderers such as
/// `ImageRenderer` can capture it deterministically.
public enum BodyMapRenderingMode: Sendable {
    case automatic
    case staticExport
}

private struct BodyMapRenderingModeKey: EnvironmentKey {
    static let defaultValue: BodyMapRenderingMode = .automatic
}

extension EnvironmentValues {
    var bodyMapRenderingMode: BodyMapRenderingMode {
        get { self[BodyMapRenderingModeKey.self] }
        set { self[BodyMapRenderingModeKey.self] = newValue }
    }
}

public extension View {
    func bodyMapRenderingMode(_ mode: BodyMapRenderingMode) -> some View {
        environment(\.bodyMapRenderingMode, mode)
    }
}
