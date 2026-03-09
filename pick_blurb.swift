#!/usr/bin/env swift
import Foundation
import CryptoKit

// Get today's UTC date string
let dateFormatter = DateFormatter()
dateFormatter.dateFormat = "yyyy-MM-dd"
dateFormatter.timeZone = TimeZone(identifier: "UTC")!
let todayString = dateFormatter.string(from: Date())

// Resolve paths relative to the current working directory (repo root in CI)
let cwd = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let blurbsData = try Data(contentsOf: cwd.appendingPathComponent("blurbs.json"))
let blurbs = try JSONSerialization.jsonObject(with: blurbsData) as! [[String: Any]]

// SHA-256 hash of the date string → deterministic daily index
let digest = SHA256.hash(data: Data(todayString.utf8))
let hashValue = digest.prefix(8).reduce(UInt64(0)) { ($0 << 8) | UInt64($1) }
let index = Int(hashValue % UInt64(blurbs.count))

// Merge the date field into the selected entry
var todayEntry: [String: Any] = ["date": todayString]
for (key, value) in blurbs[index] { todayEntry[key] = value }

// Write to today.json
let outputData = try JSONSerialization.data(
    withJSONObject: todayEntry,
    options: [.prettyPrinted, .sortedKeys]
)
try outputData.write(to: cwd.appendingPathComponent("today.json"))

print("✓ \(todayString) → index \(index): \(blurbs[index]["section"] ?? "unknown")")
