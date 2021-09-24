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

final class DataWriterDedicatedThread: NSObject, DataWriterType {
  private var writeRealm: Realm!
  private var thread: Thread!

  private var sensors: Sensor.SensorMap!

  private static let bufferMaxCount = 1000
  private var buffer = [String: [Reading]]()
  private var bufferCount = 0

  override init() {
    super.init()

    thread = Thread(target: self,
                    selector: #selector(threadWorker),
                    object: nil)
    thread.start()
  }

  func write(sym: String, value: Double) {
    precondition(thread != nil, "Thread not initialized")

    perform(#selector(addReading),
            on: thread,
            with: [sym: value],
            waitUntilDone: false,
            modes: [RunLoop.Mode.default.rawValue])
  }

  @objc private func threadWorker() {
    defer { Thread.exit() }
    writeRealm = RealmProvider.sensors.realm
    sensors = Sensor.sensorMap(in: writeRealm)

    while thread != nil, !thread.isCancelled {
      RunLoop.current.run(
        mode: RunLoop.Mode.default,
        before: Date.distantFuture)
    }

    writeBuffer(buffer)
    sensors = nil
  }

  @objc private func addReading(reading: [String: Double]) {
    guard let sym = reading.keys.first,
          let value = reading[sym] else { return }

    var bufferToProcess: [String: [Reading]] = [:]

    if buffer[sym] == nil {
      buffer[sym] = []
    }

    buffer[sym]!.append(Reading(value))
    bufferCount += 1

    if bufferCount > DataWriterDedicatedThread.bufferMaxCount {
      bufferToProcess = buffer
      bufferCount = 0
      buffer = [:]
    }

    guard !bufferToProcess.isEmpty else { return }
    writeBuffer(bufferToProcess)
  }

  func writeBuffer(_ batch: [String: [Reading]]) {
    try! writeRealm.write {
      batch.forEach { sym, values in
        sensors[sym]?.addReadings(values)
      }
    }
  }

  func invalidate() {
    thread.cancel()
  }
}

