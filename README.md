# Strix 🦉
[![Swift](https://github.com/nearfri/Strix/actions/workflows/swift.yml/badge.svg)](https://github.com/nearfri/Strix/actions/workflows/swift.yml)
[![Swift Compatibility](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fnearfri%2FStrix%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/nearfri/Strix)
[![Platform Compatibility](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fnearfri%2FStrix%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/nearfri/Strix)
[![codecov](https://codecov.io/gh/nearfri/Strix/branch/main/graph/badge.svg?token=G7bysdMZ41)](https://codecov.io/gh/nearfri/Strix)

Strix is a parser combinator library written in Swift.

## Installation

### Swift Package Manager
```swift
dependencies: [.package(url: "https://github.com/nearfri/Strix.git", from: "2.0.0")],
targets: [.target(name: "<Your Target Name>", dependencies: ["Strix"])]
```

## Example
### CSV Parsing
| Year | Make | Model | Description | Price |
| ---- | ---- | ----- | ----------- | ----- |
| 1997 | Ford | E350 | ac, abs, moon | 3000.00 |
| 1999 | Chevy | Venture "Extended Edition" | | 4900.00 |
| 1999 | Chevy | Venture "Extended Edition, Very Large" | | 5000.00 |
| 1996 | Jeep | Grand Cherokee | MUST SELL!<br>air, moon roof, loaded | 4799.00 |

The above table of data may be represented in CSV format as follows:
```
Year,Make,Model,Description,Price
1997,Ford,E350,"ac, abs, moon",3000.00
1999,Chevy,"Venture ""Extended Edition""","",4900.00
1999,Chevy,"Venture ""Extended Edition, Very Large""",,5000.00
1996,Jeep,Grand Cherokee,"MUST SELL!
air, moon roof, loaded",4799.00
```

It consists of data records represented by lines which are made of one or more fields separated by commas.
Sophisticated CSV implementations permit special characters such as newline, comma and double quotes.
They are allowed by requiring " (double quote) characters around the fields containing them.
Embedded double quote are represented by a pair of consecutive double quotes.

Following is an example of a CSV parser:
```swift
import Strix

let doubleQuote: Parser<Character> = .character("\"")
let twoDoubleQuote: Parser<Character> = Parser.string("\"\"") *> .just("\"")
let escapedText: Parser<String> = Parser.many((.none(of: "\"") <|> twoDoubleQuote))
    .map({ String($0) })
let escapedField: Parser<String> = doubleQuote *> escapedText <* doubleQuote

let nonSeparator: Parser<Character> = .satisfy("non-separator", { $0 != "," && !$0.isNewline })
let nonEscapedField: Parser<String> = .skipped(by: .many(nonSeparator))

let field: Parser<String> = escapedField <|> nonEscapedField
let record: Parser<[String]> = .many(field, separatedBy: .character(","))

let csvParser: Parser<[[String]]> = .many(record, separatedBy: .newline)
```

Passing the above CSV as `csvString` to `try csvParser.run(csvString)` will return:
```swift
[
    ["Year", "Make", "Model", "Description", "Price"],
    ["1997", "Ford", "E350", "ac, abs, moon", "3000.00"],
    ["1999", "Chevy", "Venture \"Extended Edition\"", "", "4900.00"],
    ["1999", "Chevy", "Venture \"Extended Edition, Very Large\"", "", "5000.00"],
    ["1996", "Jeep", "Grand Cherokee", "MUST SELL!\nair, moon roof, loaded", "4799.00"]
]
```

If you want more examples, see [StrixParsers](./Sources/StrixParsers/).

## License
Strix is released under the MIT license. See LICENSE for more information.
