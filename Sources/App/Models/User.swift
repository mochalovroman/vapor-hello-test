import Foundation
import Vapor

struct User: Model {
    var id: Node?
    let name: String
    let email: String
    var exists: Bool = false

    init(name: String, email: String) {
        self.name = name
        self.email = email
    }
    
    // NodeInitializable
    init(node: Node, in context: Context) throws {
        id = try node.extract("id")
        name = try node.extract("name")
        email = try node.extract("email")
    }
    
    // NodeRepresentable
    func makeNode(context: Context) throws -> Node {
        return try Node(node: ["id": id,
                               "name": name,
                               "email": email])
    }
    
    // Preparation
    static func prepare(_ database: Database) throws {
        try database.create("users") { friends in
            friends.id()
            friends.string("name")
            friends.string("email")
        }
    }
    
    static func revert(_ database: Database) throws {
        try database.delete("users")
    }
}

import Auth

extension User: Auth.User {
    static func authenticate(credentials: Credentials) throws -> Auth.User {
        let user: User?
        
        switch credentials {
        case let id as Identifier:
            user = try User.find(id.id)
        case let accessToken as AccessToken:
            user = try User.query().filter("access_token", accessToken.string).first()
        case let apiKey as APIKey:
            user = try User.query().filter("email", apiKey.id).filter("password", apiKey.secret).first()
        default:
            throw Abort.custom(status: .badRequest, message: "Invalid credentials.")
        }
        
        guard let u = user else {
            throw Abort.custom(status: .badRequest, message: "User not found")
        }
        
        return u
    }
    
    
    static func register(credentials: Credentials) throws -> Auth.User {
        throw Abort.custom(status: .badRequest, message: "Register not supported.")
    }
}

import HTTP

extension Request {
    func user() throws -> User {
        guard let user = try auth.user() as? User else {
            throw Abort.custom(status: .badRequest, message: "Invalid user type.")
        }
        
        return user
    }
}
