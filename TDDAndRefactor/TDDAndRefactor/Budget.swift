//
//  Budget.swift
//  TDDAndRefactor
//
//  Created by SallyXie on 2023/8/23.
//

import Foundation

let timeZone = TimeZone(secondsFromGMT: 0)!

var dateFormatter: DateFormatter {
    let dateFormatter = DateFormatter()
    dateFormatter.timeZone = timeZone
    return dateFormatter
}

var calendar: Calendar {
    var calendar = Calendar(identifier: .iso8601)
    calendar.timeZone = timeZone
    return calendar
}

class BudgetService {
    private lazy var dateFormat: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = timeZone
        dateFormatter.dateFormat = "yyyyMM"
        return dateFormatter
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
            
            let dailyAmount = self.dailyAmount(budget)
            
            if startToEndMonthData.count == 1 {
                let diffDay = start.diffDay(toTime: end)
                let amount = dailyAmount * (Decimal(diffDay!) + 1)
                totalAmount += amount
                continue
            }
            
            if let firstDateOfMonth = startToEndMonthData.first,
               budget.yearMonth == firstDateOfMonth.yearMonth {
                let lastDay = budget.date.lastDateOfMonth
                let diffDay = start.diffDay(toTime: lastDay)
                let amount = dailyAmount * (Decimal(diffDay!) + 1)
                totalAmount += amount
                continue
            }
            
            if let lastDateOfMonth = startToEndMonthData.last,
               budget.yearMonth == lastDateOfMonth.yearMonth {
                let firstDay = budget.date.firstDateOfMonth
                let diffDay = firstDay.diffDay(toTime: end)
                let amount = dailyAmount * (Decimal(diffDay!) + 1)
                totalAmount += amount
                continue
            }
            
            totalAmount += Decimal(budget.amount)
        }
        
        return totalAmount
    }

    private func getStartToEndMonthData(budgets: [Budget], start: Date, end: Date) -> [Budget] {
        let filteredBudgets = budgets.filter { budget in
            let budgetDate = budget.date.firstDateOfMonth
            return budgetDate.lastDateOfMonth >= start && budgetDate <= end
        }

        return filteredBudgets
    }
    
    fileprivate func dailyAmount(_ budget: Budget) -> Decimal {
        // 預設每月30天
        let daysInMonth = calendar.range(of: .day, in: .month, for: self.dateFormat.date(from: budget.yearMonth)!)?.count ?? 30
        let firstDay = budget.date.firstDateOfMonth
        let lastDay = budget.date.lastDateOfMonth
        // 每日預算
        let dailyAmount = Decimal(budget.amount) / Decimal(daysInMonth)
        return dailyAmount
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
        dateFormatter.timeZone = timeZone
        dateFormatter.dateFormat = "yyyyMM"
        if let date = dateFormatter.date(from: yearMonth) {
            let components = calendar.dateComponents([.year, .month], from: date)
            return calendar.date(from: components) ?? Date()
        }

        return Date()
    }
}

extension Date {
    
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
     
     func diffDay(toTime: Date) -> Int? {
         let formerTime = calendar.startOfDay(for: self)
         let endTime = calendar.startOfDay(for: toTime)

         return calendar.dateComponents([.day], from: formerTime, to: endTime).day
     }
}
