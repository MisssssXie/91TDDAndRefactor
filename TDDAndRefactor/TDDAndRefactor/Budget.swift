//
//  Budget.swift
//  TDDAndRefactor
//
//  Created by SallyXie on 2023/8/23.
//

import Foundation

let timeZone = TimeZone(secondsFromGMT: 0)!

var calendar: Calendar {
    var calendar = Calendar(identifier: .iso8601)
    calendar.timeZone = timeZone
    return calendar
}

class BudgetService {

    let repo: BudgetRepo

    init(repo: BudgetRepo) {
        self.repo = repo
    }

    func totalAmount(start: Date, end: Date) -> Decimal {
        
        let startToEndMonthData = self.getValidBudgets(budgets: self.repo.getAll(), start: start, end: end)
        
        var totalAmount: Decimal = 0.0

        for budget in startToEndMonthData {

            var startDay = start
            var endDay = end

            if (start.yearMonth == end.yearMonth) {
                startDay = start
                endDay = end
            }
            else if let firstDateOfMonth = startToEndMonthData.first,
               budget.yearMonth == firstDateOfMonth.yearMonth {
                
                startDay = start
                endDay = budget.lastDateOfMonth
            }
            else if let lastDateOfMonth = startToEndMonthData.last,
                    budget.yearMonth == lastDateOfMonth.yearMonth {

                startDay = budget.firstDateOfMonth
                endDay = end
            }
            else {

                startDay = budget.firstDateOfMonth
                endDay = budget.lastDateOfMonth
            }

            totalAmount += getPeriodAmount(startDay, endDay, budget.dailyAmount())
        }
        
        return totalAmount
    }


    private func getPeriodAmount(_ startDate: Date, _ endDate: Date, _ dailyAmount: Decimal) -> Decimal {

        let diffDay = startDate.getDiffDay(toTime: endDate)
        return dailyAmount * (Decimal(diffDay) + 1)
    }

    private func getValidBudgets(budgets: [Budget], start: Date, end: Date) -> [Budget] {

        let filteredBudgets = budgets.filter { budget in
            return budget.lastDateOfMonth >= start && budget.firstDateOfMonth <= end
        }

        return filteredBudgets
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

    var firstDateOfMonth: Date {
        return self.date.firstDateOfMonth
    }

    var lastDateOfMonth: Date {
        return self.date.lastDateOfMonth
    }

    private var date: Date {
        return self.getDate(from: self.yearMonth)
    }

    private func getDate(from yearMonth: String) -> Date {

        if let date = self.getDateFormatter().date(from: yearMonth) {
            return date.yearMonth
        }

        return Date()
    }

    func dailyAmount() -> Decimal {

        // 預設每月30天
        let daysInMonth = calendar.range(of: .day, in: .month, for: self.getDateFormatter().date(from: self.yearMonth)!)?.count ?? 30

        // 每日預算
        let dailyAmount = Decimal(self.amount) / Decimal(daysInMonth)
        return dailyAmount
    }

    func getDateFormatter() -> DateFormatter {

        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = timeZone
        dateFormatter.dateFormat = "yyyyMM"
        return dateFormatter
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

    var yearMonth: Date {

        let components = calendar.dateComponents([.year, .month], from: self)
        return calendar.date(from: components) ?? Date()
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
     
     func getDiffDay(toTime: Date) -> Int {
         let formerTime = calendar.startOfDay(for: self)
         let endTime = calendar.startOfDay(for: toTime)

         return calendar.dateComponents([.day], from: formerTime, to: endTime).day ?? 0
     }
}
