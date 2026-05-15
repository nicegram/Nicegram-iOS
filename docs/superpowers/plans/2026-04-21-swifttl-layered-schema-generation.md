# SwiftTL — Layered Schema Generation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Extend `build-system/SwiftTL` to parse `.tl` schemas containing `===N===` layer markers and emit one cumulative-snapshot `{apiPrefix}Layer{N}.swift` file per layer, while leaving the flat schema pipeline byte-identical.

**Architecture:** Approach 1 from the design spec (`docs/superpowers/specs/2026-04-21-swifttl-layered-schema-generation-design.md`). `DescriptionParser` returns a new `ParsedSchema` enum (`.flat` or `.layered`). `Resolver` gains `resolveLayeredTypes(layers:)` that snapshots a running constructor map per layer. `CodeGenerator` gains `generateLayered(apiPrefix:, layerNumber:, types:)` that emits a single-file-per-layer shape matching the existing hand-written `SecretApiLayer{N}.swift`. `main.swift` branches on `ParsedSchema`.

**Tech Stack:** Swift 5.5 executable target (`build-system/SwiftTL/Package.swift`). Vendored `Parser` combinator library for parsing. Project itself uses Bazel (`Make.py build`) for the full iOS build — `swift build` and `swift run` work at the package level for SwiftTL itself.

**Testing note:** per `CLAUDE.md`, no unit tests exist in this project. Verification is end-to-end: `swift run SwiftTL` on real schema files, diff against existing hand-written output, full Bazel build of the iOS app. No TDD steps in this plan — each task's verification is either (a) `swift build` (compiles), (b) `swift run SwiftTL` producing expected files, or (c) full Bazel build succeeds.

**Baseline:** this plan is written against a pre-existing prep commit landed just before Task 1 begins, which threads `apiPrefix: String` through `CodeGenerator.generate` / `generateMainFile` / `generateImplFile` / `typeReferenceRepresentation`, removes dead `--stub-functions` and `--print-constructors` CLI flags from `main.swift`, and deletes the unused `LegacyOrderParser.swift`. All task-level edits below assume these changes are already committed — code snippets and line numbers reference the post-prep-commit state of the files.

---

## File Structure

All edits within `build-system/SwiftTL/Sources/SwiftTL/`:

- `DescriptionParsing.swift` — add `ParsedSchema` enum, rework `parse(data:)` to detect `===N===` markers and route lines per layer.
- `Resolution.swift` — add `resolveLayeredTypes(layers:)` that walks sections and snapshots a running map.
- `CodeGeneration.swift` — add `generateLayered(apiPrefix:, layerNumber:, types:)` that emits one `{apiPrefix}Layer{N}.swift` string.
- `main.swift` — branch on `ParsedSchema`, loop for layered, unchanged for flat.

Downstream changes in the repo:

- `submodules/TelegramApi/Sources/SecretApiLayer{8,17,20,23,45,46,66,73,101,143,144}.swift` — replace existing 5 (of 11) with generator output; 6 new files added. BUILD uses `glob("Sources/**/*.swift")` so no BUILD update needed (confirmed — `submodules/TelegramApi/BUILD` line 9).

Reference artifacts to consult during implementation:

- Input schema: `/Users/isaac/build/telegram/telegram-ios-shared/tools/secret_scheme.tl` (112 lines).
- Legacy per-layer output to match: `submodules/TelegramApi/Sources/SecretApiLayer{8,46,73,101,144}.swift`.
- Flat reference: `submodules/TelegramApi/Sources/Api0.swift` and sharded `Api{1..5}.swift` — shows the `useStructPattern = true` shape to contrast against.
- Invocation script (not to be edited in this plan — spec calls it out as a follow-up in the sibling repo): `/Users/isaac/build/telegram/telegram-ios-shared/tools/generate_and_copy_scheme.sh`.

---

### Task 1: `ParsedSchema` type + layered parsing in `DescriptionParser`

**Files:**
- Modify: `build-system/SwiftTL/Sources/SwiftTL/DescriptionParsing.swift`

**Goal:** Replace `DescriptionParser.parse(data:) -> (constructors, functions)` with `parse(data:) -> ParsedSchema`, where `ParsedSchema` is a new enum with `.flat` and `.layered` cases. Layered mode triggers on any line matching `^===\d+===\s*$`. Flat mode is byte-identical to today.

- [ ] **Step 1: Add the `ParsedSchema` enum at the top of `DescriptionParser`**

Insert immediately after the `enum DescriptionParser {` opening brace, before `enum TypeReferenceDescription`:

```swift
enum ParsedSchema {
    case flat(constructors: [ConstructorDescription], functions: [ConstructorDescription])
    case layered(layers: [(layerNumber: Int, constructors: [ConstructorDescription])])
}

struct SchemaParsingError: Error, CustomStringConvertible {
    var text: String
    var description: String { text }
}
```

- [ ] **Step 2: Rewrite `parse(data:)` signature and dispatch logic**

Replace the current `static func parse(data: String) throws -> (constructors: [ConstructorDescription], functions: [ConstructorDescription])` (currently at lines 27–99) with:

```swift
static func parse(data: String) throws -> ParsedSchema {
    let lines = data.components(separatedBy: "\n")

    // Detect layered mode: any line of the form ===N===
    let layerMarker = try NSRegularExpression(pattern: "^===\\d+===\\s*$")
    let hasLayerMarker = lines.contains { line in
        let range = NSRange(line.startIndex..., in: line)
        return layerMarker.firstMatch(in: line, range: range) != nil
    }

    if hasLayerMarker {
        return try parseLayered(lines: lines)
    } else {
        return try parseFlat(lines: lines)
    }
}
```

- [ ] **Step 3: Extract the existing flat-parsing body into `parseFlat(lines:)`**

Add directly below `parse(data:)`. This is the existing logic verbatim, just accepting pre-split lines and returning the new enum case:

```swift
private static func parseFlat(lines: [String]) throws -> ParsedSchema {
    var typeLines: [String] = []
    var functionLines: [String] = []

    let skipPrefixes: [String] = [
        "true#3fedd339 = True;",
        "vector#1cb5c415 {t:Type} # [ t ] = Vector t;",
        "error#c4b9f9bb code:int text:string = Error;",
        "null#56730bcc = Null;"
    ]
    let skipContains: [String] = ["{X:Type}"]

    var isParsingFunctions = false
    loop: for line in lines {
        if line.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).isEmpty {
            continue
        } else if line == "---functions---" {
            isParsingFunctions = true
        } else {
            for string in skipPrefixes {
                if line.hasPrefix(string) { continue loop }
            }
            for string in skipContains {
                if line.contains(string) { continue loop }
            }
            if isParsingFunctions {
                functionLines.append(line)
            } else {
                typeLines.append(line)
            }
        }
    }

    var constructors: [ConstructorDescription] = []
    var functions: [ConstructorDescription] = []

    for line in typeLines {
        do {
            constructors.append(try parseConstructor(string: line))
        } catch let e {
            print("Error while parsing line:\n\(line)\n")
            print("\(e)")
            throw e
        }
    }
    for line in functionLines {
        do {
            functions.append(try parseConstructor(string: line))
        } catch let e {
            print("Error while parsing line:\n\(line)\n")
            print("\(e)")
            throw e
        }
    }

    return .flat(constructors: constructors, functions: functions)
}
```

- [ ] **Step 4: Add `parseLayered(lines:)`**

Add directly below `parseFlat`:

```swift
private static func parseLayered(lines: [String]) throws -> ParsedSchema {
    let skipPrefixes: [String] = [
        "true#3fedd339 = True;",
        "vector#1cb5c415 {t:Type} # [ t ] = Vector t;",
        "error#c4b9f9bb code:int text:string = Error;",
        "null#56730bcc = Null;"
    ]
    let skipContains: [String] = ["{X:Type}"]
    let layerMarker = try NSRegularExpression(pattern: "^===(\\d+)===\\s*$")

    // Pre-marker constructor lines accumulate here and are attached to the first declared layer.
    var preMarkerLines: [String] = []
    var sections: [(layerNumber: Int, lines: [String])] = []
    var lastLayerNumber: Int? = nil

    loop: for line in lines {
        let trimmed = line.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        if trimmed.isEmpty { continue }

        if line == "---functions---" {
            throw SchemaParsingError(text: "Layered schemas may not declare ---functions---; secret/layered schemas are types-only.")
        }

        let range = NSRange(line.startIndex..., in: line)
        if let match = layerMarker.firstMatch(in: line, range: range),
           let numberRange = Range(match.range(at: 1), in: line),
           let layerNumber = Int(line[numberRange])
        {
            if let previous = lastLayerNumber, layerNumber <= previous {
                throw SchemaParsingError(text: "Layer markers must appear in strictly ascending order; found ===\(layerNumber)=== after ===\(previous)===.")
            }
            sections.append((layerNumber, []))
            lastLayerNumber = layerNumber
            continue
        }

        // Apply the same skip rules as flat mode.
        for string in skipPrefixes {
            if line.hasPrefix(string) { continue loop }
        }
        for string in skipContains {
            if line.contains(string) { continue loop }
        }

        if sections.isEmpty {
            preMarkerLines.append(line)
        } else {
            sections[sections.count - 1].lines.append(line)
        }
    }

    if sections.isEmpty {
        throw SchemaParsingError(text: "Layered schema has a layer marker regex match but no ===N=== sections were extracted; this indicates a parser bug.")
    }

    // Attach pre-marker lines to the first (lowest) declared layer.
    if !preMarkerLines.isEmpty {
        sections[0].lines.insert(contentsOf: preMarkerLines, at: 0)
    }

    var layers: [(layerNumber: Int, constructors: [ConstructorDescription])] = []
    for (layerNumber, sectionLines) in sections {
        var constructors: [ConstructorDescription] = []
        for line in sectionLines {
            do {
                constructors.append(try parseConstructor(string: line))
            } catch let e {
                print("Error while parsing line (layer \(layerNumber)):\n\(line)\n")
                print("\(e)")
                throw e
            }
        }
        layers.append((layerNumber, constructors))
    }

    return .layered(layers: layers)
}
```

- [ ] **Step 5: Verify SwiftTL compiles**

Run: `cd build-system/SwiftTL && swift build 2>&1`
Expected: build succeeds OR fails only at call sites in `main.swift` (the next task fixes main.swift). Errors inside `DescriptionParsing.swift` mean the rewrite has a syntax/type issue — fix before proceeding.

Note: at this point `main.swift` still calls `parse(data:)` expecting the old tuple return type, so `swift build` from the package root will fail at the main-file callsite with a type-mismatch error. That's expected; Task 4 fixes it.

- [ ] **Step 6: Commit**

```bash
cd /Users/isaac/build/telegram/telegram-ios
git add build-system/SwiftTL/Sources/SwiftTL/DescriptionParsing.swift
git commit -m "$(cat <<'EOF'
SwiftTL: add ParsedSchema + layered schema parsing

DescriptionParser.parse(data:) now returns ParsedSchema (.flat or
.layered) based on the presence of ===N=== markers. Layered schemas
split constructor lines per layer; pre-marker constructors attach to
the lowest-numbered layer; ---functions--- is rejected in layered
mode; non-ascending markers throw.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task 2: `Resolver.resolveLayeredTypes` for per-layer cumulative snapshots

**Files:**
- Modify: `build-system/SwiftTL/Sources/SwiftTL/Resolution.swift`

**Goal:** Add `Resolver.resolveLayeredTypes(layers:)` that walks per-layer constructor descriptions in order, threads a running name→constructor map with last-wins semantics, and snapshots `[SumType]` at the end of each layer. Shares argument-resolution logic with the existing `resolveTypes(constructors:)` (by factoring a shared helper closure/method).

- [ ] **Step 1: Add `resolveLayeredTypes` to the `Resolver` enum**

Insert this method immediately after `resolveTypes(constructors:)` (which ends at Resolution.swift:201, `return types.values.sorted(by: { $0.name < $1.name })`). The method threads mutable state (a running map of constructor name → resolved SumType.Constructor and target type) and snapshots at each layer boundary:

```swift
static func resolveLayeredTypes(
    layers: [(layerNumber: Int, constructors: [DescriptionParser.ConstructorDescription])]
) throws -> [(layerNumber: Int, types: [SumType])] {
    // Running state: for each constructor name, the target type name and the raw description.
    // We keep raw descriptions (not resolved forms) because a later-layer constructor may
    // introduce new target-type names, and resolveTypeReference needs the final target-type set.
    var liveConstructors: [QualifiedName: (typeName: QualifiedName, description: DescriptionParser.ConstructorDescription)] = [:]
    var result: [(layerNumber: Int, types: [SumType])] = []

    for (layerNumber, layerConstructors) in layers {
        // Apply this layer's constructors to the running map with last-wins semantics.
        for constructorDescription in layerConstructors {
            switch constructorDescription.type {
            case let .type(name):
                if !name.value[name.value.startIndex].isUppercase {
                    throw ResolutionError(text: "Type constructor \(constructorDescription.name) -> \(name): the resulting type name should begin with a capital letter")
                }
                liveConstructors[constructorDescription.name] = (name, constructorDescription)
            case let .generic(name, argumentType):
                throw ResolutionError(text: "Type constructor \(constructorDescription.name) can not be used to construct a generic type \(name)<\(argumentType)>")
            }
        }

        // Snapshot: group by target type, resolve.
        var constructedTypes: [QualifiedName: [DescriptionParser.ConstructorDescription]] = [:]
        var constructorNameToType: [QualifiedName: QualifiedName] = [:]
        for (ctorName, entry) in liveConstructors {
            constructedTypes[entry.typeName, default: []].append(entry.description)
            constructorNameToType[ctorName] = entry.typeName
        }

        func resolveTypeReference(description: DescriptionParser.TypeReferenceDescription) throws -> TypeReference {
            switch description {
            case let .type(name):
                if let resolvedBuiltinType = resolveBuiltinType(name: name) {
                    return resolvedBuiltinType
                }
                if name.value[name.value.startIndex].isUppercase {
                    if let _ = constructedTypes[name] {
                        return .boxedType(name)
                    } else {
                        throw ResolutionError(text: "Unresolved type \(name) in layer \(layerNumber)")
                    }
                } else {
                    if let typeName = constructorNameToType[name] {
                        return .bareConstructor(typeName: typeName, name: name)
                    } else {
                        throw ResolutionError(text: "Unresolved type constructor \(name) in layer \(layerNumber)")
                    }
                }
            case let .generic(name, argumentType):
                if name == "vector" {
                    return .bareVector(try resolveTypeReference(description: .type(name: argumentType)))
                } else if name == "Vector" {
                    return .boxedVector(try resolveTypeReference(description: .type(name: argumentType)))
                } else {
                    throw ResolutionError(text: "Unresolved generic type \(name) in layer \(layerNumber)")
                }
            }
        }

        func resolveArgument(existingArguments: [Argument], description: DescriptionParser.ArgumentDescription) throws -> Argument {
            return Argument(
                name: description.name,
                type: try resolveTypeReference(description: description.type),
                condition: try description.condition.flatMap { condition -> Argument.Condition in
                    if !existingArguments.contains(where: { $0.name == condition.fieldName }) {
                        throw ResolutionError(text: "Unresolved conditional field reference to \(condition.fieldName) in layer \(layerNumber)")
                    }
                    return Argument.Condition(fieldName: condition.fieldName, bitIndex: condition.bitIndex)
                }
            )
        }

        var types: [QualifiedName: SumType] = [:]
        for (typeName, constructorDescriptions) in constructedTypes {
            let type = SumType(name: typeName)
            for constructorDescription in constructorDescriptions {
                var arguments: [Argument] = []
                for argumentDescription in constructorDescription.arguments {
                    arguments.append(try resolveArgument(existingArguments: arguments, description: argumentDescription))
                }
                guard let id = constructorDescription.explicitId else {
                    throw ResolutionError(text: "Constructor \(constructorDescription.name) does not have an id")
                }
                type.constructors[constructorDescription.name] = SumType.Constructor(
                    name: constructorDescription.name,
                    id: id,
                    arguments: arguments
                )
            }
            types[type.name] = type
        }

        let sortedTypes = types.values.sorted(by: { $0.name < $1.name })
        result.append((layerNumber, sortedTypes))
    }

    return result
}
```

- [ ] **Step 2: Verify SwiftTL package compiles (DescriptionParsing + Resolution)**

Run: `cd build-system/SwiftTL && swift build 2>&1 | head -50`
Expected: the only remaining errors are in `main.swift` (unchanged in this task). If `Resolution.swift` itself has errors, fix before proceeding.

- [ ] **Step 3: Commit**

```bash
cd /Users/isaac/build/telegram/telegram-ios
git add build-system/SwiftTL/Sources/SwiftTL/Resolution.swift
git commit -m "$(cat <<'EOF'
SwiftTL: add Resolver.resolveLayeredTypes

Walks layer sections in order, threads a running constructor-name map
with last-wins semantics, and snapshots [SumType] at each layer
boundary. Constructors appearing only in later layers do not leak into
earlier layers' snapshots.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task 3: `CodeGenerator.generateLayered` — one file per layer

**Files:**
- Modify: `build-system/SwiftTL/Sources/SwiftTL/CodeGeneration.swift`

**Goal:** Emit one `{apiPrefix}Layer{N}.swift` file per layer, matching the shape of the existing hand-written `SecretApiLayer8.swift` (nested `public struct`, inline enum case args, `fileprivate parse_*`). Reuses `typeReferenceRepresentation`, `generateFieldSerialization`, `generateFieldParsing`, and `SumType.hasDirectReference(to:typeMap:)` unchanged.

Reference for the expected output shape: read `submodules/TelegramApi/Sources/SecretApiLayer8.swift` (the first 80 lines show the header + struct body; lines ~85+ show the nested enums). The generator output will not byte-match but must match this *shape*.

- [ ] **Step 1: Add `generateLayered` entry point to `CodeGenerator`**

Insert the following method after the existing `generate(...)` method (which ends at CodeGeneration.swift:200). Reads directly; uses the same `CodeWriter` helper and private type helpers already in the file:

```swift
static func generateLayered(
    apiPrefix: String,
    layerNumber: Int,
    types: [Resolver.SumType]
) throws -> (filename: String, source: String) {
    let structName = "\(apiPrefix)\(layerNumber)"
    let filename = "\(apiPrefix)Layer\(layerNumber).swift"

    var typeMap: [QualifiedName: Resolver.SumType] = [:]
    for type in types {
        typeMap[type.name] = type
    }

    // Detect whether any constructor argument uses Int256; if so, we need the int256 parser entry.
    var usesInt256 = false
    for type in types {
        for (_, constructor) in type.constructors {
            for argument in constructor.arguments {
                if containsInt256(argument.type) { usesInt256 = true; break }
            }
            if usesInt256 { break }
        }
        if usesInt256 { break }
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
        try emitLayeredType(writer: &writer, apiPrefix: apiPrefix, structName: structName, type: type, typeMap: typeMap)
    }

    writer.dedent()
    writer.line("}") // close public struct

    return (filename, writer.output())
}
```

- [ ] **Step 2: Add `containsInt256` helper**

Insert directly below `generateLayered` (or above it, before `private static func generateFieldParsing`):

```swift
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
```

- [ ] **Step 3: Add `emitLayeredType` helper**

Insert directly below `containsInt256`. This emits a single nested `public enum <TypeName> { ... }` with inline-args cases, a `serialize(_:_:)` method, and `fileprivate parse_*` methods. It mirrors the existing `generate`/`generateImplFile` logic for the type body but:
- renders with `useStructPattern = false` (no `Cons_*` wrapper) directly,
- drops `TypeConstructorDescription` conformance,
- drops the `descriptionFields()` method,
- uses `fileprivate` (not `public`) for `parse_*`,
- nests inside the outer struct writer's indent rather than using a `public extension`:

```swift
private static func emitLayeredType(
    writer: inout CodeWriter,
    apiPrefix: String,
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
            // NOTE: layered generator uses structName (e.g. "SecretApi8") as the "apiPrefix"
            // for nested-type references, because nested types live inside the struct.
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
                    writer.line("if Int(_\(fieldIndex + 1)!) & Int(1 << \(condition.bitIndex)) != 0 {")
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
                    writer.line("let _c\(checkIndex + 1) = (Int(_\(fieldIndex + 1)!) & Int(1 << \(condition.bitIndex)) == 0) || _\(checkIndex + 1) != nil")
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
```

**IMPORTANT:** `typeReferenceRepresentation`, `generateFieldSerialization`, and `generateFieldParsing` take an `apiPrefix` parameter that they inject as a prefix on type names (e.g. `"Api.ChatFull"`). For layered output, the prefix becomes the per-layer struct name (`"SecretApi8"`), so inline-args like `media: SecretApi8.DecryptedMessageMedia` render correctly. We pass `structName` (not `apiPrefix`) to these helpers inside the layered emitter.

Also: `camelCasedAndEscaped` is a private String extension at the top of `CodeGeneration.swift`. The layered emitter uses it as-is — no duplication.

- [ ] **Step 4: Verify CodeGeneration.swift compiles**

Run: `cd build-system/SwiftTL && swift build 2>&1 | head -50`
Expected: only `main.swift` errors (unchanged in this task). Any error inside `CodeGeneration.swift` itself means the emitter has a syntax/type issue — fix before proceeding.

- [ ] **Step 5: Commit**

```bash
cd /Users/isaac/build/telegram/telegram-ios
git add build-system/SwiftTL/Sources/SwiftTL/CodeGeneration.swift
git commit -m "$(cat <<'EOF'
SwiftTL: add CodeGenerator.generateLayered for per-layer output

Emits one {apiPrefix}Layer{N}.swift file per layer: file-scope
dispatch table, public struct {apiPrefix}{N} with parse/parseVector/
serializeObject, nested public enums for each sum type using the
inline-args shape. Int256 dispatch entry emitted only when a layer's
constructors reference it. Reuses typeReferenceRepresentation /
generateFieldSerialization / generateFieldParsing unchanged, passing
the struct name as the apiPrefix so nested type refs render correctly.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task 4: Wire `main.swift` to branch on `ParsedSchema`

**Files:**
- Modify: `build-system/SwiftTL/Sources/SwiftTL/main.swift:47-98`

**Goal:** Update the top-level `do { ... }` block to pattern-match on `ParsedSchema`. Flat path uses today's body unchanged; layered path iterates `resolveLayeredTypes` output and calls `generateLayered` once per layer.

- [ ] **Step 1: Replace the `do { ... } catch let e { ... }` block**

Replace the existing block from line 47 (`do {`) to line 98 (the closing `}` of the catch) with:

```swift
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
```

Note the flat branch body is the same 40-odd lines that were in the original `do`, lightly reindented. The `createDirectory` call is hoisted above the switch since both branches need it.

- [ ] **Step 2: Verify SwiftTL builds**

Run: `cd build-system/SwiftTL && swift build 2>&1`
Expected: `Build complete!` with no errors.

- [ ] **Step 3: Dry-run layered generation on secret_scheme.tl**

```bash
cd /Users/isaac/build/telegram/telegram-ios/build-system/SwiftTL
rm -rf /tmp/swifttl-layered-out
swift run SwiftTL /Users/isaac/build/telegram/telegram-ios-shared/tools/secret_scheme.tl /tmp/swifttl-layered-out --api-prefix=SecretApi
ls /tmp/swifttl-layered-out/
```

Expected output: 11 files named `SecretApiLayer{8,17,20,23,45,46,66,73,101,143,144}.swift`. If any are missing or extra, inspect the parser's layer-marker handling. If the tool errors, the error message should point at the offending layer or constructor.

- [ ] **Step 4: Dry-run flat generation on swift_scheme.tl (regression check)**

```bash
cd /Users/isaac/build/telegram/telegram-ios/build-system/SwiftTL
rm -rf /tmp/swifttl-flat-out
swift run SwiftTL /Users/isaac/build/telegram/telegram-ios-shared/tools/swift_scheme.tl /tmp/swifttl-flat-out
ls /tmp/swifttl-flat-out/
diff -q /tmp/swifttl-flat-out /Users/isaac/build/telegram/telegram-ios/submodules/TelegramApi/Sources/ 2>&1 | grep -E "^(Only in|Files)" | head
```

Expected: 6 files (`Api0.swift` through `Api5.swift`). The diff against `submodules/TelegramApi/Sources/` should show only "Only in submodules" entries for non-`Api*.swift` files (e.g. `SecretApiLayer*.swift`, `Api+*.swift` helpers). `Api0.swift`-`Api5.swift` must either be identical or show only trivially-different content — any structural diff would indicate a regression in the flat pipeline that must be fixed before proceeding.

- [ ] **Step 5: Commit**

```bash
cd /Users/isaac/build/telegram/telegram-ios
git add build-system/SwiftTL/Sources/SwiftTL/main.swift
git commit -m "$(cat <<'EOF'
SwiftTL: main.swift branches on ParsedSchema

Flat schemas keep the existing generate(...) pipeline. Layered
schemas iterate resolveLayeredTypes and write one
{apiPrefix}Layer{N}.swift per layer via generateLayered.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task 5: Regenerate `SecretApiLayer*.swift` and verify full project build

**Files:**
- Overwrite: `submodules/TelegramApi/Sources/SecretApiLayer{8,46,73,101,144}.swift` (existing, hand-written)
- Create: `submodules/TelegramApi/Sources/SecretApiLayer{17,20,23,45,66,143}.swift` (new)

**Goal:** Regenerate all 11 layer files using the new SwiftTL and confirm the entire iOS project still compiles. Downstream consumers (`ManagedSecretChatOutgoingOperations.swift`, `ProcessSecretChatIncomingDecryptedOperations.swift`) already reference `SecretApi{8,46,73,101,144}.<Type>.<ctor>` symbols; they must continue to resolve.

- [ ] **Step 1: Pre-flight — snapshot current state of `submodules/TelegramApi/Sources/SecretApiLayer*.swift`**

```bash
cd /Users/isaac/build/telegram/telegram-ios
ls submodules/TelegramApi/Sources/SecretApiLayer*.swift
git log --oneline -5 -- submodules/TelegramApi/Sources/SecretApiLayer*.swift
```

Expected: 5 files (`SecretApiLayer{8,46,73,101,144}.swift`), each tracked by git. If there are uncommitted modifications to any of these files, stop and investigate — they should be clean before regeneration.

- [ ] **Step 2: Regenerate into a staging directory**

```bash
cd /Users/isaac/build/telegram/telegram-ios/build-system/SwiftTL
rm -rf /tmp/secretapi-staging
swift run SwiftTL /Users/isaac/build/telegram/telegram-ios-shared/tools/secret_scheme.tl /tmp/secretapi-staging --api-prefix=SecretApi
ls /tmp/secretapi-staging/
```

Expected: 11 files, one per layer.

- [ ] **Step 3: Spot-check layer 8 output against the hand-written file**

```bash
diff /tmp/secretapi-staging/SecretApiLayer8.swift /Users/isaac/build/telegram/telegram-ios/submodules/TelegramApi/Sources/SecretApiLayer8.swift | head -80
```

Expected: cosmetic differences (whitespace, maybe case ordering) but each enum case name must appear in both; each `buffer.appendInt32(<id>)` must have the same ID in both files for the same constructor; the `parsers` dict must contain the same set of `dict[<id>]` entries. If the generator added a `Bool` type (from the pre-marker `boolFalse`/`boolTrue`), that's an expected addition per the spec — not a failure.

If any *constructor ID* or *enum case name* differs for an existing constructor, STOP. That means either the schema's legacy hand-written content drifted from the `.tl` source (spec risk section covers this — schema wins) or the generator has a bug. Decide on the fly: if the legacy hand-written file has a typo'd ID, the regenerated file is correct and should land as-is. If the generator has a bug, fix before proceeding.

- [ ] **Step 4: Copy staging output into place**

```bash
cd /Users/isaac/build/telegram/telegram-ios
rm -f submodules/TelegramApi/Sources/SecretApiLayer*.swift
cp /tmp/secretapi-staging/SecretApiLayer*.swift submodules/TelegramApi/Sources/
ls submodules/TelegramApi/Sources/SecretApiLayer*.swift
```

Expected: 11 files, one per layer (5 overwrites + 6 new).

- [ ] **Step 5: Full Bazel build**

```bash
cd /Users/isaac/build/telegram/telegram-ios
source ~/.zshrc 2>/dev/null
python3 build-system/Make/Make.py build --continueOnError 2>&1 | tee /tmp/swifttl-wave-build.log | tail -40
```

Expected: build completes with no errors. The `Telegram.ipa` target builds successfully. If compile errors surface, they will most likely be in `ManagedSecretChatOutgoingOperations.swift` or `ProcessSecretChatIncomingDecryptedOperations.swift` — cases where a specific `SecretApi{N}.<Type>.<ctor>` symbol the consumer expects doesn't appear in the regenerated file. Triage:

- If the missing symbol is a constructor present in `secret_scheme.tl` under some layer: verify the resolver captured it correctly in the snapshot for that layer. Likely a bug in `resolveLayeredTypes` (e.g. pre-marker handling) or in the emitter (e.g. case-name mis-generation). Fix in SwiftTL and regenerate.
- If the missing symbol names a constructor NOT in `secret_scheme.tl` under that layer's cumulative set: the hand-written file and the consumer code drifted from the schema. Not a generator bug. Escalate with the user before modifying consumer code.

- [ ] **Step 6: Commit regenerated files**

```bash
cd /Users/isaac/build/telegram/telegram-ios
git add submodules/TelegramApi/Sources/SecretApiLayer*.swift
git status --short submodules/TelegramApi/Sources/
git commit -m "$(cat <<'EOF'
TelegramApi: regenerate SecretApiLayer*.swift via SwiftTL

Replaces the hand-written layer 8/46/73/101/144 files with SwiftTL
output and adds the previously-unpublished layers 17/20/23/45/66/143.
Per-layer struct names (SecretApi8, SecretApi46, ...) and public
enum case signatures are unchanged; downstream consumers
(ManagedSecretChatOutgoingOperations, ProcessSecretChatIncomingDecryptedOperations)
compile unchanged.

BUILD uses glob("Sources/**/*.swift") so no BUILD update required.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task 6: Final flat-path regression check

**Files:** none modified — this is a verification-only task.

**Goal:** Confirm the flat pipeline is structurally unchanged — `Api*.swift` files regenerated from `swift_scheme.tl` match what's currently committed in `submodules/TelegramApi/Sources/`.

- [ ] **Step 1: Regenerate `Api*.swift` into staging**

```bash
cd /Users/isaac/build/telegram/telegram-ios/build-system/SwiftTL
rm -rf /tmp/api-flat-staging
swift run SwiftTL /Users/isaac/build/telegram/telegram-ios-shared/tools/swift_scheme.tl /tmp/api-flat-staging
ls /tmp/api-flat-staging/
```

Expected: `Api0.swift` through `Api5.swift` (exact count depends on the schema's constructor count; 6 files is the current count).

- [ ] **Step 2: Diff against committed flat output**

```bash
for f in /tmp/api-flat-staging/Api*.swift; do
  base=$(basename "$f")
  diff -q "$f" "/Users/isaac/build/telegram/telegram-ios/submodules/TelegramApi/Sources/$base" || echo "DIFFERS: $base"
done
```

Expected: every file identical to the committed version, or at most whitespace differences. Any structural diff (different enum cases, different IDs, different method signatures) is a regression in the flat pipeline introduced by this wave's edits — must be fixed.

- [ ] **Step 3: (If no diff) confirm in conversation**

If step 2 reports all files identical, the wave is complete — note in the PR description / commit log that the flat pipeline is verified unchanged. No further commit.

- [ ] **Step 4: (If diff found) investigate and fix**

If diffs exist: most likely cause is that a shared helper in `CodeGeneration.swift` was touched with an effect that cascades into `generate(...)`. Revisit Task 3 and ensure all edits added new methods only, with no modifications to `generate`, `generateMainFile`, `generateImplFile`, or the top-level `CodeGenerator` API. Fix and re-run step 2.

---

## Out-of-scope follow-ups (do not execute in this plan)

Documented in the spec; not part of this plan's delivered scope.

- Update `/Users/isaac/build/telegram/telegram-ios-shared/tools/generate_and_copy_scheme.sh` to `rm -f` and `cp` the `SecretApiLayer*.swift` output alongside the existing `Api*.swift` copy step. Lives in a sibling repo; the user handles when ready.
- Delete `build-system/SwiftTL/Sources/SwiftTL/LegacyOrderParser.swift` was ALREADY deleted in the uncommitted working tree (per `git status` at plan writing time — `D Sources/SwiftTL/LegacyOrderParser.swift`). Not in this plan; the deletion can land with Task 1 if still convenient or as a separate cleanup.
