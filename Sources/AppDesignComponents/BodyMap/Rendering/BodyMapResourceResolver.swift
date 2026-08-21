import Foundation

struct BodyMapResourceResolver {
    static let humanBodySubdirectory = "BodyMap/HumanBody"

    init() {}

    func pdfURL(named name: String, bundle: Bundle) -> URL? {
        bundle.url(
            forResource: name,
            withExtension: "pdf",
            subdirectory: Self.humanBodySubdirectory
        ) ?? bundle.url(
            forResource: name,
            withExtension: "pdf"
        )
    }

    func textureName(for model: BodyMapModel) -> String {
        switch model {
        case .male:
            return "body_map_male"
        case .female:
            return "body_map_female"
        }
    }
}
