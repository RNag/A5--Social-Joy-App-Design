//
//  QuizScreen.swift
//  Assignment5 - Collab
//
//  Created by Ritvik on 4/22/17.
//  Copyright © 2017 Ritvik Nag. All rights reserved.
//

import UIKit


struct QuizQuestion {
    
    enum MultipleChoice: Int {
        case A = 0, B, C, D
    }
    
    let numIndex: Int
    let questionPrompt: String
    let answer : String
    let choices: [String: String]
    
}

extension QuizQuestion {
    init?(json: [String: Any]) {
        guard let number = json["number"] as? Int,
            let prompt = json["questionSentence"] as? String,
            let options = json["options"] as? [String : Any],
            let correctOption = json["correctOption"] as? String
        else {
            return nil
        }
        
        var choices : [String : String] = [:]
        for letterOption in options {
            guard let i = quizProperties().choices.index(of: letterOption.0) else {
                return nil
            }
            
            choices.updateValue(letterOption.value as! String, forKey: quizProperties().choices[i])
        }
        
        self.numIndex = number
        self.questionPrompt = prompt
        self.answer = correctOption
        self.choices = choices
    }
}

struct quizProperties {
    
    let choices = ["A", "B", "C", "D"]
    
    var questions = [QuizQuestion]()
    var qCount : Int = 0
    var qIndex : Int = 0
    var topic : String = "Topic"
    var number = 0
}

class QuizScreen: UIViewController {

    @IBOutlet var options: [UIButton]!
    @IBOutlet var playerIcons: [UIImageView]!
    @IBOutlet var playerScores: [UILabel]!
    @IBOutlet var playerSpeechBubble: [UIImageView]!
    @IBOutlet var playerVisualChoice : [UILabel]!
    
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var sentenceLabel : UILabel!
    @IBOutlet weak var cDownLabel : UILabel!
    @IBOutlet weak var startOverButton: UIButton!
    
    let playerAssets : [UIImage] = [ #imageLiteral(resourceName: "User Filled-Blue2"), #imageLiteral(resourceName: "User Filled-Violet"), #imageLiteral(resourceName: "User Filled-Green"), #imageLiteral(resourceName: "User Filled-Orange")  ]
    
    let defaultColor = #colorLiteral(red: 0.7233663201, green: 0.7233663201, blue: 0.7233663201, alpha: 1)
    let selectColor = #colorLiteral(red: 0.4745098054, green: 0.8392156959, blue: 0.9764705896, alpha: 1)
    let submitColor = UIColor.cyan
    let revealColor = UIColor.green
    let COUNTDOWN_TIME = 20
    let transitionTime = 3
    let maxPlayers = 4
    
    var timer : Timer!
    var timeInSeconds : Int = 0
    var scores = Array(repeating: 0, count: 4)
    var tappedCount = Array(repeating: 0, count: 4)
    var numberOfPlayers = 1

    var quiz = quizProperties()

    
    func initialize() {

        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(quizTimer), userInfo: nil, repeats: true)
        
        timeInSeconds = 0

        for i in 0 ..< tappedCount.count {
            tappedCount[i] = 0
        }
        options.forEach({
            $0.backgroundColor = defaultColor
            $0.isUserInteractionEnabled = true
        })
        
        for i in 0 ..< maxPlayers {
            if i+1 > numberOfPlayers {
                playerIcons[i].image = #imageLiteral(resourceName: "User-Unfilled")
                playerIcons[i].alpha = 0.02
                playerScores[i].isEnabled = false
                playerScores[i].alpha = 0.5
                
                playerSpeechBubble[i].isHidden = true
                playerVisualChoice[i].isHidden = true
            }
            
            else {
                playerIcons[i].image = playerAssets[i]
            }
            playerVisualChoice[i].text = ""
            playerIcons[i].contentMode = .scaleAspectFit
            playerScores[i].text = "\(scores[i])"
        }
        
        headerLabel.text = "Question \(quiz.qIndex + 1)/\(quiz.qCount)"
        sentenceLabel.text = quiz.questions[quiz.qIndex].questionPrompt
        cDownLabel.text = String(COUNTDOWN_TIME)
        startOverButton.isHidden = true
        
        for (i, option) in options.enumerated() {
            
            option.setTitle(quiz.choices[i] + ") " + quiz.questions[quiz.qIndex].choices[quiz.choices[i]]! , for: .normal)
        }
        
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        quiz.number = 1
        quiz.qIndex = 0

        //  Load JSON data before view is shown
        searchQuizData(quizNumber: quiz.number)
    }
    
    
    override func viewDidLoad() {
         super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        for option in options {
            option.layer.cornerRadius = 15
            option.layer.masksToBounds =  true
        }
    }
    
    @IBAction func selectOption(_ sender: UIButton){

        if let i = options.index(of: sender) {
            tappedCount[i] += 1
            
            options.forEach({$0.isSelected = false})
            
            switch tappedCount[i] {
            case 1:
                options[i].backgroundColor = selectColor
                
                for c in 0 ..< tappedCount.count {
                    if c != i {
                        tappedCount[c] = 0
                        options[c].backgroundColor = defaultColor
                    }
                }
                
            case 2:
                
                shouldSubmit(i)

            default: break
            }
        }
    }
    
    func timeUp(_ selectIndex : Int) {
        
        /* TO-DO: maybe add red text showing user choice if user runs out of time & does not submit (this is assuming his submission would not? get recorded
        let letter = options[selectIndex].currentTitle!.characters.first!
        
        playerVisualChoice[0].text = String(letter)
        playerVisualChoice[0].textColor = UIColor.red
        */
        
        playerVisualChoice[0].text = ""
        cDownLabel.text = "Time's up!"
        revealAnswer()
    }
    
    
    func shouldSubmit(_ selectIndex : Int) {
        
        let letter = options[selectIndex].currentTitle!.characters.first!
        
        timer.invalidate()
        
        options[selectIndex].backgroundColor = submitColor
        
        
        // NOTE: this will only set player 1's speech overhead.
        // Need to loop through all players inside this func
        playerVisualChoice[0].text = String(letter)

        for option in options {
            option.isUserInteractionEnabled = false
        }
        
        if (String(letter) == quiz.questions[quiz.qIndex].answer) {
            cDownLabel.text = "Nice Job!"
            
            // Determine which player was correct ?
            scores[0] += 1
            
            for i in 0 ..< maxPlayers {
                playerScores[i].text = "\(scores[i])"
            }
        }
        else {
            cDownLabel.text = "Incorrect!"
        }
        
        revealAnswer()
    }
    
    func revealAnswer() {
        // perhaps setup as a timer instead ?
        
   
        options[quiz.choices.index(of: quiz.questions[quiz.qIndex].answer)!].backgroundColor = revealColor
        
        let when = DispatchTime.now() + 3
        
        quiz.qIndex += 1
        
        DispatchQueue.main.asyncAfter(deadline: when) {
            // Your code with delay
            
            if self.quiz.qIndex == self.quiz.qCount {   // End quiz
                self.quiz.qIndex = 0
                
                let playerScore = self.scores[0]  // Assume player one
                //  Determine the winner (if there is any)
                self.scores.sort(by: {$0 > $1})
                
                if playerScore == self.scores.first! {  //Satisfies predicate for a win-draw scenario
                    if self.scores[0] == self.scores[1] {
                        self.cDownLabel.text = "You tied !"
                    }
                    else {
                        self.cDownLabel.text = "You WON !"
                    }
                }
                else {
                    self.cDownLabel.text = "You lost."
                }
                
                self.startOverButton.isHidden = false
                
            }
            else {
                self.initialize()
            }
        }
        
    }
    
    
    func quizTimer() {
        
        timeInSeconds += 1
        cDownLabel.text = String(COUNTDOWN_TIME - timeInSeconds)
        
        
        if timeInSeconds == COUNTDOWN_TIME {
            timer.invalidate()
            timeUp(0)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    @IBAction func restartQuiz(_ sender: UIButton) {
        startOverButton.isHidden = true
        quiz.number += 1
        
        // Resets score for all players
        for i in 0 ..< maxPlayers {
            scores[i] = 0
        }
        
        DispatchQueue.main.async(){
            self.searchQuizData(quizNumber: self.quiz.number)
        }
        
    }

    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
    }
    func searchQuizData(quizNumber: Int) {

        let quizUrl = URL(string: "http://www.people.vcu.edu/~ebulut/jsonFiles/quiz\(quizNumber).json")!
        let request = URLRequest(url: quizUrl)
        let session = URLSession.shared
        let STATUS_OK = 200
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        
        let task = session.dataTask(with: request) { (data, response, error) in
            
            let httpResponse = response as? HTTPURLResponse
            let statusCode = httpResponse?.statusCode
            
            
            if let Error = error {
                print("An error occurred: \(Error)")
                return
            }
                
            else if statusCode! != STATUS_OK { // Status code != OK can happen for any number of reasons, chief among them is the 404 (Not Found) error, in which we rollback to Quiz 1 (default)
                DispatchQueue.main.async {
                    self.quiz.number = 1
                    self.searchQuizData(quizNumber: self.quiz.number)
                }
                return
            }
            
           
            do {
                let jsonResult = try JSONSerialization.jsonObject(with: data!, options: []) as! [String: Any]
                
                DispatchQueue.main.async() {
                    self.parseQuizData(jsonResult)
                    self.setUp()

                    return
                }
            }
            
            catch let err {
                print(err.localizedDescription)
            }
            // Close the dataTask block, and call resume() in order to make it run immediately
        }
        
        task.resume()
    }
    
    func setUp(){
        initialize()
        quiz.qIndex = 0
        
        headerLabel.text = "Question \(quiz.qIndex + 1)/\(quiz.qCount)"
        sentenceLabel.text = quiz.questions[quiz.qIndex].questionPrompt
        
        let multipleChoices = ["A", "B", "C", "D"]
        for (i, option) in options.enumerated() {
            
            option.setTitle(multipleChoices[i] + ") " + quiz.questions[quiz.qIndex].choices[multipleChoices[i]]! , for: .normal)
        }
        
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
    
    
    func parseQuizData(_ quizData: [String: Any]) {
        // Make sure the results are in the expected format of [String: Any]
        guard let quizQuestions = quizData["questions"] as? [[String: Any]],
              let questionsCount = quizData["numberOfQuestions"] as? Int,
              let quizTopic = quizData["topic"] as? String
        else {
            print("Could not process search results...")
            return
        }
        
        
        // Create a temporary place to add the new list of app details to
        var questions = [QuizQuestion]()
        
        // Loop through all the results...
        for question in quizQuestions {
            questions.append(QuizQuestion(json: question)!)
        }
        
        quiz.questions = questions
        quiz.qCount = questionsCount
        quiz.topic = quizTopic
        
    }

}
