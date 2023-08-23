//
//  Budget.swift
//  TDDAndRefactor
//
//  Created by SallyXie on 2023/8/23.
//

import Foundation

class BudgetService {
    private lazy var dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMM"
//        dateFormatter.locale = Locale(identifier: "zh_Hant_TW")
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)!
        return dateFormatter
    }()
    
    private lazy var calendar: Calendar = {
        var calendar = Calendar(identifier: .iso8601)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }()

    
    let repo: BudgetRepo

    init(repo: BudgetRepo) {
        self.repo = repo
    }

    func totalAmount(start: Date, end: Date) -> Decimal {
        if start > end {
            return 0
        }

        let budgets = self.repo.getAll()
        let startToEndMonthData = self.getStartToEndMonthData(budgets: budgets, start: start, end: end)

        if startToEndMonthData.isEmpty {
            return 0
        }
        
        var totalAmount: Decimal = 0.0

        for budget in startToEndMonthData {
            let yearMonthString = budget.yearMonth
            let daysInMonth = calendar.range(of: .day, in: .month, for: self.dateFormatter.date(from: yearMonthString)!)?.count ?? 30 // 預設每月30天
            let firstDay = budget.date.firstDateOfMonth
            let lastDay = budget.date.lastDateOfMonth
            let diffDay = firstDay.diffDay(toTime: lastDay)
            let dailyAmount = Decimal(budget.amount) / Decimal(daysInMonth) * Decimal(diffDay!)
            totalAmount += dailyAmount
        }
        
        return totalAmount
    }

    private func getStartToEndMonthData(budgets: [Budget], start: Date, end: Date) -> [Budget] {
        let filteredBudgets = budgets.filter { budget in
            if let budgetDate = self.dateFormatter.date(from: budget.yearMonth) {
                return lastDayOfMonth(for: budgetDate)! >= start && budgetDate <= end
            }
            return false
        }

        return filteredBudgets
    }
    
    func lastDayOfMonth(for date: Date) -> Date? {
        var components = DateComponents()
        var calendar = Calendar(identifier: .iso8601)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        
        components.year = calendar.component(.year, from: date)
        components.month = calendar.component(.month, from: date)
        components.day = 1 // 這裡先設定為1日，然後進行下個月份的減一天操作
        
        if let firstDayOfMonth = calendar.date(from: components) {
            let lastDay = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: firstDayOfMonth)
            return lastDay
        }
        
        return nil
    }
}


protocol BudgetRepo {
    func getAll() -> [Budget]
}

class MockBudgetRepo: BudgetRepo {
    let budgets: [Budget]

    init(budgets: [Budget]) {
        self.budgets = budgets
    }

    func getAll() -> [Budget] {
        return self.budgets
    }
}

struct Budget {
    let yearMonth: String
    let amount: Int

    var date: Date {
        return self.getDate(from: self.yearMonth)
    }

    private func getDate(from yearMonth: String) -> Date {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMM"

        if let date = dateFormatter.date(from: yearMonth) {
            let calendar = Calendar.current
            let components = calendar.dateComponents([.year, .month], from: date)
            return calendar.date(from: components) ?? Date()
        }

        return Date()
    }
}

extension Date {
    
    var calendar: Calendar {
        var calendar = Calendar(identifier: .iso8601)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }
    
     func isBetween(_ date1: Date, and date2: Date) -> Bool {
         return (min(date1, date2) ... max(date1, date2)).contains(self)
     }
     
     /// 台灣時區的當年 (西元年)
     var year: Int {
        
         let component = calendar.dateComponents([.year], from: self)
         return component.year ?? -1
     }
     
     /// 台灣時區的當月份
     var month: Int {
         let component = calendar.dateComponents([.month], from: self)
         return component.month ?? -1
     }
     
     /// 台灣時區的當月第一天  00:00 日期 (Date 為絕對值不分時區, 因此回傳值會顯示為 GMT+0 的日期)
     var firstDateOfMonth: Date {
         let component = calendar.dateComponents([.year, .month], from: self)
         return calendar.date(from: component) ?? Date()
     }
     
     /// 台灣時區的當月最後一天 00:00 日期 (Date 為絕對值不分時區, 因此回傳值會顯示為 GMT+0 的日期)
     var lastDateOfMonth: Date {
         var component = calendar.dateComponents([.year, .month, .day], from: self)
         component.day = 0
         component.month! += 1
         return calendar.date(from: component) ?? Date()
     }
     
     func diffDay(toTime: Date, calendar: Calendar = .current) -> Int? {
         let formerTime = calendar.startOfDay(for: self)
         let endTime = calendar.startOfDay(for: toTime)

         return calendar.dateComponents([.day], from: formerTime, to: endTime).day
     }
}
