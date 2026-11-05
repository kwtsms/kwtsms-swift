import KwtSMS

let sms = KwtSMS.fromEnv()

// Load your recipient list (in practice, from your database).
// 965XXXXXXXX is a placeholder: replace it with your recipients' numbers.
let numbers: [String] = [
    "965XXXXXXXX",
    // add more numbers here
]

// sendBulk() auto-batches >200 numbers
let result = await sms.sendBulk(mobiles: numbers, message: "Campaign announcement from MyApp")

print("Result: \(result.result)")     // "OK", "PARTIAL", or "ERROR"
print("Batches: \(result.batches)")
print("Numbers sent: \(result.numbers)")
print("Credits used: \(result.pointsCharged)")
print("Balance: \(result.balanceAfter ?? 0)")
print("Message IDs: \(result.msgIds)")

if !result.errors.isEmpty {
    print("Batch errors:")
    for err in result.errors {
        print("  Batch \(err.batch): \(err.code) \(err.description)")
    }
}

if !result.invalid.isEmpty {
    print("Invalid numbers: \(result.invalid.count)")
}
