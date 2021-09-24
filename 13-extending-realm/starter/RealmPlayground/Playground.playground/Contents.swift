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

// Setup
let realm = try! Realm(
  configuration: Realm.Configuration(inMemoryIdentifier: "TemporaryRealm"))

print("Ready to play!")

// Person
@objcMembers
class Person: Object {
  enum Key: String {
    case insurance, car
  }

  dynamic var name = ""
  dynamic var car: Car?
  dynamic var insurance: InsurancePolicy?

  convenience init(_ name: String) {
    self.init()
    self.name = name
  }
}

// Car
@objcMembers
class Car: Object {
  enum Key: String {
    case insurances
  }

  dynamic var name = ""
  let insurances = List<InsurancePolicy>()

  convenience init(_ name: String) {
    self.init()
    self.name = name
  }
}

// Insurance Policy
@objcMembers
class InsurancePolicy: Object {
  dynamic var name = ""
  convenience init(_ name: String) {
    self.init()
    self.name = name
  }
}

// Build some test data

let jane = Person("Jane")
let car = Car("Tesla")
car.insurances.append(InsurancePolicy("Full Auto"))
car.insurances.append(InsurancePolicy("Heli pickup"))
jane.car = car

let life = InsurancePolicy("Life insurance")
jane.insurance = life

try! realm.write {
  realm.add(jane)
}

// Print the current objects

print(jane)

print("------------")
print("People: \(realm.objects(Person.self).count)")
print("Cars: \(realm.objects(Car.self).count)")
print("Insurances: \(realm.objects(InsurancePolicy.self).count)")
