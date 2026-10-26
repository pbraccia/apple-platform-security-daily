import Foundation

let files = FileManager.default
let repository = URL(fileURLWithPath: files.currentDirectoryPath)
let temporary = files.temporaryDirectory.appendingPathComponent(UUID().uuidString)
try files.createDirectory(at: temporary, withIntermediateDirectories: true)
defer { try? files.removeItem(at: temporary) }
try files.copyItem(at: repository.appendingPathComponent("blurbs.json"),
                   to: temporary.appendingPathComponent("blurbs.json"))

let picker = Process()
picker.executableURL = URL(fileURLWithPath: "/usr/bin/env")
picker.arguments = ["swift", repository.appendingPathComponent("pick_blurb.swift").path, "2027-01-01"]
picker.currentDirectoryURL = temporary
try picker.run()
picker.waitUntilExit()
precondition(picker.terminationStatus == 0, "Picker failed")

func readJSON(_ name: String) throws -> [String: Any] {
    let data = try Data(contentsOf: temporary.appendingPathComponent(name))
    return try JSONSerialization.jsonObject(with: data) as! [String: Any]
}

let today = try readJSON("today.json")
let week = try readJSON("week.json")["days"] as! [[String: Any]]
precondition(today["date"] as? String == "2027-01-01", "Wrong date in today.json")
precondition(!(today["blurb"] as! String).isEmpty, "Missing blurb")
precondition(week.count == 8, "Expected eight days in week.json")
precondition(week.first?["date"] as? String == "2026-12-31", "Wrong first date")
precondition(week.last?["date"] as? String == "2027-01-07", "Wrong last date")
precondition(NSDictionary(dictionary: week[1]).isEqual(to: today), "Today's entries differ")
print("Picker smoke test passed")
