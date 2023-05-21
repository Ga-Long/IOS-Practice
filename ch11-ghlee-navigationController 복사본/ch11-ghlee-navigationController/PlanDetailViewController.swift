//
//  PlanDetailViewConroller.swift
//  ch10-ghlee-stackView
//
//  Created by 이가현 on 2023/05/08.
//

import UIKit

class PlanDetailViewController: UIViewController {
    
    @IBOutlet weak var dateDatePicker: UIDatePicker!
    @IBOutlet weak var ownerLabel: UILabel!
    @IBOutlet weak var typePicker: UIPickerView!
    @IBOutlet weak var contentTextView: UITextView!
    
    var plan: Plan? // 나중에 PlanGroupViewController로부터 데이터를 전달받는다
    var saveChangeDelegate: ((Plan)-> Void)?

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        typePicker.dataSource = self
        typePicker.delegate = self
                
        plan = plan ?? Plan(date: Date(), withData: true)
        dateDatePicker.date = plan?.date ?? Date()
        ownerLabel.text = plan?.owner       // plan!.owner과 차이는? optional chainingtype

        // typePickerView 초기화
        if let plan = plan{
            typePicker.selectRow(plan.kind.rawValue, inComponent: 0, animated:false)
        }
        contentTextView.text = plan?.content
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)


    }
    
    @objc func dismissKeyboard(sender: UITapGestureRecognizer){
        view.endEditing(true)
    }
    
    @IBAction func gotoBack(_ sender: UIButton) {
        
        //plan 객체에 저장한 후 saveChangeDelete 호출
        plan!.date = dateDatePicker.date
        plan!.owner = ownerLabel.text    // 수정할 수 없는 UILabel이므로 필요없는 연산임
        plan!.kind = Plan.Kind(rawValue: typePicker.selectedRow(inComponent: 0))!
        plan!.content = contentTextView.text

        saveChangeDelegate?(plan!)

        saveChangeDelegate?(plan!)
        //dismiss(animated: true, completion: nil)
        navigationController?.popViewController(animated: true)

    }
    override func viewDidDisappear(_ animated: Bool) {
        if let saveChangeDelegate = saveChangeDelegate{
            plan!.content = contentTextView.text
            plan!.date = dateDatePicker.date
            plan!.owner = ownerLabel.text
            plan!.kind = Plan.Kind(rawValue: typePicker.selectedRow(inComponent: 0))!
            plan!.content = contentTextView.text
            saveChangeDelegate(plan!)
        }
    }
    
}


extension PlanDetailViewController:UIPickerViewDelegate, UIPickerViewDataSource{
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return Plan.Kind.count   // Plan.swift파일에서 count를 확인하라
    }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        let type = Plan.Kind(rawValue: row)    // 정수를 해당 Kind 타입으로 변환하는 것이다.
        return type!.toString()
    }
}
