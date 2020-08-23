//
// Created by Ian Ruh on 8/19/20.
//

import Foundation
import PythonKit

internal class SymbolLabPostgres {
    let psycopg2: PythonObject
    var connection: PythonObject
    var cursor: PythonObject

    internal var version: String {
        self.cursor.execute("SELECT version()")
        let db_version = cursor.fetchone()
        return db_version.description
    }

    internal init?(host: String = "localhost", dbname: String = "symbollab", user: String = "symbollab", password: String) {
        self.psycopg2 = try Python.import("psycopg2")
        self.connection = self.psycopg2.connect("host=\(host) dbname=\(dbname) user=\(user) password=\(password)")
        self.cursor = self.connection.cursor()
    }

    deinit {
        cursor.close()
        connection.close()
    }
}