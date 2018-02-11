//
//  StartViewController.swift
//  IOSMyQuiz
//
//  Created by Yuske Fukuyama on 2018/02/11.
//  Copyright © 2018 Yuske Fukuyama. All rights reserved.
//

import UIKit

class StartViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        QuestionDataManager.sharedInstance.loadQuestion()
        guard let nextViewController = segue.destination as? QuestionViewController else {
            return
        }
        guard let questionData = QuestionDataManager.sharedInstance.nextQuestion() else {
            return
        }
        nextViewController.questionData = questionData
    }

    @IBAction func goToTitle(_ segue: UIStoryboardSegue) {
    }
}
