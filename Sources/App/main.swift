import Vapor
import Auth
import Cookies
import VaporPostgreSQL

let drop = Droplet()

do {
    try drop.addProvider(VaporPostgreSQL.Provider.self)
} catch {
    assertionFailure("Error adding provider: \(error)")
}

let auth = AuthMiddleware(user: User.self) { value in
    return Cookie(
        name: "vapor-auth",
        value: value,
        secure: true
    )
}
drop.middleware.append(auth)
drop.preparations.append(User.self)

drop.get("hello") { _ in
    return "Hello Vapor"
}

drop.post("form") { request in
    return "Submitted with a POST request"
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

drop.get("friends") { req in
    let friends = try User.all().makeNode()
    let friendsDictionary = ["friends": friends]
    return try JSON(node: friendsDictionary)
}

drop.group("users") { users in
    users.post("register") { req in
        guard let name = req.data["name"]?.string else {
            throw Abort.badRequest
        }
        
        guard let email = req.data["email"]?.string else {
            throw Abort.badRequest
        }
        
        guard let password = req.data["password"]?.string else {
            throw Abort.badRequest
        }
        
        var user = try User(node: req.json)
        try user.save()
        return user
//        return try friend.makeJSON()
    }
    
    users.post("login") { req in
        guard let credentials = req.auth.header?.basic else {
            throw Abort.badRequest
        }
        
        try req.auth.login(credentials)
        
        return try JSON(node: ["message": "Logged in via default, check vapor-auth cookie."])
    }
    
    let protect = ProtectMiddleware(error:
        Abort.custom(status: .forbidden, message: "Not authorized.")
    )
    
    users.group(protect) { secure in
        secure.get("secure") { req in
            guard let authHeader = req.auth.header?.header else {
                throw Abort.badRequest
            }
            return try req.user()
        }
        secure.get("list") { req in
            guard let authHeader = req.auth.header?.header else {
                throw Abort.badRequest
            }
            let users = try User.all().makeNode()
            let usersDictionary = ["users": users]
            return try JSON(node: usersDictionary)
        }
    }
}

drop.run()
