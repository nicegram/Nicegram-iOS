import Foundation

struct PathProcessor {

    let data: String

    func commands() throws -> [Path.Command] {
        let parser = Path.ComponentParser()
        let components = try Path.Component.components(from: data)
        return try parser.parse(components)
    }
}
