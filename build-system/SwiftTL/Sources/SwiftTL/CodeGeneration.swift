import Foundation

private let reservedIdentifiers: [String] = [
    "protocol",
    "private"
]

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

    var camelCasedAndEscaped: String {
        var result = self.camelCased

        if reservedIdentifiers.contains(result) {
            result = "`\(result)`"
        }

        return result
    }
}

private struct CodeWriter {
    private var code: String = ""
    private var indentLevel: Int = 0
    private let indentString: String = "    "

    private var currentIndent: String {
        String(repeating: indentString, count: indentLevel)
    }

    mutating func indent() {
        indentLevel += 1
    }

    mutating func dedent() {
        indentLevel = max(0, indentLevel - 1)
    }

    mutating func line(_ text: String = "") {
        if text.isEmpty {
            code += "\n"
        } else {
            code += currentIndent + text + "\n"
        }
    }

    mutating func lines(_ text: String) {
        for line in text.split(separator: "\n", omittingEmptySubsequences: false) {
            if line.isEmpty {
                code += "\n"
            } else {
                code += currentIndent + line + "\n"
            }
        }
    }

    func output() -> String {
        return code
    }
}

/*private extension QualifiedName {
    var camelCased: String {
        if let namespace = self.namespace {
            return "\(namespace).\(self.value.camelCased)"
        } else {
            return self.value.camelCased
        }
    }
}*/

private func typeReferenceRepresentation(_ apiPrefix: String, _ type: Resolver.TypeReference) -> String {
    switch type {
    case .int32:
        return "Int32"
    case .int64:
        return "Int64"
    case .int256:
        return "Int256"
    case .double:
        return "Double"
    case .bytes:
        return "Buffer"
    case .string:
        return "String"
    case .bool:
        return "Bool"
    case .boolTrue:
        return "bool"
    case let .bareVector(elementType):
        return "[\(typeReferenceRepresentation(apiPrefix, elementType))]"
    case let .boxedVector(elementType):
        return "[\(typeReferenceRepresentation(apiPrefix, elementType))]"
    case let .bareConstructor(typeName, _):
        return "\(apiPrefix).\(typeName)"
    case let .boxedType(typeName):
        return "\(apiPrefix).\(typeName)"
    }
}

private extension Resolver.SumType {
    func hasDirectReference(to otherTypes: [Resolver.SumType], typeMap: [QualifiedName: Resolver.SumType]) throws -> Bool {
        for (_, constructor) in self.constructors {
            for argument in constructor.arguments {
                switch argument.type {
                case .int32:
                    break
                case .int64:
                    break
                case .int256:
                    break
                case .double:
                    break
                case .bytes:
                    break
                case .string:
                    break
                case .bool:
                    break
                case .boolTrue:
                    break
                case .bareVector:
                    break
                case .boxedVector:
                    break
                case .bareConstructor(let typeName, _), .boxedType(let typeName):
                    for otherType in otherTypes {
                        if typeName == otherType.name {
                            return true
                        }
                    }
                    
                    guard let referencedType = typeMap[typeName] else {
                        throw CodeGenerator.CodeGenerationError(text: "Type \(typeName) not found")
                    }
                    
                    var mergedTypes = otherTypes
                    if !mergedTypes.contains(where: { $0.name == self.name }) {
                        mergedTypes.append(self)
                    }
                    
                    if try referencedType.hasDirectReference(to: mergedTypes, typeMap: typeMap) {
                        return true
                    }
                }
            }
        }
        
        return false
    }
}

private extension Sequence where Iterator.Element: Hashable {
    func unique() -> [Iterator.Element] {
        var seen: Set<Iterator.Element> = []
        return filter { seen.insert($0).inserted }
    }
}

enum CodeGenerator {
    struct CodeGenerationError: Error, CustomStringConvertible {
        var text: String
        
        var description: String {
            return self.text
        }
    }
    
    static func generate(apiPrefix: String, types: [Resolver.SumType], functions: [Resolver.Function], constructorOrder: [(typeName: QualifiedName, constructorName: String)], typeOrder: [(types: [(typeName: QualifiedName, constructorNames: [String])], functions: [QualifiedName])]) throws -> [String: String] {
        var files: [String: String] = [:]
        
        var functions = functions
        functions.append(Resolver.Function(name: QualifiedName(namespace: "help", value: "test"), id: UInt32(bitPattern: -1058929929), arguments: [], result: .boxedType(QualifiedName(namespace: nil, value: "Bool"))))

        files["\(apiPrefix)0.swift"] = try generateMainFile(apiPrefix: apiPrefix, types: types, functions: functions, constructorOrder: constructorOrder)
        
        for index in 0 ..< typeOrder.count {
            files["\(apiPrefix)\(index + 1).swift"] = try generateImplFile(apiPrefix: apiPrefix, types: types, functions: functions, typeOrder: typeOrder[index])
        }
        
        return files
    }

    static func generateLayered(
        apiPrefix: String,
        layerNumber: Int,
        types: [Resolver.SumType]
    ) throws -> (filename: String, source: String) {
        let structName = "\(apiPrefix)\(layerNumber)"
        let filename = "\(apiPrefix)Layer\(layerNumber).swift"

        // All nested type refs (inside the struct) use `structName` as their prefix —
        // `apiPrefix` is used only to compute `structName` and `filename`. Helpers like
        // typeReferenceRepresentation and generateFieldParsing get `structName`, not
        // `apiPrefix`, so e.g. fields render as `media: SecretApi8.DecryptedMessageMedia`.

        var typeMap: [QualifiedName: Resolver.SumType] = [:]
        for type in types {
            typeMap[type.name] = type
        }

        // Detect whether any constructor argument uses Int256; if so, we need the int256 parser entry.
        var usesInt256 = false
        outer: for type in types {
            for (_, constructor) in type.constructors {
                for argument in constructor.arguments {
                    if containsInt256(argument.type) { usesInt256 = true; break outer }
                }
            }
        }

        var writer = CodeWriter()
        writer.line()

        // File-scope dispatch table
        writer.line("fileprivate let parsers: [Int32 : (BufferReader) -> Any?] = {")
        writer.indent()
        writer.line("var dict: [Int32 : (BufferReader) -> Any?] = [:]")
        writer.line("dict[-1471112230] = { return $0.readInt32() }")
        writer.line("dict[570911930] = { return $0.readInt64() }")
        writer.line("dict[571523412] = { return $0.readDouble() }")
        writer.line("dict[-1255641564] = { return parseString($0) }")
        if usesInt256 {
            writer.line("dict[0x0929C32F] = { return parseInt256($0) }")
        }

        let sortedTypes = types.sorted(by: { $0.name < $1.name })
        for type in sortedTypes {
            let sortedConstructors = type.constructors.values.sorted(by: { $0.name < $1.name })
            for constructor in sortedConstructors {
                writer.line("dict[\(Int32(bitPattern: constructor.id))] = { return \(structName).\(type.name).parse_\(constructor.name.value)($0) }")
            }
        }
        writer.line("return dict")
        writer.dedent()
        writer.line("}()")
        writer.line()

        // public struct {apiPrefix}{N} {
        writer.line("public struct \(structName) {")
        writer.indent()

        // public static func parse(_ buffer: Buffer) -> Any?
        writer.line("public static func parse(_ buffer: Buffer) -> Any? {")
        writer.indent()
        writer.line("let reader = BufferReader(buffer)")
        writer.line("if let signature = reader.readInt32() {")
        writer.indent()
        writer.line("return parse(reader, signature: signature)")
        writer.dedent()
        writer.line("}")
        writer.line("return nil")
        writer.dedent()
        writer.line("}")
        writer.line()

        // fileprivate static func parse(_ reader: BufferReader, signature: Int32) -> Any?
        writer.line("fileprivate static func parse(_ reader: BufferReader, signature: Int32) -> Any? {")
        writer.indent()
        writer.line("if let parser = parsers[signature] {")
        writer.indent()
        writer.line("return parser(reader)")
        writer.dedent()
        writer.line("}")
        writer.line("else {")
        writer.indent()
        writer.line("telegramApiLog(\"Type constructor \\(String(signature, radix: 16, uppercase: false)) not found\")")
        writer.line("return nil")
        writer.dedent()
        writer.line("}")
        writer.dedent()
        writer.line("}")
        writer.line()

        // fileprivate static func parseVector
        writer.line("fileprivate static func parseVector<T>(_ reader: BufferReader, elementSignature: Int32, elementType: T.Type) -> [T]? {")
        writer.indent()
        writer.line("if let count = reader.readInt32() {")
        writer.indent()
        writer.line("var array = [T]()")
        writer.line("var i: Int32 = 0")
        writer.line("while i < count {")
        writer.indent()
        writer.line("var signature = elementSignature")
        writer.line("if elementSignature == 0 {")
        writer.indent()
        writer.line("if let unboxedSignature = reader.readInt32() {")
        writer.indent()
        writer.line("signature = unboxedSignature")
        writer.dedent()
        writer.line("}")
        writer.line("else {")
        writer.indent()
        writer.line("return nil")
        writer.dedent()
        writer.line("}")
        writer.dedent()
        writer.line("}")
        writer.line("if let item = \(structName).parse(reader, signature: signature) as? T {")
        writer.indent()
        writer.line("array.append(item)")
        writer.dedent()
        writer.line("}")
        writer.line("else {")
        writer.indent()
        writer.line("return nil")
        writer.dedent()
        writer.line("}")
        writer.line("i += 1")
        writer.dedent()
        writer.line("}")
        writer.line("return array")
        writer.dedent()
        writer.line("}")
        writer.line("return nil")
        writer.dedent()
        writer.line("}")
        writer.line()

        // public static func serializeObject
        writer.line("public static func serializeObject(_ object: Any, buffer: Buffer, boxed: Swift.Bool) {")
        writer.indent()
        writer.line("switch object {")
        for type in sortedTypes {
            writer.line("case let _1 as \(structName).\(type.name):")
            writer.indent()
            writer.line("_1.serialize(buffer, boxed)")
            writer.dedent()
        }
        writer.line("default:")
        writer.indent()
        writer.line("break")
        writer.dedent()
        writer.line("}")
        writer.dedent()
        writer.line("}")
        writer.line()

        // Nested public enum <TypeName> { ... } for each type
        for type in sortedTypes {
            try emitLayeredType(writer: &writer, structName: structName, type: type, typeMap: typeMap)
        }

        writer.dedent()
        writer.line("}") // close public struct

        return (filename, writer.output())
    }

    private static func containsInt256(_ type: Resolver.TypeReference) -> Bool {
        switch type {
        case .int256:
            return true
        case .bareVector(let element), .boxedVector(let element):
            return containsInt256(element)
        case .int32, .int64, .double, .bytes, .string, .bool, .boolTrue, .bareConstructor, .boxedType:
            return false
        }
    }

    private static func emitLayeredType(
        writer: inout CodeWriter,
        structName: String,
        type: Resolver.SumType,
        typeMap: [QualifiedName: Resolver.SumType]
    ) throws {
        let sortedConstructors = type.constructors.values.sorted(by: { $0.name < $1.name })

        let indirectPrefix = try type.hasDirectReference(to: [type], typeMap: typeMap) ? "indirect " : ""
        writer.line("\(indirectPrefix)public enum \(type.name.value) {")
        writer.indent()

        // case <ctor>(<args>)  -- inline-args shape
        for constructor in sortedConstructors {
            var argumentsString = ""
            for argument in constructor.arguments {
                if case .boolTrue = argument.type { continue }
                if !argumentsString.isEmpty { argumentsString.append(", ") }
                argumentsString.append(argument.name.camelCased)
                argumentsString.append(": ")
                argumentsString.append(typeReferenceRepresentation(structName, argument.type))
                if argument.condition != nil { argumentsString.append("?") }
            }
            writer.line("case \(constructor.name.value)\(argumentsString.isEmpty ? "" : "(\(argumentsString))")")
        }
        writer.line()

        // public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool)
        writer.line("public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {")
        writer.indent()
        writer.line("switch self {")
        for constructor in sortedConstructors {
            var bindString = ""
            for argument in constructor.arguments {
                if case .boolTrue = argument.type { continue }
                if !bindString.isEmpty { bindString.append(", ") }
                bindString.append("let ")
                bindString.append(argument.name.camelCasedAndEscaped)
            }
            writer.line("case .\(constructor.name.value)\(bindString.isEmpty ? "" : "(\(bindString))"):")
            writer.indent()
            writer.line("if boxed {")
            writer.indent()
            writer.line("buffer.appendInt32(\(Int32(bitPattern: constructor.id)))")
            writer.dedent()
            writer.line("}")

            for argument in constructor.arguments {
                if case .boolTrue = argument.type { continue }
                var argumentAccessor = "\(argument.name.camelCasedAndEscaped)"
                if let condition = argument.condition {
                    writer.line("if Int(\(condition.fieldName)) & Int(1 << \(condition.bitIndex)) != 0 {")
                    writer.indent()
                    argumentAccessor.append("!")
                    generateFieldSerialization(writer: &writer, argument: argument, argumentAccessor: argumentAccessor)
                    writer.dedent()
                    writer.line("}")
                } else {
                    generateFieldSerialization(writer: &writer, argument: argument, argumentAccessor: argumentAccessor)
                }
            }
            writer.line("break")
            writer.dedent()
        }
        writer.line("}")
        writer.dedent()
        writer.line("}")
        writer.line()

        // fileprivate static func parse_<ctor>(_ reader: BufferReader) -> <TypeName>?
        for constructor in sortedConstructors {
            writer.line("fileprivate static func parse_\(constructor.name.value)(_ reader: BufferReader) -> \(type.name.value)? {")
            writer.indent()
            if constructor.arguments.contains(where: { if case .boolTrue = $0.type { return false } else { return true } }) {
                var argumentIndex = 0
                var argumentCheckString = ""
                var argumentCollectionString = ""
                for argument in constructor.arguments {
                    if case .boolTrue = argument.type { continue }

                    writer.line("var _\(argumentIndex + 1): \(typeReferenceRepresentation(structName, argument.type))?")

                    if let condition = argument.condition {
                        guard let fieldIndex = constructor.arguments.filter({ if case .boolTrue = $0.type { return false } else { return true } }).firstIndex(where: { $0.name == condition.fieldName }) else {
                            throw CodeGenerationError(text: "Condition field \(condition.fieldName) not found")
                        }
                        writer.line("if Int(_\(fieldIndex + 1) ?? 0) & Int(1 << \(condition.bitIndex)) != 0 {")
                        writer.indent()
                        try generateFieldParsing(apiPrefix: structName, writer: &writer, typeMap: typeMap, argument: argument, argumentAccessor: "_\(argumentIndex + 1)")
                        writer.dedent()
                        writer.line("}")
                    } else {
                        try generateFieldParsing(apiPrefix: structName, writer: &writer, typeMap: typeMap, argument: argument, argumentAccessor: "_\(argumentIndex + 1)")
                    }

                    if !argumentCheckString.isEmpty { argumentCheckString.append(" && ") }
                    argumentCheckString.append("_c\(argumentIndex + 1)")

                    if !argumentCollectionString.isEmpty { argumentCollectionString.append(", ") }
                    argumentCollectionString.append("\(argument.name.camelCased): _\(argumentIndex + 1)")
                    if argument.condition == nil { argumentCollectionString.append("!") }

                    argumentIndex += 1
                }

                var checkIndex = 0
                for argument in constructor.arguments {
                    if case .boolTrue = argument.type { continue }
                    if let condition = argument.condition {
                        guard let fieldIndex = constructor.arguments.filter({ if case .boolTrue = $0.type { return false } else { return true } }).firstIndex(where: { $0.name == condition.fieldName }) else {
                            throw CodeGenerationError(text: "Condition field \(condition.fieldName) not found")
                        }
                        writer.line("let _c\(checkIndex + 1) = (Int(_\(fieldIndex + 1) ?? 0) & Int(1 << \(condition.bitIndex)) == 0) || _\(checkIndex + 1) != nil")
                    } else {
                        writer.line("let _c\(checkIndex + 1) = _\(checkIndex + 1) != nil")
                    }
                    checkIndex += 1
                }

                writer.line("if \(argumentCheckString) {")
                writer.indent()
                writer.line("return \(structName).\(type.name).\(constructor.name.value)\(argumentCollectionString.isEmpty ? "" : "(\(argumentCollectionString))")")
                writer.dedent()
                writer.line("}")
                writer.line("else {")
                writer.indent()
                writer.line("return nil")
                writer.dedent()
                writer.line("}")
            } else {
                writer.line("return \(structName).\(type.name).\(constructor.name.value)")
            }
            writer.dedent()
            writer.line("}")
        }

        writer.dedent()
        writer.line("}")
        writer.line()
    }

    private static func generateMainFile(apiPrefix: String, types: [Resolver.SumType], functions: [Resolver.Function], constructorOrder: [(typeName: QualifiedName, constructorName: String)]) throws -> String {
        var writer = CodeWriter()

        writer.line()

        var namespaces = Set<String>()
        for type in types {
            if let namespace = type.name.namespace {
                namespaces.insert(namespace)
            }
        }

        var functionNamespaces = Set<String>()
        for function in functions {
            if let namespace = function.name.namespace {
                functionNamespaces.insert(namespace)
            }
        }

        writer.line("public enum \(apiPrefix) {")
        writer.indent()
        for namespace in namespaces.sorted(by: { $0 < $1 }) {
            writer.line("public enum \(namespace) {}")
        }
        writer.line("public enum functions {")
        writer.indent()
        for namespace in functionNamespaces.sorted(by: { $0 < $1 }) {
            writer.line("public enum \(namespace) {}")
        }
        writer.dedent()
        writer.line("}")
        writer.dedent()
        writer.line("}")

        writer.line()

        var typeMap: [QualifiedName: Resolver.SumType] = [:]
        for type in types {
            typeMap[type.name] = type
        }

        writer.line("fileprivate let parsers: [Int32 : (BufferReader) -> Any?] = {")
        writer.indent()
        writer.line("var dict: [Int32 : (BufferReader) -> Any?] = [:]")
        writer.line("dict[-1471112230] = { return $0.readInt32() }")
        writer.line("dict[570911930] = { return $0.readInt64() }")
        writer.line("dict[571523412] = { return $0.readDouble() }")
        writer.line("dict[0x0929C32F] = { return parseInt256($0) }")
        writer.line("dict[-1255641564] = { return parseString($0) }")

        for (typeName, constructorName) in constructorOrder {
            guard let type = typeMap[typeName] else {
                throw CodeGenerationError(text: "Type \(typeName) not found")
            }

            var found = false
            for (_, constructor) in type.constructors {
                if constructor.name.value == constructorName {
                    found = true
                    writer.line("dict[\(Int32(bitPattern: constructor.id))] = { return \(apiPrefix).\(type.name).parse_\(constructor.name.value)($0) }")
                    break
                }
            }

            if !found {
                throw CodeGenerationError(text: "Constructor \(constructorName) not found")
            }
        }

        writer.line("return dict")
        writer.dedent()
        writer.line("}()")

        writer.line()

        writer.line("public extension \(apiPrefix) {")
        writer.indent()

        writer.line("static func parse(_ buffer: Buffer) -> Any? {")
        writer.indent()
        writer.line("let reader = BufferReader(buffer)")
        writer.line("if let signature = reader.readInt32() {")
        writer.indent()
        writer.line("return parse(reader, signature: signature)")
        writer.dedent()
        writer.line("}")
        writer.line("return nil")
        writer.dedent()
        writer.line("}")

        writer.line()

        writer.line("static func parse(_ reader: BufferReader, signature: Int32) -> Any? {")
        writer.indent()
        writer.line("if let parser = parsers[signature] {")
        writer.indent()
        writer.line("return parser(reader)")
        writer.dedent()
        writer.line("} else {")
        writer.indent()
        writer.line("telegramApiLog(\"Type constructor \\(String(UInt32(bitPattern: signature), radix: 16, uppercase: false)) not found\")")
        writer.line("return nil")
        writer.dedent()
        writer.line("}")
        writer.dedent()
        writer.line("}")

        writer.line()

        writer.line("static func parseVector<T>(_ reader: BufferReader, elementSignature: Int32, elementType: T.Type) -> [T]? {")
        writer.indent()
        writer.line("if let count = reader.readInt32() {")
        writer.indent()
        writer.line("var array = [T]()")
        writer.line("var i: Int32 = 0")
        writer.line("while i < count {")
        writer.indent()
        writer.line("var signature = elementSignature")
        writer.line("if elementSignature == 0 {")
        writer.indent()
        writer.line("if let unboxedSignature = reader.readInt32() {")
        writer.indent()
        writer.line("signature = unboxedSignature")
        writer.dedent()
        writer.line("} else {")
        writer.indent()
        writer.line("return nil")
        writer.dedent()
        writer.line("}")
        writer.dedent()
        writer.line("}")
        writer.line("if elementType == Buffer.self {")
        writer.indent()
        writer.line("if let item = parseBytes(reader) as? T {")
        writer.indent()
        writer.line("array.append(item)")
        writer.dedent()
        writer.line("} else {")
        writer.indent()
        writer.line("return nil")
        writer.dedent()
        writer.line("}")
        writer.dedent()
        writer.line("} else {")
        writer.indent()
        writer.line("if let item = \(apiPrefix).parse(reader, signature: signature) as? T {")
        writer.indent()
        writer.line("array.append(item)")
        writer.dedent()
        writer.line("} else {")
        writer.indent()
        writer.line("return nil")
        writer.dedent()
        writer.line("}")
        writer.dedent()
        writer.line("}")
        writer.line("i += 1")
        writer.dedent()
        writer.line("}")
        writer.line("return array")
        writer.dedent()
        writer.line("}")
        writer.line("return nil")
        writer.dedent()
        writer.line("}")

        writer.line()

        writer.line("static func serializeObject(_ object: Any, buffer: Buffer, boxed: Swift.Bool) {")
        writer.indent()
        writer.line("switch object {")

        let typeOrder = constructorOrder.map(\.typeName).unique()

        for typeName in typeOrder {
            guard let type = typeMap[typeName] else {
                throw CodeGenerationError(text: "Type \(typeName) not found")
            }

            writer.line("case let _1 as \(apiPrefix).\(type.name):")
            writer.indent()
            writer.line("_1.serialize(buffer, boxed)")
            writer.dedent()
        }

        writer.line("default:")
        writer.indent()
        writer.line("break")
        writer.dedent()
        writer.line("}")
        writer.dedent()
        writer.line("}")

        writer.dedent()
        writer.line("}")

        return writer.output()
    }
    
    private static func generateImplFile(apiPrefix: String, types: [Resolver.SumType], functions: [Resolver.Function], typeOrder: (types: [(typeName: QualifiedName, constructorNames: [String])], functions: [QualifiedName])) throws -> String {
        var writer = CodeWriter()

        var typeMap: [QualifiedName: Resolver.SumType] = [:]
        for type in types {
            typeMap[type.name] = type
        }

        for (typeName, constructorNames) in typeOrder.types {
            writer.line("public extension \(apiPrefix)\(typeName.namespace.flatMap { "." + $0 } ?? "") {")
            writer.indent()

            guard let type = typeMap[typeName] else {
                throw CodeGenerationError(text: "Type \(typeName) not found")
            }

            let indirectPrefix = try type.hasDirectReference(to: [type], typeMap: typeMap) ? "indirect " : ""
            writer.line("\(indirectPrefix)enum \(typeName.value): TypeConstructorDescription {")
            writer.indent()

            var sortedConstructors: [Resolver.SumType.Constructor] = []
            for constructorName in constructorNames {
                var foundConstructor: Resolver.SumType.Constructor?
                for (_, constructor) in type.constructors {
                    if constructor.name.value == constructorName {
                        foundConstructor = constructor
                        break
                    }
                }
                guard let constructor = foundConstructor else {
                    throw CodeGenerationError(text: "Constructor \(constructorName) -> \(typeName) not found")
                }
                sortedConstructors.append(constructor)
            }

            let useStructPattern = true

            if useStructPattern {
                for constructor in sortedConstructors {
                    var fieldsString = ""
                    var initParamsString = ""
                    var initBodyString = ""
                    var descriptionFieldsString = ""

                    for argument in constructor.arguments {
                        if case .boolTrue = argument.type {
                            continue
                        }

                        let fieldName = argument.name.camelCasedAndEscaped
                        let fieldType = typeReferenceRepresentation(apiPrefix, argument.type) + (argument.condition != nil ? "?" : "")

                        if !fieldsString.isEmpty {
                            fieldsString.append("\n")
                        }
                        fieldsString.append("public var \(fieldName): \(fieldType)")

                        if !initParamsString.isEmpty {
                            initParamsString.append(", ")
                        }
                        initParamsString.append("\(fieldName): \(fieldType)")

                        if !initBodyString.isEmpty {
                            initBodyString.append("\n")
                        }
                        initBodyString.append("self.\(fieldName) = \(fieldName)")

                        if !descriptionFieldsString.isEmpty {
                            descriptionFieldsString.append(", ")
                        }
                        descriptionFieldsString.append("(\"\(fieldName)\", ConstructorParameterDescription(self.\(fieldName)))")
                    }

                    if !fieldsString.isEmpty {
                        writer.line("public class Cons_\(constructor.name.value): TypeConstructorDescription {")
                        writer.indent()
                        writer.lines(fieldsString)
                        writer.line("public init(\(initParamsString)) {")
                        writer.indent()
                        writer.lines(initBodyString)
                        writer.dedent()
                        writer.line("}")
                        writer.line("public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {")
                        writer.indent()
                        writer.line("return (\"\(constructor.name.value)\", [\(descriptionFieldsString)])")
                        writer.dedent()
                        writer.line("}")
                        writer.dedent()
                        writer.line("}")
                    }
                }
            }

            for constructor in sortedConstructors {
                let hasFields = constructor.arguments.contains { if case .boolTrue = $0.type { return false } else { return true } }

                if useStructPattern && hasFields {
                    writer.line("case \(constructor.name.value)(Cons_\(constructor.name.value))")
                } else {
                    var argumentsString = ""
                    for argument in constructor.arguments {
                        if case .boolTrue = argument.type {
                            continue
                        }

                        if !argumentsString.isEmpty {
                            argumentsString.append(", ")
                        }

                        argumentsString.append(argument.name.camelCased)
                        argumentsString.append(": ")
                        argumentsString.append(typeReferenceRepresentation(apiPrefix, argument.type))
                        if argument.condition != nil {
                            argumentsString.append("?")
                        }
                    }

                    writer.line("case \(constructor.name.value)\(argumentsString.isEmpty ? "" : "(\(argumentsString))")")
                }
            }

            writer.line()
            writer.line("public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {")
            writer.indent()
            writer.line("switch self {")

            for constructor in sortedConstructors {
                let hasFields = constructor.arguments.contains { if case .boolTrue = $0.type { return false } else { return true } }

                if useStructPattern && hasFields {
                    writer.line("case .\(constructor.name.value)(let _data):")
                    writer.indent()
                    writer.line("if boxed {")
                    writer.indent()
                    writer.line("buffer.appendInt32(\(Int32(bitPattern: constructor.id)))")
                    writer.dedent()
                    writer.line("}")

                    for argument in constructor.arguments {
                        if case .boolTrue = argument.type {
                            continue
                        }

                        var argumentAccessor = "_data.\(argument.name.camelCasedAndEscaped)"
                        if let condition = argument.condition {
                            writer.line("if Int(_data.\(condition.fieldName.camelCasedAndEscaped)) & Int(1 << \(condition.bitIndex)) != 0 {")
                            writer.indent()
                            argumentAccessor.append("!")
                            generateFieldSerialization(writer: &writer, argument: argument, argumentAccessor: argumentAccessor)
                            writer.dedent()
                            writer.line("}")
                        } else {
                            generateFieldSerialization(writer: &writer, argument: argument, argumentAccessor: argumentAccessor)
                        }
                    }
                    writer.line("break")
                    writer.dedent()
                } else {
                    var argumentsString = ""
                    for argument in constructor.arguments {
                        if case .boolTrue = argument.type {
                            continue
                        }

                        if !argumentsString.isEmpty {
                            argumentsString.append(", ")
                        }

                        argumentsString.append("let ")
                        argumentsString.append(argument.name.camelCasedAndEscaped)
                    }

                    writer.line("case .\(constructor.name.value)\(argumentsString.isEmpty ? "" : "(\(argumentsString))"):")
                    writer.indent()
                    writer.line("if boxed {")
                    writer.indent()
                    writer.line("buffer.appendInt32(\(Int32(bitPattern: constructor.id)))")
                    writer.dedent()
                    writer.line("}")

                    for argument in constructor.arguments {
                        if case .boolTrue = argument.type {
                            continue
                        }

                        var argumentAccessor = "\(argument.name.camelCasedAndEscaped)"
                        if let condition = argument.condition {
                            writer.line("if Int(\(condition.fieldName)) & Int(1 << \(condition.bitIndex)) != 0 {")
                            writer.indent()
                            argumentAccessor.append("!")
                            generateFieldSerialization(writer: &writer, argument: argument, argumentAccessor: argumentAccessor)
                            writer.dedent()
                            writer.line("}")
                        } else {
                            generateFieldSerialization(writer: &writer, argument: argument, argumentAccessor: argumentAccessor)
                        }
                    }
                    writer.line("break")
                    writer.dedent()
                }
            }

            writer.line("}")
            writer.dedent()
            writer.line("}")

            writer.line()
            writer.line("public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {")
            writer.indent()
            writer.line("switch self {")

            for constructor in sortedConstructors {
                let hasFields = constructor.arguments.contains { if case .boolTrue = $0.type { return false } else { return true } }

                if useStructPattern && hasFields {
                    var argumentSerializationString = ""
                    for argument in constructor.arguments {
                        if case .boolTrue = argument.type {
                            continue
                        }

                        if !argumentSerializationString.isEmpty {
                            argumentSerializationString.append(", ")
                        }
                        argumentSerializationString.append("(\"\(argument.name.camelCasedAndEscaped)\", ConstructorParameterDescription(_data.\(argument.name.camelCasedAndEscaped)))")
                    }

                    writer.line("case .\(constructor.name.value)(let _data):")
                    writer.indent()
                    writer.line("return (\"\(constructor.name.value)\", [\(argumentSerializationString)])")
                    writer.dedent()
                } else {
                    var argumentsString = ""
                    var argumentSerializationString = ""
                    for argument in constructor.arguments {
                        if case .boolTrue = argument.type {
                            continue
                        }

                        if !argumentsString.isEmpty {
                            argumentsString.append(", ")
                        }
                        if !argumentSerializationString.isEmpty {
                            argumentSerializationString.append(", ")
                        }

                        argumentsString.append("let ")
                        argumentsString.append(argument.name.camelCasedAndEscaped)

                        argumentSerializationString.append("(\"\(argument.name.camelCasedAndEscaped)\", \(argument.name.camelCasedAndEscaped) as Any)")
                    }

                    writer.line("case .\(constructor.name.value)\(argumentsString.isEmpty ? "" : "(\(argumentsString))"):")
                    writer.indent()
                    writer.line("return (\"\(constructor.name.value)\", [\(argumentSerializationString)])")
                    writer.dedent()
                }
            }

            writer.line("}")
            writer.dedent()
            writer.line("}")

            writer.line()

            for constructor in sortedConstructors {
                writer.line("public static func parse_\(constructor.name.value)(_ reader: BufferReader) -> \(typeName.value)? {")
                writer.indent()
                if constructor.arguments.contains(where: { if case .boolTrue = $0.type { return false } else { return true } }) {
                    var argumentIndex = 0
                    var argumentCheckString = ""
                    var argumentCollectionString = ""
                    for argument in constructor.arguments {
                        if case .boolTrue = argument.type {
                            continue
                        }

                        writer.line("var _\(argumentIndex + 1): \(typeReferenceRepresentation(apiPrefix, argument.type))?")

                        if let condition = argument.condition {
                            guard let fieldIndex = constructor.arguments.filter({ if case .boolTrue = $0.type { return false } else { return true } }).firstIndex(where: { $0.name == condition.fieldName }) else {
                                throw CodeGenerationError(text: "Condition field \(condition.fieldName) not found")
                            }

                            writer.line("if Int(_\(fieldIndex + 1) ?? 0) & Int(1 << \(condition.bitIndex)) != 0 {")
                            writer.indent()
                            try generateFieldParsing(apiPrefix: apiPrefix, writer: &writer, typeMap: typeMap, argument: argument, argumentAccessor: "_\(argumentIndex + 1)")
                            writer.dedent()
                            writer.line("}")
                        } else {
                            try generateFieldParsing(apiPrefix: apiPrefix, writer: &writer, typeMap: typeMap, argument: argument, argumentAccessor: "_\(argumentIndex + 1)")
                        }

                        if !argumentCheckString.isEmpty {
                            argumentCheckString.append(" && ")
                        }
                        argumentCheckString.append("_c\(argumentIndex + 1)")

                        if !argumentCollectionString.isEmpty {
                            argumentCollectionString.append(", ")
                        }
                        argumentCollectionString.append("\(argument.name.camelCased): _\(argumentIndex + 1)")
                        if argument.condition == nil {
                            argumentCollectionString.append("!")
                        }

                        argumentIndex += 1
                    }

                    var checkIndex = 0
                    for argument in constructor.arguments {
                        if case .boolTrue = argument.type {
                            continue
                        }

                        if let condition = argument.condition {
                            guard let fieldIndex = constructor.arguments.filter({ if case .boolTrue = $0.type { return false } else { return true } }).firstIndex(where: { $0.name == condition.fieldName }) else {
                                throw CodeGenerationError(text: "Condition field \(condition.fieldName) not found")
                            }

                            writer.line("let _c\(checkIndex + 1) = (Int(_\(fieldIndex + 1) ?? 0) & Int(1 << \(condition.bitIndex)) == 0) || _\(checkIndex + 1) != nil")
                        } else {
                            writer.line("let _c\(checkIndex + 1) = _\(checkIndex + 1) != nil")
                        }

                        checkIndex += 1
                    }

                    writer.line("if \(argumentCheckString) {")
                    writer.indent()
                    if useStructPattern && !argumentCollectionString.isEmpty {
                        writer.line("return \(apiPrefix).\(typeName).\(constructor.name.value)(Cons_\(constructor.name.value)(\(argumentCollectionString)))")
                    } else {
                        writer.line("return \(apiPrefix).\(typeName).\(constructor.name.value)\(argumentCollectionString.isEmpty ? "" : "(\(argumentCollectionString))")")
                    }
                    writer.dedent()
                    writer.line("}")
                    writer.line("else {")
                    writer.indent()
                    writer.line("return nil")
                    writer.dedent()
                    writer.line("}")
                } else {
                    writer.line("return \(apiPrefix).\(typeName).\(constructor.name.value)")
                }

                writer.dedent()
                writer.line("}")
            }

            writer.dedent()
            writer.line("}")
            writer.dedent()
            writer.line("}")
        }

        if !typeOrder.functions.isEmpty {
            for functionName in typeOrder.functions {
                writer.line("public extension \(apiPrefix).functions\(functionName.namespace.flatMap { "." + $0 } ?? "") {")
                writer.indent()

                var foundFunction: Resolver.Function?
                for function in functions {
                    if function.name == functionName {
                        foundFunction = function
                        break
                    }
                }
                guard let function = foundFunction else {
                    throw CodeGenerationError(text: "Function \(functionName) not found")
                }

                var argumentsString = ""
                for argument in function.arguments {
                    if case .boolTrue = argument.type {
                        continue
                    }

                    if !argumentsString.isEmpty {
                        argumentsString.append(", ")
                    }

                    argumentsString.append(argument.name.camelCasedAndEscaped)
                    argumentsString.append(": ")
                    argumentsString.append(typeReferenceRepresentation(apiPrefix, argument.type))
                    if argument.condition != nil {
                        argumentsString.append("?")
                    }
                }

                writer.line("static func \(function.name.value)(\(argumentsString)) -> (FunctionDescription, Buffer, DeserializeFunctionResponse<\(typeReferenceRepresentation(apiPrefix, function.result))>) {")
                writer.indent()
                writer.line("let buffer = Buffer()")
                writer.line("buffer.appendInt32(\(Int32(bitPattern: function.id)))")

                var argumentSerializationString = ""
                for argument in function.arguments {
                    if case .boolTrue = argument.type {
                        continue
                    }

                    var argumentAccessor = "\(argument.name.camelCasedAndEscaped)"
                    if let condition = argument.condition {
                        guard let _ = function.arguments.filter({ if case .boolTrue = $0.type { return false } else { return true } }).firstIndex(where: { $0.name == condition.fieldName }) else {
                            throw CodeGenerationError(text: "Condition field \(condition.fieldName) not found")
                        }

                        writer.line("if Int(\(condition.fieldName)) & Int(1 << \(condition.bitIndex)) != 0 {")
                        writer.indent()
                        argumentAccessor.append("!")
                        generateFieldSerialization(writer: &writer, argument: argument, argumentAccessor: argumentAccessor)
                        writer.dedent()
                        writer.line("}")
                    } else {
                        generateFieldSerialization(writer: &writer, argument: argument, argumentAccessor: argumentAccessor)
                    }

                    if !argumentSerializationString.isEmpty {
                        argumentSerializationString.append(", ")
                    }

                    argumentSerializationString.append("(\"\(argument.name.camelCasedAndEscaped)\", ConstructorParameterDescription(\(argument.name.camelCasedAndEscaped)))")
                }

                writer.line("return (FunctionDescription(name: \"\(function.name)\", parameters: [\(argumentSerializationString)]), buffer, DeserializeFunctionResponse { (buffer: Buffer) -> \(typeReferenceRepresentation(apiPrefix, function.result))? in")
                writer.indent()
                writer.line("let reader = BufferReader(buffer)")
                writer.line("var result: \(typeReferenceRepresentation(apiPrefix, function.result))?")

                try generateFieldParsing(apiPrefix: apiPrefix, writer: &writer, typeMap: typeMap, argument: Resolver.Argument(name: "result", type: function.result, condition: nil), argumentAccessor: "result")

                writer.line("return result")
                writer.dedent()
                writer.line("})")

                writer.dedent()
                writer.line("}")

                writer.dedent()
                writer.line("}")
            }
        }

        return writer.output()
    }
    
    private static func generateFieldSerialization(writer: inout CodeWriter, argument: Resolver.Argument, argumentAccessor: String) {
        switch argument.type {
        case .int32:
            writer.line("serializeInt32(\(argumentAccessor), buffer: buffer, boxed: false)")
        case .int64:
            writer.line("serializeInt64(\(argumentAccessor), buffer: buffer, boxed: false)")
        case .int256:
            writer.line("serializeInt256(\(argumentAccessor), buffer: buffer, boxed: false)")
        case .double:
            writer.line("serializeDouble(\(argumentAccessor), buffer: buffer, boxed: false)")
        case .bytes:
            writer.line("serializeBytes(\(argumentAccessor), buffer: buffer, boxed: false)")
        case .string:
            writer.line("serializeString(\(argumentAccessor), buffer: buffer, boxed: false)")
        case .bool:
            preconditionFailure()
        case .boolTrue:
            preconditionFailure()
        case .bareVector(let elementType), .boxedVector(let elementType):
            if case .boxedVector = argument.type {
                writer.line("buffer.appendInt32(481674261)")
            }
            writer.line("buffer.appendInt32(Int32(\(argumentAccessor).count))")
            writer.line("for item in \(argumentAccessor) {")
            writer.indent()
            generateFieldSerialization(writer: &writer, argument: Resolver.Argument(name: "item", type: elementType, condition: nil), argumentAccessor: "item")
            writer.dedent()
            writer.line("}")
        case .bareConstructor:
            writer.line("\(argumentAccessor).serialize(buffer, false)")
        case .boxedType:
            writer.line("\(argumentAccessor).serialize(buffer, true)")
        }
    }
    
    private static func generateFieldParsing(apiPrefix: String, writer: inout CodeWriter, typeMap: [QualifiedName: Resolver.SumType], argument: Resolver.Argument, argumentAccessor: String) throws {
        switch argument.type {
        case .int32:
            writer.line("\(argumentAccessor) = reader.readInt32()")
        case .int64:
            writer.line("\(argumentAccessor) = reader.readInt64()")
        case .int256:
            writer.line("\(argumentAccessor) = parseInt256(reader)")
        case .double:
            writer.line("\(argumentAccessor) = reader.readDouble()")
        case .bytes:
            writer.line("\(argumentAccessor) = parseBytes(reader)")
        case .string:
            writer.line("\(argumentAccessor) = parseString(reader)")
        case .bool:
            preconditionFailure()
        case .boolTrue:
            preconditionFailure()
        case .bareVector(let elementType), .boxedVector(let elementType):
            var elementSignature: Int32 = 0

            switch elementType {
            case .int32:
                elementSignature = -1471112230
            case .int64:
                elementSignature = 570911930
            case .int256:
                elementSignature = 0x0929C32F
            case .double:
                elementSignature = 571523412
            case .bytes:
                elementSignature = -1255641564
            case .string:
                elementSignature = -1255641564
            case .bool:
                elementSignature = 0
            case .boolTrue:
                elementSignature = 0
            case .bareVector:
                elementSignature = 0
            case .boxedVector:
                elementSignature = 0
            case let .bareConstructor(typeName, name):
                guard let type = typeMap[typeName] else {
                    throw CodeGenerationError(text: "Type \(typeName) not found")
                }
                guard let constructor = type.constructors[name] else {
                    throw CodeGenerationError(text: "Type \(typeName) not found")
                }
                elementSignature = Int32(bitPattern: constructor.id)
            case .boxedType:
                elementSignature = 0
            }

            if case .boxedVector = argument.type {
                writer.line("if let _ = reader.readInt32() {")
                writer.indent()
                writer.line("\(argumentAccessor) = \(apiPrefix).parseVector(reader, elementSignature: \(elementSignature), elementType: \(typeReferenceRepresentation(apiPrefix, elementType)).self)")
                writer.dedent()
                writer.line("}")
            } else {
                writer.line("\(argumentAccessor) = \(apiPrefix).parseVector(reader, elementSignature: \(elementSignature), elementType: \(typeReferenceRepresentation(apiPrefix, elementType)).self)")
            }
        case let .bareConstructor(typeName, name):
            guard let type = typeMap[typeName] else {
                throw CodeGenerationError(text: "Type \(typeName) not found")
            }
            guard let constructor = type.constructors[name] else {
                throw CodeGenerationError(text: "Type \(typeName) not found")
            }
            writer.line("\(argumentAccessor) = \(apiPrefix).parse(reader, signature: \(Int32(bitPattern: constructor.id)) as? \(typeReferenceRepresentation(apiPrefix, argument.type))")
        case .boxedType:
            writer.line("if let signature = reader.readInt32() {")
            writer.indent()
            writer.line("\(argumentAccessor) = \(apiPrefix).parse(reader, signature: signature) as? \(typeReferenceRepresentation(apiPrefix, argument.type))")
            writer.dedent()
            writer.line("}")
        }
    }
}
