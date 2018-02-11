//
//  ResultViewController.swift
//  IOSMyQuiz
//
//  Created by Yuske Fukuyama on 2018/02/11.
//  Copyright © 2018 Yuske Fukuyama. All rights reserved.
//

import UIKit

class ResultViewController: UIViewController {

    @IBOutlet weak var correctPercentLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        let questionDataArray = QuestionDataManager.sharedInstance.questionDataArray

        let questionCount = questionDataArray.count

        var correctCount: Int = 0
        for questionData in questionDataArray {
            if questionData.isCorrect() {
                correctCount += 1
            }
        }

        let correctPercent: Float = (Float(correctCount) / Float(questionCount)) * 100
        correctPercentLabel.text = String(format: "%.1f", correctPercent) + "%"
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
}
