//
//  QuestionDataManager.swift
//  IOSMyQuiz
//
//  Created by Yuske Fukuyama on 2018/02/11.
//  Copyright © 2018 Yuske Fukuyama. All rights reserved.
//

import Foundation

class QuestionData {
    var questionText: String
    var choice1: String
    var choice2: String
    var choice3: String
    var choice4: String
    var correctAnswer: Int
    var userAnswer: Int?
    var questionNumber: Int = 0
    
    init(questionSourceDataArray: [String]) {
        questionText = questionSourceDataArray[0]
        choice1 = questionSourceDataArray[1]
        choice2 = questionSourceDataArray[2]
        choice3 = questionSourceDataArray[3]
        choice4 = questionSourceDataArray[4]
        correctAnswer = Int(questionSourceDataArray[5])!
    }
    
    func isCorrect() -> Bool {
        if userAnswer == correctAnswer {
            return true
        } else {
            return false
        }
    }
}

class QuestionDataManager {
    // singleton manager object
    static let sharedInstance = QuestionDataManager() // static to always reference same obj in memory

    var questionDataArray = [QuestionData]()
    var upcomingQuestionIndex: Int = 0

    private init() {
        // because it's singleton
    }

    func loadQuestion() {
        questionDataArray.removeAll()
        upcomingQuestionIndex = 0
        
        guard let csvFilePath = Bundle.main.path(forResource: "questions", ofType: "csv") else {
            print("csv file does not exist")
            return
        }
        
        do {
            let csvStringData = try String(contentsOfFile: csvFilePath, encoding: String.Encoding.utf8)

            csvStringData.enumerateLines(invoking: { (line, stop) in
                let questionSourceDataArray = line.components(separatedBy: ",")
                let questionData = QuestionData(questionSourceDataArray: questionSourceDataArray)
                self.questionDataArray.append(questionData)
                questionData.questionNumber = self.questionDataArray.count
            })
        } catch let error {
            print("error occured while reading csv: \(error)")
            return
        }
    }

    // get next question or nil
    func nextQuestion() -> QuestionData? {
        if upcomingQuestionIndex < questionDataArray.count {
            let nextQuestion = questionDataArray[upcomingQuestionIndex]
            upcomingQuestionIndex += 1
            return nextQuestion
        } else {
            return nil
        }
    }
}
