import Vapor
import Auth
import Cookies
import VaporPostgreSQL

let drop = Droplet()

let auth = AuthMiddleware(user: User.self)
drop.middleware.append(auth)

do {
    try drop.addProvider(VaporPostgreSQL.Provider.self)
} catch {
    assertionFailure("Error adding provider: \(error)")
}

drop.preparations.append(User.self)

let loginController = UsersController()
loginController.addRoutes(to: drop)

drop.get("hello") { _ in
    return "Hello Vapor"
}

drop.get("json") { request in
    return try JSON(node: [
        "number": 123,
        "text": "unicorns",
        "bool": false
        ])
}

drop.get("404") { request in
    throw Abort.notFound
}

drop.get("error") { request in
    throw Abort.custom(status: .badRequest, message: "Sorry 😱")
}

drop.group("users") { users in
    users.get("list") { req in
        guard let authHeader = req.auth.header?.header else {
            throw Abort.badRequest
        }
        if req.auth.header?.header != "appsconf" {
            throw Abort.custom(status: .badRequest, message: "You use bad Authorization header")
        }
        
        print(authHeader)
        let users = try User.all().makeNode()
        let usersDictionary = ["users": users]
        return try JSON(node: usersDictionary)
    }
}

drop.run()
