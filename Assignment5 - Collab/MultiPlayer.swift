//
//  ViewController.swift
//  MultipeerExample
//
//  Created by Eyuphan Bulut on 4/5/17.
//  Copyright © 2017 Eyuphan Bulut. All rights reserved.
//

import UIKit
import MultipeerConnectivity

var mpc = MCPeerManager()

class Multiplayer: UIViewController, MCBrowserViewControllerDelegate, MCSessionDelegate {
    
    
    
    var session: MCSession!
    
    var peerID: MCPeerID!
    
    var browser: MCBrowserViewController!
    var assistant: MCAdvertiserAssistant!
    
    
    @IBOutlet weak var img1: UIImageView!
    @IBOutlet weak var img2: UIImageView!
    @IBOutlet weak var img3: UIImageView!
    @IBOutlet weak var img4: UIImageView!
    @IBOutlet weak var pid1: UILabel!
    @IBOutlet weak var pid2: UILabel!
    @IBOutlet weak var pid3: UILabel!
    @IBOutlet weak var pid4: UILabel!
    @IBOutlet weak var ans1: UILabel!
    @IBOutlet weak var ans2: UILabel!
    @IBOutlet weak var ans3: UILabel!
    @IBOutlet weak var ans4: UILabel!
    @IBOutlet weak var score1: UILabel!
    @IBOutlet weak var score2: UILabel!
    @IBOutlet weak var score3: UILabel!
    @IBOutlet weak var score4: UILabel!
    @IBOutlet weak var qheader: UILabel!
    @IBOutlet weak var qsentence: UILabel!
    @IBOutlet weak var choice1: UIButton!
    @IBOutlet weak var choice2: UIButton!
    @IBOutlet weak var choice3: UIButton!
    @IBOutlet weak var choice4: UIButton!
    @IBOutlet weak var countdown: UILabel!
    @IBOutlet weak var startover: UIButton!
    @IBOutlet weak var bubble1: UIImageView!
    @IBOutlet weak var bubble2: UIImageView!
    @IBOutlet weak var bubble3: UIImageView!
    @IBOutlet weak var bubble4: UIImageView!
    
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
    var numberOfPlayers : Int = 0
    let choices = ["A", "B", "C", "D"]
    var gameplayers = Array(repeating: (name: "", id: 0), count: 4)
    
    var myplayer = (name: "", score: 0, Ans: "")
    
    

    
    var quiz = quizProperties()
    
    
    func initialize() {
        
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(quizTimer), userInfo: nil, repeats: true)
        
        timeInSeconds = 0
        
        for i in 0 ..< tappedCount.count {
            tappedCount[i] = 0
        }
        /*options.forEach({
            $0.backgroundColor = defaultColor
            $0.isUserInteractionEnabled = true
        })*/
        
        choice1.backgroundColor = defaultColor
        choice1.isUserInteractionEnabled = true
        choice2.backgroundColor = defaultColor
        choice2.isUserInteractionEnabled = true
        choice3.backgroundColor = defaultColor
        choice3.isUserInteractionEnabled = true
        choice4.backgroundColor = defaultColor
        choice4.isUserInteractionEnabled = true
        
        for i in 0 ..< maxPlayers {
            if i+1 > numberOfPlayers {
                
                switch i {
                    
                case 0:
                    
                    img1.image = #imageLiteral(resourceName: "User-Unfilled")
                    img1.alpha = 0.02
                    score1.isEnabled = false
                    score1.alpha = 0.5
                    
                    bubble1.isHidden = true
                    ans1.isHidden = true
                    
                case 1:
                    
                    img2.image = #imageLiteral(resourceName: "User-Unfilled")
                    img2.alpha = 0.02
                    score2.isEnabled = false
                    score2.alpha = 0.5
                    
                    bubble2.isHidden = true
                    ans2.isHidden = true
                    
                case 2:
                    
                    img3.image = #imageLiteral(resourceName: "User-Unfilled")
                    img3.alpha = 0.02
                    score3.isEnabled = false
                    score3.alpha = 0.5
                    
                    bubble3.isHidden = true
                    ans3.isHidden = true
                    
                case 3:
                    
                    img4.image = #imageLiteral(resourceName: "User-Unfilled")
                    img4.alpha = 0.02
                    score4.isEnabled = false
                    score4.alpha = 0.5
                    
                    bubble4.isHidden = true
                    ans4.isHidden = true
                    
                default:
                    img2.image = #imageLiteral(resourceName: "User Filled-Cyan")
                    img2.alpha = 0.02
                    score2.isEnabled = false
                    score2.alpha = 0.5
                    
                    bubble2.isHidden = true
                    ans2.isHidden = true
                }
                
            }
                
            else {
                
                switch i {
                case 0:
                    img1.image = playerAssets[i]
                case 1:
                    img2.image = playerAssets[i]
                case 2:
                    img3.image = playerAssets[i]
                case 3:
                    img4.image = playerAssets[i]
                default:
                    img1.image = playerAssets[2]
                }
                
            }
            
            switch i {
                
            case 0:
                ans1.text = ""
                img1.contentMode = .scaleAspectFit
                score1.text = "\(scores[i])"
            case 1:
                ans2.text = ""
                img2.contentMode = .scaleAspectFit
                score2.text = "\(scores[i])"
            case 2:
                ans3.text = ""
                img3.contentMode = .scaleAspectFit
                score3.text = "\(scores[i])"
            case 3:
                ans4.text = ""
                img4.contentMode = .scaleAspectFit
                score4.text = "\(scores[i])"
            default:
                ans1.text = "?????"
                img1.contentMode = .scaleAspectFit
                score1.text = "\(scores[i])"
                
            }
            
        }
        
        qheader.text = "Question \(quiz.qIndex + 1)/\(quiz.qCount)"
        qsentence.text = quiz.questions[quiz.qIndex].questionPrompt
        countdown.text = String(COUNTDOWN_TIME)
        startover.isHidden = true
        
        for i in 0..<quiz.choices.count {
            
            switch i {
            case 0:
                choice1.setTitle(quiz.choices[i] + ") " + quiz.questions[quiz.qIndex].choices[quiz.choices[i]]! , for: .normal)
            case 1:
                choice2.setTitle(quiz.choices[i] + ") " + quiz.questions[quiz.qIndex].choices[quiz.choices[i]]! , for: .normal)

            case 2:
                choice3.setTitle(quiz.choices[i] + ") " + quiz.questions[quiz.qIndex].choices[quiz.choices[i]]! , for: .normal)

            case 3:
                choice4.setTitle(quiz.choices[i] + ") " + quiz.questions[quiz.qIndex].choices[quiz.choices[i]]! , for: .normal)

            default:
                choice1.setTitle(quiz.choices[i] + ")???? " + quiz.questions[quiz.qIndex].choices[quiz.choices[i]]! , for: .normal)
            }
            
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
        // Do any additional setup after loading the view, typically from a nib.
        
        
        self.peerID = MCPeerID(displayName: UIDevice.current.name)
       // self.session = MCSession(peer: peerID)
        self.browser = MCBrowserViewController(serviceType: "chat", session: session)
        self.assistant = MCAdvertiserAssistant(serviceType: "chat", discoveryInfo: nil, session: session)
        
        //assistant.start()
        session.delegate = self
        //browser.delegate = self
        
        choice1.layer.cornerRadius = 15
        choice1.layer.masksToBounds = true
        choice2.layer.cornerRadius = 15
        choice2.layer.masksToBounds = true
        choice3.layer.cornerRadius = 15
        choice3.layer.masksToBounds = true
        choice4.layer.cornerRadius = 15
        choice4.layer.masksToBounds = true
        
        //givePeerID()
        
        print("Players: \(numberOfPlayers)")
        
        myplayer.name = peerID.displayName
        
        print("Session count: \(session.connectedPeers.count)")

        
    }
    
    
    @IBAction func selectOption(_ sender: UIButton) {
        
        if (sender.tag == 1)
        {
            tappedCount[0] += 1
            
            choice1.isSelected = false
            choice2.isSelected = false
            choice3.isSelected = false
            choice4.isSelected = false
            
            switch tappedCount[0] {
            case 1:
                choice1.backgroundColor = selectColor
                choice2.backgroundColor = defaultColor
                choice3.backgroundColor = defaultColor
                choice4.backgroundColor = defaultColor
                
            case 2:
                
                shouldSubmit(1)
                
            default: break
            }

        }
        else if sender.tag == 2
        {
            tappedCount[1] += 1
            
            choice1.isSelected = false
            choice2.isSelected = false
            choice3.isSelected = false
            choice4.isSelected = false
            
            switch tappedCount[1] {
            case 1:
                choice2.backgroundColor = selectColor
                choice1.backgroundColor = defaultColor
                choice3.backgroundColor = defaultColor
                choice4.backgroundColor = defaultColor
                
            case 2:
                
                shouldSubmit(2)
                
            default: break
            }

        }
        else if sender.tag == 3
        {
            tappedCount[2] += 1
            
            choice1.isSelected = false
            choice2.isSelected = false
            choice3.isSelected = false
            choice4.isSelected = false
            
            switch tappedCount[2] {
            case 1:
                choice3.backgroundColor = selectColor
                choice2.backgroundColor = defaultColor
                choice1.backgroundColor = defaultColor
                choice4.backgroundColor = defaultColor
                
            case 2:
                
                shouldSubmit(3)
                
            default: break
            }

        }
        else if sender.tag == 4
        {
            tappedCount[3] += 1
            
            choice1.isSelected = false
            choice2.isSelected = false
            choice3.isSelected = false
            choice4.isSelected = false
            
            switch tappedCount[3] {
            case 1:
                choice4.backgroundColor = selectColor
                choice2.backgroundColor = defaultColor
                choice3.backgroundColor = defaultColor
                choice1.backgroundColor = defaultColor
                
            case 2:
                
                shouldSubmit(4)
                
            default: break
            }

        }
        else
        {
            print("Error")
        }
        
       
        
    }
    
    
    
    func timeUp(_ selectIndex : Int) {
        
        /* TO-DO: maybe add red text showing user choice if user runs out of time & does not submit (this is assuming his submission would not? get recorded
         let letter = options[selectIndex].currentTitle!.characters.first!
         
         playerVisualChoice[0].text = String(letter)
         playerVisualChoice[0].textColor = UIColor.red
         */
        
        ans1.text = ""
        ans2.text = ""
        ans3.text = ""
        ans4.text = ""
        countdown.text = "Time's up!"
        revealAnswer()
    }
    
    func shouldSubmit(_ selectIndex : Int) {
        
        let letter = choices[selectIndex - 1]
        
        timer.invalidate()
        
        
        switch selectIndex
        {
        case 1:
            choice1.backgroundColor = submitColor
        case 2:
            choice2.backgroundColor = submitColor
        case 3:
            choice3.backgroundColor = submitColor
        case 4:
            choice4.backgroundColor = submitColor
        default:
            print("Error in submitted answer")
        }
        
        
        // NOTE: this will only set player 1's speech overhead.
        // Need to loop through all players inside this func
        ans1.text = String(letter)
        myplayer.Ans = ans1.text!
        
        choice1.isUserInteractionEnabled = false
        choice2.isUserInteractionEnabled = false
        choice3.isUserInteractionEnabled = false
        choice4.isUserInteractionEnabled = false
        
        if (String(letter) == quiz.questions[quiz.qIndex].answer) {
            countdown.text = "Nice Job!"
            
            // Determine which player was correct ?
            scores[0] += 1
            myplayer.score = scores[0]
            
            //for i in 0 ..< maxPlayers {
                //score1.text = "\(scores[1])"
                score1.text = "\(scores[0])"
            //}
        }
        else {
            countdown.text = "Incorrect!"
        }
        
        let dataToSend =  NSKeyedArchiver.archivedData(withRootObject: myplayer)
        
        do{
            try session.send(dataToSend, toPeers: session.connectedPeers, with: .unreliable)
        }
        catch let err {
            print("Error in sending data \(err)")
        }

        
        revealAnswer()
    }

    
    @IBAction func restartQuiz(_ sender: Any) {
        
        startover.isHidden = true
        quiz.number += 1
        
        for i in 0 ..< maxPlayers {
            scores[i] = 0
        }
        
        DispatchQueue.main.async(){
            self.searchQuizData(quizNumber: self.quiz.number)
        }
    }
    
    
    func revealAnswer()
    {
        // perhaps setup as a timer instead ?
        
        switch (quiz.choices.index(of: quiz.questions[quiz.qIndex].answer)!) {
        case 0:
            choice1.backgroundColor = revealColor
        case 1:
            choice2.backgroundColor = revealColor
        case 2:
            choice3.backgroundColor = revealColor
        case 3:
            choice4.backgroundColor = revealColor
        default:
            choice1.backgroundColor = selectColor
        }
        
        
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
                        self.countdown.text = "You tied !"
                    }
                    else {
                        self.countdown.text = "You WON !"
                    }
                }
                else {
                    self.countdown.text = "You lost."
                }
                
                self.startover.isHidden = false
                
            }
            else {
                self.initialize()
            }
        }
        
    }
    
   

    

    
    func quizTimer() {
        
        timeInSeconds += 1
        countdown.text = String(COUNTDOWN_TIME - timeInSeconds)
        
        
        if timeInSeconds == COUNTDOWN_TIME {
            timer.invalidate()
            timeUp(0)
        }
    }
    

    
    
    
    
    @IBAction func connect(_ sender: UIButton) {
        
        present(browser, animated: true, completion: nil)
        
    }
    
    
    //**********************************************************
    // required functions for MCBrowserViewControllerDelegate
    func browserViewControllerDidFinish(_ browserViewController: MCBrowserViewController) {
        // Called when the browser view controller is dismissed
        dismiss(animated: true, completion: nil)
    }
    
    func browserViewControllerWasCancelled(_ browserViewController: MCBrowserViewController) {
        // Called when the browser view controller is cancelled
        dismiss(animated: true, completion: nil)
    }
    //**********************************************************
    
    
    
    
    //**********************************************************
    // required functions for MCSessionDelegate
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL, withError error: Error?) {
        
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        
        // this needs to be run on the main thread
        DispatchQueue.main.async(execute: {
            
            
            
           // let receivedPlayer = NSKeyedUnarchiver.unarchiveObject(with: data) as? (name: String, score: Int, ans: String)
            
            
             /*switch receivedPlayer?.name
             {
                case gameplayers[1].name:
                    self.scores[1] = (receivedPlayer?.score)!
                    break
                case gameplayers[2].name:
                    
                    self.scores[2] = (receivedPlayer?.score)!
                    break

                
                case gameplayers[3].name:
                
                    self.scores[3] = (receivedPlayer?.score)!
                    break

             }*/
            
            
        })
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        
    }
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        
        // Called when a connected peer changes state (for example, goes offline)
        
        switch state {
        case MCSessionState.connected:
            print("Connected: \(peerID.displayName)")
            
        case MCSessionState.connecting:
            print("Connecting: \(peerID.displayName)")
            
        case MCSessionState.notConnected:
            print("Not Connected: \(peerID.displayName)")
        }
        
    }
    //**********************************************************
    
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
        
        qheader.text = "Question \(quiz.qIndex + 1)/\(quiz.qCount)"
        qsentence.text = quiz.questions[quiz.qIndex].questionPrompt
        
        let multipleChoices = ["A", "B", "C", "D"]
        for i in 0..<multipleChoices.count {
            
            switch i {
            case 0:
                choice1.setTitle(multipleChoices[i] + ") " + quiz.questions[quiz.qIndex].choices[multipleChoices[i]]! , for: .normal)
            case 1:
                choice2.setTitle(multipleChoices[i] + ") " + quiz.questions[quiz.qIndex].choices[multipleChoices[i]]! , for: .normal)
            case 2:
                choice3.setTitle(multipleChoices[i] + ") " + quiz.questions[quiz.qIndex].choices[multipleChoices[i]]! , for: .normal)
            case 3:
                choice4.setTitle(multipleChoices[i] + ") " + quiz.questions[quiz.qIndex].choices[multipleChoices[i]]! , for: .normal)
            default:
                choice1.setTitle(multipleChoices[i] + ")???? " + quiz.questions[quiz.qIndex].choices[multipleChoices[i]]! , for: .normal)
            }
            
            
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


    
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
}

