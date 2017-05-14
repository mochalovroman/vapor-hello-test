import Foundation
import Vapor
import Fluent
import Turnstile
import TurnstileCrypto

final class User {
    var id: Node?
    let email: String
    let password: String
    var exists: Bool = false
    
    init(email: String, password: String) {
        self.id = nil
        self.email = email
        self.password = password
    }
    
    init(node: Node, in context: Context) throws {
        id = try node.extract("id")
        email = try node.extract("email")
        password = try node.extract("password")
    }
}

extension User: Model {
    func makeNode(context: Context) throws -> Node {
        return try Node(node: ["id": id,
                               "email": email,
                               "password": password])
    }
}

extension User: Preparation {
    static func prepare(_ database: Database) throws {
        try database.create("users") { user in
            user.id()
            user.string("email")
            user.string("password")
        }
    }
    
    static func revert(_ database: Database) throws {
        try database.delete("users")
    }
}

import Auth

extension User: Auth.User {
    static func authenticate(credentials: Credentials) throws -> Auth.User {
        switch credentials {
        case let apiKey as APIKey:
            let fetchedUser = try User.query().filter("email", apiKey.id).first()
            guard let user = fetchedUser else {
                throw Abort.custom(status: .networkAuthenticationRequired, message: "User does not exist")
            }
            if try BCrypt.verify(password: apiKey.secret, matchesHash: fetchedUser!.password) {
                return user
            } else {
                throw Abort.custom(status: .networkAuthenticationRequired, message: "Invalid user name or password.")
            }
            
        default:
            let type = type(of: credentials)
            throw Abort.custom(status: .forbidden, message: "Unsupported credential type: \(type).")
        }
    }
    
    
    static func register(credentials: Credentials) throws -> Auth.User {
        let usernamePassword = credentials as? UsernamePassword
        
        guard let creds = usernamePassword else {
            let type = type(of: credentials)
            throw Abort.custom(status: .forbidden, message: "Unsupported credential type: \(type).")
        }
        
        let user = User(email: creds.username, password: BCrypt.hash(password: creds.password))
        return user
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
