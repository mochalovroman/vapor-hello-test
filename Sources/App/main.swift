import Vapor
import Auth
import Cookies
import VaporPostgreSQL

let drop = Droplet()

let auth = AuthMiddleware(user: User.self)
drop.middleware.append(auth)

do {
    try drop.addProvider(VaporPostgreSQL.Provider.self)
    drop.preparations.append(User.self)
} catch {
    assertionFailure("Error adding provider: \(error)")
}


let loginController = UsersController()
loginController.addRoutes(to: drop)

drop.get("hello") { _ in
    return "Hello, AppsConf"
}

drop.get("json") { request in
    return try JSON(node: [
        "text": "Hello, AppsConf",
        "year": 2017,
        "swift": true
        ])
}

drop.get("notfound") { request in
    throw Abort.notFound
}

drop.get("customerror") { request in
    throw Abort.custom(status: .badRequest, message: "Sorry 😱")
}

drop.run()
