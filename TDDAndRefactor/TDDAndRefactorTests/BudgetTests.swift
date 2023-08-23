//
//  BudgetTests.swift
//  TDDAndRefactorTests
//
//  Created by SallyXie on 2023/8/23.
//

import XCTest
@testable import TDDAndRefactor

final class BudgetTests: XCTestCase {
    let dateFormat = dateFormatter
    
    var sut: BudgetService!

    override func setUpWithError() throws {
    
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func test_非法起迄() {
        self.given(budgets: [Budget(yearMonth: "202312", amount: 3100), Budget(yearMonth: "202311", amount: 3000)])
        XCTAssertEqual(self.sut.totalAmount(start: self.stringToDate("20230823"), end: self.stringToDate("20230821")), 0)
    }

    func test_查無該月份() {
        self.given(budgets: [Budget(yearMonth: "202305", amount: 0)])
        
        XCTAssertEqual(self.sut.totalAmount(start: self.stringToDate("20230601"), end: self.stringToDate("20230602")), 0)
    }

    func test_該月份無預算() {
        self.given(budgets: [Budget(yearMonth: "202305", amount: 0)])
        XCTAssertEqual(self.sut.totalAmount(start: self.stringToDate("20230501"), end: self.stringToDate("20230502")), 0)
    }
    
    func test_當月份有預算() {
        self.given(budgets: [Budget(yearMonth: "202308", amount: 31)])
        XCTAssertEqual(self.sut.totalAmount(start: self.stringToDate("20230829"), end: self.stringToDate("20230829")), 1)
    }
    
    func test_月份有預算_兩個月() {
        self.given(budgets: [Budget(yearMonth: "202308", amount: 31),
                             Budget(yearMonth: "202309", amount: 300)])
        XCTAssertEqual(self.sut.totalAmount(start: self.stringToDate("20230831"), end: self.stringToDate("20230902")), 21)
    }
    
    func test_月份有預算_三個月() {
        self.given(budgets: [Budget(yearMonth: "202308", amount: 31),
                             Budget(yearMonth: "202309", amount: 300),
                             Budget(yearMonth: "202310", amount: 3100)
                            ])
        XCTAssertEqual(self.sut.totalAmount(start: self.stringToDate("20230831"), end: self.stringToDate("20231002")), 501)
    }
    
    func test_潤年有預算() {
        self.given(budgets: [Budget(yearMonth: "202402", amount: 29),
                             Budget(yearMonth: "202403", amount: 310)
                            ])
        XCTAssertEqual(self.sut.totalAmount(start: self.stringToDate("20240227"), end: self.stringToDate("20240301")), 13)
    }
    
    func test_非潤年有預算() {
        self.given(budgets: [Budget(yearMonth: "202302", amount: 28),
                             Budget(yearMonth: "202303", amount: 310)
                            ])
        XCTAssertEqual(self.sut.totalAmount(start: self.stringToDate("20230227"), end: self.stringToDate("20230301")), 12)
    }

    private func stringToDate(_ dateString: String, format: String = "YYYYMMdd") -> Date! {
    
        dateFormat.dateFormat = format
        
        return dateFormat.date(from: dateString)
    }

    private func getMockDate() -> [Budget] {
        return [
            Budget(yearMonth: "202312", amount: 3100),
            Budget(yearMonth: "202311", amount: 3000),
            Budget(yearMonth: "202310", amount: 310),
            Budget(yearMonth: "202309", amount: 300),
            Budget(yearMonth: "202308", amount: 31),
            Budget(yearMonth: "202305", amount: 0),
        ]
    }

    private func given(budgets: [Budget]) {
        let repo = MockBudgetRepo(budgets: budgets)
        self.sut = BudgetService(repo: repo)
    }
}
