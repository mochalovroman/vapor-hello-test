import Vapor

let drop = Droplet()

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

drop.run()
