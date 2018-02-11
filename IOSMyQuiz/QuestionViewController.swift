//
//  QuestionViewController.swift
//  IOSMyQuiz
//
//  Created by Yuske Fukuyama on 2018/02/11.
//  Copyright © 2018 Yuske Fukuyama. All rights reserved.
//

import UIKit
import AudioToolbox

class QuestionViewController: UIViewController {
    var questionData: QuestionData!

    @IBOutlet weak var questionNumberLable: UILabel!
    @IBOutlet weak var questionTextView: UITextView!
    @IBOutlet weak var choice1Button: UIButton!
    @IBOutlet weak var choice2Button: UIButton!
    @IBOutlet weak var choice3Button: UIButton!
    @IBOutlet weak var choice4Button: UIButton!

    @IBOutlet weak var correctImageView: UIImageView!
    @IBOutlet weak var incorrectImageView: UIImageView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        questionNumberLable.text = "Q. \(questionData.questionNumber)"
        questionTextView.text = questionData.questionText
        choice1Button.setTitle(questionData.choice1, for: UIControlState.normal)
        choice2Button.setTitle(questionData.choice2, for: UIControlState.normal)
        choice3Button.setTitle(questionData.choice3, for: UIControlState.normal)
        choice4Button.setTitle(questionData.choice4, for: UIControlState.normal)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func tapChoice1Button(_ sender: Any) {
        questionData.userAnswer = 1
        goNextQuestionWithAnimation()
    }
    @IBAction func tapChoice2Button(_ sender: Any) {
        questionData.userAnswer = 2
        goNextQuestionWithAnimation()
    }
    @IBAction func tapChoice3Button(_ sender: Any) {
        questionData.userAnswer = 3
        goNextQuestionWithAnimation()
    }
    @IBAction func tapChoice4Button(_ sender: Any) {
        questionData.userAnswer = 4
        goNextQuestionWithAnimation()
    }
    
    func goNextQuestionWithAnimation() {
        if questionData.isCorrect() {
            goNextQuestionWithCorrectAnimation()
        } else {
            goNextQuestionWithIncorrectAnimation()
        }
    }
    
    func goNextQuestionWithCorrectAnimation() {
        AudioServicesPlayAlertSound(1025)

        UIView.animate(withDuration: 2.0, animations: {
            self.correctImageView.alpha = 1.0
        }) { (Bool) in
            self.goNextQuestion()
        }
    }
    
    func goNextQuestionWithIncorrectAnimation() {
        AudioServicesPlayAlertSound(1006)

        UIView.animate(withDuration: 2.0, animations: {
            self.incorrectImageView.alpha = 1.0
        }) { (Bool) in
            self.goNextQuestion()
        }
    }
    
    func goNextQuestion() {
        guard let nextQuestionData = QuestionDataManager.sharedInstance.nextQuestion() else {
            if let resultViewController = storyboard?.instantiateViewController(withIdentifier: "result")  as? ResultViewController {
                present(resultViewController, animated: true, completion: nil)
            }
            return
        }
        
        if let nextQuestionViewController = storyboard?.instantiateViewController(withIdentifier: "question") as? QuestionViewController {
            nextQuestionViewController.questionData = nextQuestionData
            present(nextQuestionViewController, animated: true, completion: nil)
        }
    }
}
