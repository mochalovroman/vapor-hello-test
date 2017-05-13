import Vapor
import VaporPostgreSQL

let drop = Droplet()
drop.preparations.append(Friend.self)

do {
    try drop.addProvider(VaporPostgreSQL.Provider.self)
} catch {
    assertionFailure("Error adding provider: \(error)")
}

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
    let friends = try Friend.all().makeNode()
    let friendsDictionary = ["friends": friends]
    return try JSON(node: friendsDictionary)
}

drop.get("friends", Int.self) { req, userID in
    guard let friend = try Friend.find(userID) else {
        throw Abort.notFound
    }
    return try friend.makeJSON()
}

drop.post("friend") { req in
    var friend = try Friend(node: req.json)
    try friend.save()
    return try friend.makeJSON()
}

drop.run()
