/// Copyright (c) 2018 Razeware LLC
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
///
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import FluentPostgreSQL
import Vapor
import Leaf

/// Called before your application initializes.
///
/// [Learn More →](https://docs.vapor.codes/3.0/getting-started/structure/#configureswift)
public func configure(
  _ config: inout Config,
  _ env: inout Environment,
  _ services: inout Services
) throws {
  // Register providers first
  try services.register(FluentPostgreSQLProvider())
  try services.register(LeafProvider())

  // Register routes to the router
  let router = EngineRouter.default()
  try routes(router)
  services.register(router, as: Router.self)

  // Register middleware
  var middlewares = MiddlewareConfig() // Create _empty_ middleware config
  middlewares.use(FileMiddleware.self) // Serves files from `Public/` directory
  // middlewares.use(DateMiddleware.self) // Adds `Date` header to responses
  middlewares.use(ErrorMiddleware.self) // Catches errors and converts to HTTP response
  services.register(middlewares)

  // Configure a database
  var databases = DatabasesConfig()
  let hostname = Environment.get("DATABASE_HOSTNAME") ?? "localhost"
  let username = Environment.get("DATABASE_USER") ?? "vapor"

  let databaseName: String
  let databasePort: Int
  if (env == .testing) {
    databaseName = "vapor-test"
    if let testPort = Environment.get("DATABASE_PORT") {
      databasePort = Int(testPort) ?? 5433
    } else {
      databasePort = 5433
    }
  }
  else {
    databaseName = Environment.get("DATABASE_DB") ?? "vapor"
    databasePort = 5432
  }
  let password = Environment.get("DATABASE_PASSWORD") ?? "password"
  let databaseConfig = PostgreSQLDatabaseConfig(
    hostname: hostname,
    port: databasePort,
    username: username,
    database: databaseName,
    password: password)
  let database = PostgreSQLDatabase(config: databaseConfig)
  databases.add(database: database, as: .psql)
  services.register(databases)

  // Configure migrations
  var migrations = MigrationConfig()
  migrations.add(model: User.self, database: .psql)
  migrations.add(model: Acronym.self, database: .psql)
  migrations.add(model: Category.self, database: .psql)
  migrations.add(model: AcronymCategoryPivot.self, database: .psql)
  services.register(migrations)

  // Configure the rest of your application here
  var commandConfig = CommandConfig.default()
  commandConfig.useFluentCommands()
  services.register(commandConfig)

  config.prefer(LeafRenderer.self, for: ViewRenderer.self)
    
    let websockets = NIOWebSocketServer.default()
   // var clients = [WebSocket]()
    var browserClient: WebSocket?
    var phoneClient: WebSocket?
    websockets.get("devicews") { ws, req in
        print("ws connnected")
        
        var pingTimer: DispatchSourceTimer? = nil
        pingTimer = DispatchSource.makeTimerSource()
        pingTimer?.schedule(deadline: .now(), repeating: .seconds(25))
        pingTimer?.setEventHandler { ws.send(Data()) }
        pingTimer?.resume()
        
        if browserClient == nil {
            browserClient = ws
        } else {
            phoneClient = ws
            phoneClient?.send("sendImage")
        }
     //   clients.append(ws)
        
        ws.onText { ws, text in
            print("ws received: \(text)")
            ws.send("echo - \(text)")
        }
        ws.onBinary({ (ws, data) in
//            print("ws received: binary")
//            let webClient = clients.filter({ (socket) -> Bool in
//                socket !== ws
//            }).first
//            if let wc = webClient {
           //     print("sending image to client")
                browserClient?.send(data)
                phoneClient?.send("sendImage")
          //  }
        })
    }
    services.register(websockets, as: WebSocketServer.self)
    
    
}
