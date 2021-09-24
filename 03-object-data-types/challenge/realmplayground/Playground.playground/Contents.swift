/// Copyright (c) 2019 Razeware LLC
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

import Foundation
import RealmSwift
import CoreLocation

// Setup
let realm = try! Realm(configuration:
  Realm.Configuration(inMemoryIdentifier: "TemporaryRealm"))

print("Ready to play...")

// Playground

class Car: Object {
  @objc dynamic var brand = ""
  @objc dynamic var year = 0

  convenience init(brand: String, year: Int) {
    self.init()
    self.brand = brand
    self.year = year
  }

  override var description: String {
    return "🚗 {\(brand), \(year)}"
  }
}

Example.of("Basic Model") {
  let car1 = Car(brand: "BMW", year: 1980)
  print(car1)
}

class Person: Object {
  // String
  @objc dynamic var firstName = ""
  @objc dynamic var lastName: String?

  // Date
  @objc dynamic var born = Date.distantPast
  @objc dynamic var deceased: Date?

  // Data
  @objc dynamic var photo: Data?

  // Bool
  @objc dynamic var isVIP: Bool = false

  // Int, Int8, Int16, Int32, Int64
  @objc dynamic var id = 0 //defaults to Int
  @objc dynamic var hairCount: Int64 = 0

  // Float, Double
  @objc dynamic var height: Float = 0.0
  @objc dynamic var weight: Double = 0.0

  enum Department: String {
    case technology
    case politics
    case business
    case health
    case science
    case sports
    case travel
  }

  @objc dynamic private var _department =
    Department.technology.rawValue

  var department: Department {
    get { return Department(rawValue: _department)! }
    set { _department = newValue.rawValue }
  }

  // Computed Properties
  var isDeceased: Bool {
    return deceased != nil
  }

  var fullName: String {
    guard let last = lastName else {
      return firstName
    }

    return "\(firstName) \(last)"
  }

  convenience init(firstName: String, born: Date, id: Int) {
    self.init()
    self.firstName = firstName
    self.born = born
    self.id = id
  }

  @objc dynamic var key = UUID().uuidString
  override static func primaryKey() -> String? {
    return "key"
  }

  override static func indexedProperties() -> [String] {
    return ["firstName", "lastName"]
  }

  let idPropertyName = "id"
  var temporaryId = 0
  @objc dynamic var temporaryUploadId = 0
  override static func ignoredProperties() -> [String] {
    return ["temporaryUploadId"]
  }
}

Example.of("Complex Model") {
  let person = Person(
    firstName: "Marin",
    born: Date(timeIntervalSince1970: 0),
    id: 1035)
  person.hairCount = 1284639265974
  person.isVIP = true

  print(type(of: person))
  print(type(of: person).primaryKey() ?? "no primary key")
  print(type(of: person).className())

  print(person)
}

@objcMembers class Article: Object {
  dynamic var id = 0
  dynamic var title: String?
}

Example.of("Using @objcMembers") {
  let article = Article()
  article.title = "New article about famous person"

  print(article)
}

// Challenge 1

@objcMembers class Book: Object {
  dynamic var ISBN = ""
  dynamic var title = ""
  dynamic var author = ""
  dynamic var bestseller = false
  dynamic var firstPublishDate = Date.distantPast
  dynamic var lastPublishDate: Date?

  convenience init(ISBN: String, title: String, author: String, firstPublish: Date) {
    self.init()
    self.ISBN = ISBN
    self.title = title
    self.author = author
    self.firstPublishDate = firstPublish
  }

  enum Property: String {
    case ISBN, bestseller
  }

  override static func primaryKey() -> String? {
    return Book.Property.ISBN.rawValue
  }

  override static func indexedProperties() -> [String] {
    return [Book.Property.bestseller.rawValue]
  }

  enum Classification: String {
    case fiction
    case nonFiction
    case selfHelp
  }

  @objc dynamic private var _type =
    Classification.fiction.rawValue

  var type: Classification {
    get { return Classification(rawValue: _type)! }
    set { _type = newValue.rawValue }
  }
}

Example.of("Challenge 1") {
  let book = Book(ISBN: "1234567890",
                  title: "Realm by Tutorials",
                  author: "Marin Todorov",
                  firstPublish: Date())
  book.bestseller = true
  book.type = .nonFiction

  print(book)
}

