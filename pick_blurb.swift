import Foundation

// Get a string of today's UTC date. Pass a date like 2027-01-01 to see what that day would show.
let dateFormatter = DateFormatter()
dateFormatter.dateFormat = "yyyy-MM-dd"
dateFormatter.timeZone = TimeZone(identifier: "UTC")!

var date = Date()
if CommandLine.arguments.count > 1 {
    date = dateFormatter.date(from: CommandLine.arguments[1])!
}
let todayString = dateFormatter.string(from: date)

// Find the blurbs.json file
let cwd = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let blurbsData = try Data(contentsOf: cwd.appendingPathComponent("blurbs.json"))
let blurbs = try JSONSerialization.jsonObject(with: blurbsData) as! [[String: Any]]

// A small random number generator that always gives the same numbers for the same seed.
// (SplitMix64 - the constants come from the original algorithm.)
struct SeededGenerator {
    var state: UInt64

    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}

// Shuffle the blurb indexes the same way every time for a given seed.
// We do the shuffle ourselves because Swift's built-in one isn't guaranteed
// to stay the same between Swift versions.
func shuffledIndexes(seed: Int) -> [Int] {
    var generator = SeededGenerator(state: UInt64(seed))
    var indexes = Array(blurbs.indices)
    for i in stride(from: indexes.count - 1, to: 0, by: -1) {
        let j = Int(generator.next() % UInt64(i + 1))
        indexes.swapAt(i, j)
    }
    return indexes
}

// Go through every blurb once, in a shuffled order, before starting over with a new order.
// Each pass is one "cycle" that lasts as many days as there are blurbs.
let daysSince1970 = Int(date.timeIntervalSince1970 / (24 * 60 * 60))
let cycle = daysSince1970 / blurbs.count
let dayInCycle = daysSince1970 % blurbs.count

var order = shuffledIndexes(seed: cycle)

// Don't let a new cycle start with the same blurb the last one ended on
if cycle > 0 && order.first == shuffledIndexes(seed: cycle - 1).last {
    order.swapAt(0, 1)
}

let index = order[dayInCycle]

// Merge the date field into the selected entry
var todayEntry: [String: Any] = ["date": todayString]
for (key, value) in blurbs[index] { todayEntry[key] = value }

// Write to today.json. Sorting the keys keeps the file identical between runs on the
// same day, otherwise Swift puts them in a random order and git sees a change.
let outputData = try JSONSerialization.data(
    withJSONObject: todayEntry,
    options: [.prettyPrinted, .sortedKeys]
)
try outputData.write(to: cwd.appendingPathComponent("today.json"))

print("\(todayString) → index \(index): \(blurbs[index]["section"] ?? "unknown")")
