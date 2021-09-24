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

protocol CascadeDeleting {
  func hardCascadeDeleteProperties() -> [String]
  func softCascadeDeleteProperties() -> [String]
}

protocol ConditionallyDeleted {
  func shouldBeConditionallyDeleted() -> Bool
}

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

extension Person: CascadeDeleting {
  func hardCascadeDeleteProperties() -> [String] {
    return [Key.insurance.rawValue]
  }
  func softCascadeDeleteProperties() -> [String] {
    return [Key.car.rawValue]
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

extension Car: CascadeDeleting {
  func hardCascadeDeleteProperties() -> [String] {
    return [Key.insurances.rawValue]
  }
  func softCascadeDeleteProperties() -> [String] {
    return []
  }
}

extension Car: ConditionallyDeleted {
  func shouldBeConditionallyDeleted() -> Bool {
    guard Calendar.current.component(.weekday, from: Date()) == 2 else {
      return false
    }
    return true
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

extension Realm {
  func cascadeDelete(_ object: Object) {
    guard let cascading = object as? CascadeDeleting else {
      if let conditionalObject = object as? ConditionallyDeleted {
        guard conditionalObject.shouldBeConditionallyDeleted() else { return }
      }
      delete(object)
      return
    }

    for property in cascading.hardCascadeDeleteProperties() {
      if let linkedObject = object.value(forKey: property) as? Object {
        cascadeDelete(linkedObject)
        continue
      }
      if let linkedObjects = object.value(forKey: property) as? ListBase {
        (0..<linkedObjects._rlmArray.count)
          .compactMap {
            linkedObjects._rlmArray.object(at: $0) as? Object
          }
          .forEach(cascadeDelete)
        continue
      }
    }

    for property in cascading.softCascadeDeleteProperties() {
      guard let linkedObject = object.value(forKey: property) as? Object
        else { continue }

      let predicate = NSPredicate(format: "%K = %@",
                                  property,
                                  linkedObject)

      guard realm.objects(type(of: object))
                 .filter(predicate)
                 .count <= 1 else { continue }

      cascadeDelete(linkedObject)
    }

    if let conditionalObject = object as? ConditionallyDeleted {
      guard conditionalObject.shouldBeConditionallyDeleted() else { return }
    }

    delete(object)
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

let john = Person("John")
john.car = car

try! realm.write {
  realm.add(jane)
  realm.add(john)
}

// Print the current objects

try! realm.write {
  realm.cascadeDelete(jane)
  realm.cascadeDelete(john)
}

print("------------")
print("People: \(realm.objects(Person.self).count)")
print("Cars: \(realm.objects(Car.self).count)")
print("Insurances: \(realm.objects(InsurancePolicy.self).count)")
