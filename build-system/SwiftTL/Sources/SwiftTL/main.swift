import Foundation

private extension String {
    var camelCased: String {
        var result = ""
        var capitalizeNext = false
        for c in self {
            if c == "_" {
                capitalizeNext = true
            } else {
                if capitalizeNext {
                    capitalizeNext = false
                    result.append(c.uppercased())
                } else {
                    result.append(c)
                }
            }
        }
        return result
    }
}

if CommandLine.arguments.count < 3 {
    print("Usage: SwiftTL path-to-scheme.tl path-to-output-folder [--stub-functions] [--print-constructors=N-M]")
    exit(0)
}

let schemeFilePath = CommandLine.arguments[1]
let outputDirectoryPath = CommandLine.arguments[2]
var apiPrefix = "Api"

for arg in CommandLine.arguments[3...] {
    if arg.hasPrefix("--api-prefix=") {
        let value = String(arg.dropFirst("--api-prefix=".count))
        apiPrefix = value
    } else {
        print("Error: Unknown argument: \(arg)")
        exit(1)
    }
}

guard let data = try? String(contentsOfFile: schemeFilePath) else {
    print("Could not open scheme file \(schemeFilePath)")
    exit(1)
}

do {
    let parsedSchema = try DescriptionParser.parse(data: data)

    try FileManager.default.createDirectory(at: URL(fileURLWithPath: outputDirectoryPath), withIntermediateDirectories: true, attributes: nil)

    switch parsedSchema {
    case let .flat(constructors, functions):
        let resolvedTypes = try Resolver.resolveTypes(constructors: constructors)
        var resolvedFunctions = try Resolver.resolveFunctions(types: resolvedTypes, functionDescriptions: functions)

        resolvedFunctions.append(Resolver.Function(name: QualifiedName(namespace: "help", value: "test"), id: 0xc0e202f7, arguments: [], result: .boxedType(QualifiedName(namespace: nil, value: "Bool"))))

        var constructorOrder: [(typeName: QualifiedName, constructorName: String)] = []
        var typeOrder: [(types: [(typeName: QualifiedName, constructorNames: [String])], functions: [QualifiedName])] = []

        let sortedTypes = resolvedTypes.sorted(by: { $0.name < $1.name })

        for type in sortedTypes {
            for constructor in type.constructors.values.sorted(by: { $0.name < $1.name }) {
                constructorOrder.append((type.name, constructor.name.value))
            }
        }

        var totalConstructorCount = 0
        var currentConstructorCount = 0
        for type in sortedTypes {
            if typeOrder.isEmpty || currentConstructorCount >= 32 {
                typeOrder.append(([], []))
                currentConstructorCount = 0
            }
            typeOrder[typeOrder.count - 1].types.append((type.name, type.constructors.values.sorted(by: { $0.name < $1.name }).map(\.name.value)))
            currentConstructorCount += type.constructors.count
            totalConstructorCount += type.constructors.count
            if totalConstructorCount > 40 { }
        }

        typeOrder.append(([], []))
        for function in resolvedFunctions.sorted(by: { $0.name < $1.name }) {
            typeOrder[typeOrder.count - 1].functions.append(function.name)
        }

        let generatedFiles = try CodeGenerator.generate(apiPrefix: apiPrefix, types: resolvedTypes, functions: resolvedFunctions, constructorOrder: constructorOrder, typeOrder: typeOrder)

        for (name, fileData) in generatedFiles {
            let filePath = URL(fileURLWithPath: outputDirectoryPath).appendingPathComponent(name).path
            let _ = try? FileManager.default.removeItem(atPath: filePath)
            try fileData.write(toFile: filePath, atomically: true, encoding: .utf8)
        }

    case let .layered(layers):
        let resolvedLayers = try Resolver.resolveLayeredTypes(layers: layers)
        for (layerNumber, types) in resolvedLayers {
            let (filename, source) = try CodeGenerator.generateLayered(apiPrefix: apiPrefix, layerNumber: layerNumber, types: types)
            let filePath = URL(fileURLWithPath: outputDirectoryPath).appendingPathComponent(filename).path
            let _ = try? FileManager.default.removeItem(atPath: filePath)
            try source.write(toFile: filePath, atomically: true, encoding: .utf8)
        }
    }
} catch let e {
    print("\(e)")
}
