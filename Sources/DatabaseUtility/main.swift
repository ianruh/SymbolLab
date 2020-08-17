//
//  File.swift
//  
//
//  Created by Ian Ruh on 7/3/20.
//

import Foundation
import PostgresKit

let configuration = PostgresConfiguration(
    hostname: "localhost",
    username: "symbollab",
    password: "8T9V=kG4zGe}AdxnMs@K>fqmC)72eTva",
    database: "symbollab"
)

let eventLoopGroup: EventLoopGroup = EventLoopGroup(numberOfThreads: 1)
defer { try! eventLoopGroup.syncShutdown() }

let pools = EventLoopGroupConnectionPool(
    source: PostgresConnectionSource(configuration: configuration),
    on: eventLoopGroup
)
defer { pools.shutdown() }

let postgres = pool.database()
let sql = postgres.sql() // SQLDatabase
//let planets = try sql.select().column("*").from("planets").all().wait()
