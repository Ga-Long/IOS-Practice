//
//  PlanGroup.swift
//  ch09-ghlee-tableView
//
//  Created by 이가현 on 2023/05/01.
//

import UIKit


class PlanGroup: NSObject{
    var plans = [Plan]()            // var plans: [Plan] = []와 동일, 퀴리를 만족하는 plan들만 저장한다.
    var fromDate, toDate: Date?     // queryPlan 함수에서 주어진다.
    var database: Database!
    var parentNotification: ((Plan?, DbAction?) -> Void)?
    
    init(parentNotification: ((Plan?, DbAction?) -> Void)? ){
        super.init()
        self.parentNotification = parentNotification
        database = DbMemory(parentNotification: receivingNotification) // 데이터베이스 생성
    }
    
    func queryData(date: Date){
            plans.removeAll()    // 새로운 쿼리에 맞는 데이터를 채우기 위해 기존 데이터를 전부 지운다
            
            // date가 속한 1개월 +-알파만큼 가져온다
            fromDate = date.firstOfMonth().firstOfWeek()// 1일이 속한 일요일을 시작시간
            toDate = date.lastOfMonth().lastOfWeek()    // 이달 마지막일이 속한 토요일을 마감시간
            database.queryPlan(fromDate: fromDate!, toDate: toDate!)
        }
        
        func saveChange(plan: Plan, action: DbAction){
            // 단순히 데이터베이스에 변경요청을 하고 plans에 대해서는
            // 데이터베이스가 변경알림을 호출하는 receivingNotification에서 적용한다
            database.saveChange(plan: plan, action: action)
        }

    func receivingNotification(plan: Plan?, action: DbAction?){
        // 데이터베이스로부터 메시지를 받고 이를 부모에게 전달한다
        if let plan = plan{
            switch(action){    // 액션에 따라 적절히     plans에 적용한다
                case .Add: addPlan(plan: plan)
                case .Modify: modifyPlan(modifiedPlan: plan)
                case .Delete: removePlan(removedPlan: plan)
                default: break
            }
        }
        if let parentNotification = parentNotification{
            parentNotification(plan, action) // 역시 부모에게 알림내용을 전달한다.
        }
    }
}

extension PlanGroup{     // PlanGroup.swift
    func getPlans(date: Date? = nil) -> [Plan] {
        
        // plans중에서 date날짜에 있는 것만 리턴한다
        if let date = date{
            var planForDate: [Plan] = []
            let start = date.firstOfDay()    // yyyy:mm:dd 00:00:00
            let end = date.lastOfDay()    // yyyy:mm”dd 23:59:59
            for plan in plans{
                if plan.date >= start && plan.date <= end {
                    planForDate.append(plan)
                }
            }
            return planForDate
        }
        return plans
    }
}

extension PlanGroup{     // PlanGroup.swift
    
    private func count() -> Int{ return plans.count }
    
    func isIn(date: Date) -> Bool{
        if let from = fromDate, let to = toDate{
            return (date >= from && date <= to) ? true: false
        }
        return false
    }
    
    private func find(_ key: String) -> Int?{
        for i in 0..<plans.count{
            if key == plans[i].key{
                return i
            }
        }
        return nil
    }
}

extension PlanGroup{         // PlanGroup.swift
    private func addPlan(plan:Plan){ plans.append(plan) }
    private func modifyPlan(modifiedPlan: Plan){
        if let index = find(modifiedPlan.key){
            plans[index] = modifiedPlan
        }
    }
    private func removePlan(removedPlan: Plan){
        if let index = find(removedPlan.key){
            plans.remove(at: index)
        }
    }
    func changePlan(from: Plan, to: Plan){
        if let fromIndex = find(from.key), let toIndex = find(to.key) {
            plans[fromIndex] = to
            plans[toIndex] = from
        }
    }
}




