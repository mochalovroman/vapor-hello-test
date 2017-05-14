import Vapor
import HTTP
import Auth
import Turnstile

final class UsersController {
    func addRoutes(to drop: Droplet) {
        drop.group("users") { users in
            users.post("login", handler: loginHandler)
            users.post("register", handler: registerHandler)
            users.get("list", handler: listHandler)
        }
    }
    
    func loginHandler(_ request: Request)throws -> ResponseRepresentable {
        guard let credentials = request.auth.header?.basic else {
            throw Abort.badRequest
        }
        do {
            try request.auth.login(credentials, persist: true)
            return try JSON(node: ["message": "welcome!"])
        } catch {
            return try JSON(node: ["message": "error login"])
        }
    }
    
    func registerHandler(_ request: Request)throws -> ResponseRepresentable {
        guard let username = request.data["email"]?.string,
            let password = request.data["password"]?.string else {
                throw Abort.badRequest
        }
        
        let creds = UsernamePassword(username: username, password: password)
        var user = try User.register(credentials: creds) as? User
        if user != nil {
            try user!.save()
            return try JSON(node: ["message": "welcome - \(user!.email)"])
        } else {
            return try JSON(node: ["message": "error registration"])
        }
    }
    
    func listHandler(_ request: Request)throws -> ResponseRepresentable {
        guard let authHeader = request.auth.header?.header else {
            throw Abort.badRequest
        }
        if authHeader != "appsconf" {
            throw Abort.custom(status: .badRequest, message: "You use bad Authorization header")
        }
        
        let users = try User.all().makeNode()
        let usersDictionary = ["users": users]
        return try JSON(node: usersDictionary)

    }
}
