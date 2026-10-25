import Foundation

// Get a string of today's UTC date
let dateFormatter = ISO8601DateFormatter()
dateFormatter.formatOptions = [.withFullDate]
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

// A small deterministic random number generator (SplitMix64)
struct SeededGenerator: RandomNumberGenerator {
    var state: UInt64

    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}

// Shuffle the blurb indexes using the current cycle number
func shuffledIndexes(forCycle cycle: Int) -> [Int] {
    var generator = SeededGenerator(state: UInt64(cycle))
    return Array(blurbs.indices).shuffled(using: &generator)
}

var utcCalendar = Calendar(identifier: .gregorian)
utcCalendar.timeZone = dateFormatter.timeZone
let epoch = Date(timeIntervalSince1970: 0)

// Go through every blurb once, in a shuffled order, before starting over with a new order.
func blurbIndex(forDay day: Int) -> Int {
    let (cycle, dayInCycle) = day.quotientAndRemainder(dividingBy: blurbs.count)
    var order = shuffledIndexes(forCycle: cycle)

    // Don't let a new cycle start with the same blurb the last one ended on
    if cycle > 0 && order.first == shuffledIndexes(forCycle: cycle - 1).last {
        order.swapAt(0, 1)
    }

    return order[dayInCycle]
}

func entry(forDay day: Int) -> [String: Any] {
    let entryDate = utcCalendar.date(byAdding: .day, value: day, to: epoch)!
    var entry: [String: Any] = ["date": dateFormatter.string(from: entryDate)]
    for (key, value) in blurbs[blurbIndex(forDay: day)] { entry[key] = value }
    return entry
}

// Sorting the keys keeps the files identical between runs on the same day.
func write(_ object: Any, to fileName: String) throws {
    let data = try JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys])
    try data.write(to: cwd.appendingPathComponent(fileName))
}

let today = utcCalendar.dateComponents(
    [.day],
    from: epoch,
    to: utcCalendar.startOfDay(for: date)
).day!

// today.json: just today's blurb (UTC)
try write(entry(forDay: today), to: "today.json")

// Include yesterday for time zones behind UTC and a week starting today so the
// display keeps working through short delays or failures in the daily workflow.
let days = (today - 1...today + 6).map { entry(forDay: $0) }
try write(["days": days], to: "week.json")

let todayIndex = blurbIndex(forDay: today)
print("\(todayString) → index \(todayIndex): \(blurbs[todayIndex]["section"] ?? "unknown")")
