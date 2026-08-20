import XCTest
@testable import AppDesignComponents

final class BodyMapTests: XCTestCase {
    func testShaderConfigurationCreatesMetalUniform() {
        let configuration = BodyMapShaderConfiguration(
            intensity: 0.8,
            glowEnergy: 0.4,
            shadowEnergy: 0.2
        )

        let uniform = configuration.metalUniform

        XCTAssertEqual(uniform.intensity, 0.8)
        XCTAssertEqual(uniform.glowEnergy, 0.4)
        XCTAssertEqual(uniform.shadowEnergy, 0.2)
    }
}
