/// Elements conforming to `CommandRepresentable` can be expressed in the form of `Path.Command`s.
public protocol CommandRepresentable {
    func commands() throws -> [Path.Command]
}

public protocol DirectionalCommandRepresentable: CommandRepresentable {
    func commands(clockwise: Bool) throws -> [Path.Command]
}

public extension DirectionalCommandRepresentable {
    /// Defaults to anti/counter-clockwise commands.
    func commands() throws -> [Path.Command] {
        try commands(clockwise: false)
    }
}
