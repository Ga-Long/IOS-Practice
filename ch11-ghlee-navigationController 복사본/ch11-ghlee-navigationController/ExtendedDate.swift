//
//  ExtendedDate.swift
//  ch09-ghlee-tableView
//
//  Created by 이가현 on 2023/05/01.
//

import UIKit


extension Date{
    
    // extension에서는 정적변수와 함수만 추가될수 있다
    static  let calendar = Calendar(identifier: .gregorian)
    static  let dateFormatter = DateFormatter()
    
    func setCurrentTime() -> Date{ ... }    // 현재 시간을 설정된 Date를 리턴
    func firstOfDay() -> Date{ ... }        // yyyy-mm-dd 00:00:00로 설정된 Date를 리턴
    func lastOfDay() -> Date{ ... }         // yyyy-mm-dd 23:59:59로 설정된 Date를 리턴
    func firstOfWeek() -> Date{ ... }       // 이 날자가 속한 주의 일요일로 설정된 Date를 리턴
    func lastOfWeek() -> Date{ ... }        // 이 날자가 속한 주의 토요일로 설정된 Date를 리턴
    func firstOfMonth() -> Date{ ... }      // 이 날자가 속한 달의 1일로 설정된 Date를 리턴
    func lastOfMonth() -> Date{ ... }       // 이 날자가 속한 달의 마지막로 설정된 Date를 리턴
    func toStringMonth() -> String{ ... }   // 이 날자를 YYYY-MM의 문자열로 리턴
    func toStringDate() -> String{ ... }    // 이 날자를 YYYY-MM-DD의 문자열로 리턴
    func toStringDateTime() -> String{ ... }// 이 날자를 YYYY-MM-DD hh:mm:ss의 문자열로 리턴
}

