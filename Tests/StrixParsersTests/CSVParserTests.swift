import Testing
@testable import StrixParsers

@Suite struct CSVParserTests {
    private let sut = CSVParser()
    
    @Test func parse_nonQuotedField() throws {
        let csvString = """
            Year,Make,Model Name,Description,Price
            """
        
        let csv: CSV = [[
            "Year", "Make", "Model Name", "Description", "Price"
        ]]
        
        try #expect(sut.parse(csvString) == csv)
    }
    
    @Test func parse_quotedField() throws {
        let csvString = """
            1997,Ford,E350,"ac, abs, moon",3000.00
            """
        
        let csv: CSV = [[
            "1997", "Ford", "E350", "ac, abs, moon", "3000.00"
        ]]
        
        try #expect(sut.parse(csvString) == csv)
    }
    
    @Test func parse_doubleQuotedField() throws {
        let csvString = #"""
            1999,Chevy,"Venture ""Extended Edition""","",4900.00
            """#
        
        let csv: CSV = [[
            "1999", "Chevy", "Venture \"Extended Edition\"", "", "4900.00"
        ]]
        
        try #expect(sut.parse(csvString) == csv)
    }
    
    @Test func parse_multilineField() throws {
        let csvString = """
            1996,Jeep,Grand Cherokee,"MUST SELL!
            air, moon roof, loaded",4799.00
            """
        
        let csv: CSV = [[
            "1996", "Jeep", "Grand Cherokee", "MUST SELL!\nair, moon roof, loaded", "4799.00"
        ]]
        
        try #expect(sut.parse(csvString) == csv)
    }
    
    @Test func parse_empty() throws {
        let csvString = ""
        
        let csv: CSV = []
        
        try #expect(sut.parse(csvString) == csv)
    }
    
    @Test func parse_emptyLine() throws {
        let csvString = """
            Year,Make
            
            """
        
        let csv: CSV = [[
            "Year", "Make"
        ]]
        
        try #expect(sut.parse(csvString) == csv)
    }
    
    @Test func parse_complex() throws {
        let csvString = #"""
            Year,Make,Model,Description,Price
            1997,Ford,E350,"ac, abs, moon",3000.00
            1999,Chevy,"Venture ""Extended Edition""","",4900.00
            1999,Chevy,"Venture ""Extended Edition, Very Large""",,5000.00
            1996,Jeep,Grand Cherokee,"MUST SELL!
            air, moon roof, loaded",4799.00
            """#
        
        let csv: CSV = [
            ["Year", "Make", "Model", "Description", "Price"],
            ["1997", "Ford", "E350", "ac, abs, moon", "3000.00"],
            ["1999", "Chevy", "Venture \"Extended Edition\"", "", "4900.00"],
            ["1999", "Chevy", "Venture \"Extended Edition, Very Large\"", "", "5000.00"],
            ["1996", "Jeep", "Grand Cherokee", "MUST SELL!\nair, moon roof, loaded", "4799.00"]
        ]
        
        try #expect(sut.parse(csvString) == csv)
    }
}
