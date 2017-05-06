//
//  ViewController.swift
//  MultipeerExample
//
//  Created by Eyuphan Bulut on 4/5/17.
//  Copyright © 2017 Eyuphan Bulut. All rights reserved.
//

import UIKit
import CoreMotion
import MultipeerConnectivity

class Multiplayer: UIViewController, MCSessionDelegate {
    
    var session: MCSession!
    
    @IBOutlet var options: [UIButton]!
    @IBOutlet var playerIcons: [UIImageView]!
    @IBOutlet var playerScores: [UILabel]!
    @IBOutlet var playerSpeechBubble: [UIImageView]!
    @IBOutlet var playerVisualChoice : [UILabel]!
    
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var sentenceLabel : UILabel!
    @IBOutlet weak var cDownLabel : UILabel!
    @IBOutlet weak var statusUpdateLabel: UILabel!
    @IBOutlet weak var startOverButton: UIButton!
    
    //  Core Motion Manager
    var motionManager: CMMotionManager!
    
    let playerAssets : [UIImage] = [ #imageLiteral(resourceName: "User Filled-Blue2"), #imageLiteral(resourceName: "User Filled-Violet"), #imageLiteral(resourceName: "User Filled-Green"), #imageLiteral(resourceName: "User Filled-Orange")  ]
    
    let defaultColor = #colorLiteral(red: 0.7233663201, green: 0.7233663201, blue: 0.7233663201, alpha: 1)
    let selectColor = #colorLiteral(red: 0.4745098054, green: 0.8392156959, blue: 0.9764705896, alpha: 1)
    let submitColor = UIColor.cyan
    let revealColor = UIColor.green
    let COUNTDOWN_TIME = 20
    let transitionTime = 3
    let maxPlayers = 4
    static let numberOfChoices = 4
    
    var timer : Timer!
    var timeInSeconds : Int = 0
    var scores = Array(repeating: 0, count: 4)
    
    
    var tappedCount = Array(repeating: 0, count: numberOfChoices)
    var numberOfPlayers = 0
    
    var numberOfLockedInAnswers = 0
    var hasLocalPeerSubmitted = false
    
    var readyUpCount = 0
    
    let choices = ["A", "B", "C", "D"]
    
    var players:[(peerId: MCPeerID, nickname: String)] = []

    var selectionIndex = -1
    
    var initialAttitude : CMAttitude!
    var shakeCooldown = false
    
    
    var quiz = quizProperties()
    
    func assignPeerIDs() -> ()
    {
        //  The number of peers is an underestimated count (does not include self peer Id), so adjust accordingly
        
        players.append( (peerId: session.myPeerID, nickname: "Me") )
        
        print("Nickname: \(players.first!.nickname), DisplayName: \(players.first!.peerId.displayName)")
        
        for i in 0 ..< session.connectedPeers.count
        {
            players.append((peerId: session.connectedPeers[i], nickname: "P\(i+1)"))
            print("Nickname: \(players.last!.nickname), DisplayName: \(players.last!.peerId.displayName)")
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
        //  End Core Motion data gathering
        UIDevice.current.endGeneratingDeviceOrientationNotifications()
        
        let msg : [String : Any] = ["dismissPeer" : hasLocalPeerSubmitted]
        let dataToSend =  NSKeyedArchiver.archivedData(withRootObject: msg)
        let myPeers = players.dropFirst().map({$0.peerId})
        
        do {
            try session.send(dataToSend, toPeers: myPeers, with: .unreliable)
        }
                
        catch let err {
            print("There was a data transmission error in: SENDING /nError code: \(err)")
        }
        
        //session.disconnect()
        if timer != nil {   timer.invalidate()  }
        print("You quit the session.")
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super .viewDidDisappear(animated)
        
        self.motionManager.stopDeviceMotionUpdates()
        session.disconnect()
    }
    
    func initialize() {
        
        timeInSeconds = 0
        selectionIndex = -1
        numberOfPlayers = players.count
        numberOfLockedInAnswers = 0
        hasLocalPeerSubmitted = false
        readyUpCount += 1
        
        
        
        print("INIT (RC: \(readyUpCount))")

        for i in 0 ..< Multiplayer.numberOfChoices {
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
            playerVisualChoice[i].text = "..."
            playerIcons[i].contentMode = .scaleAspectFit
            playerScores[i].text = "\(scores[i])"
        }
        
        headerLabel.text = "Question \(quiz.qIndex + 1)/\(quiz.qCount)"
        sentenceLabel.text = quiz.questions[quiz.qIndex].questionPrompt
        cDownLabel.text = String(COUNTDOWN_TIME)
        statusUpdateLabel.isHidden = true
        startOverButton.isHidden = true
        
        for (i, option) in options.enumerated() {
            
            option.setTitle(quiz.choices[i] + ") " + quiz.questions[quiz.qIndex].choices[quiz.choices[i]]! , for: .normal)
        }
        
        
        let msg : [String : Any] = ["readyCount" : 1]
        let dataToSend =  NSKeyedArchiver.archivedData(withRootObject: msg)
        let myPeers = players.dropFirst().map({$0.peerId})
        
        do {
            print("SENDING READY ...")
            try session.send(dataToSend, toPeers: myPeers, with: .unreliable)
        }
            
        catch let err {
            print("There was a data transmission error in: SENDING /nError code: \(err)")
        }
        
        syncAllPlayers()
        
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        session.delegate = self
        
        //  Assign peer IDs to each player in game
        assignPeerIDs()
        
        quiz.number = 1
        quiz.qIndex = 0
        
        //  Load JSON data before view is shown
        searchQuizData(quizNumber: quiz.number)
        
        // Prepare to record CoreMotion data
        self.motionManager.deviceMotionUpdateInterval = 1.0/60.0
        self.motionManager.startDeviceMotionUpdates(using: .xArbitraryCorrectedZVertical)
        
        Timer.scheduledTimer(timeInterval: 0.02, target: self, selector: #selector(updateDeviceMotion), userInfo: nil, repeats: true)
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view, typically from a nib.
        
        for option in options {
            option.layer.cornerRadius = 15
            option.layer.masksToBounds =  true
            option.titleLabel?.numberOfLines = 0
            option.titleLabel?.lineBreakMode = .byWordWrapping
        }
        // Setup the core motion manager upon view load
        self.motionManager = CMMotionManager()
        
        if let data = self.motionManager.deviceMotion {
            initialAttitude = data.attitude  // initial attitude
        }
    }
    
    @IBAction func selectOption(_ sender: UIButton){
        
        if let i = options.index(of: sender) {
            tappedCount[i] += 1
            selectionIndex = i
            
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
        let defaultLetter = "X"
        
        /* TO-DO: maybe add red text showing user choice if user runs out of time & does not submit (this is assuming his submission would not? get recorded
         
         let letter = options[selectIndex].currentTitle!.characters.first!
         playerVisualChoice[0].text = String(letter)
         playerVisualChoice[0].textColor = UIColor.red
         */
        
        playerVisualChoice[0].text = defaultLetter
        cDownLabel.text = "Time's up!"
        for option in options {
            option.isUserInteractionEnabled = false
        }
        UIApplication.shared.isNetworkActivityIndicatorVisible = false

        revealAnswer()

        //  On successful submission, share the result with all players. In case of TIME IS UP: force a user submission, since user did not make a choice
        
        numberOfLockedInAnswers += 1
        hasLocalPeerSubmitted = true
        
        var msg : [String : Any] = [:]
        msg["peerChoice"] = defaultLetter
        msg["isCorrect"] = false
        
        let dataToSend =  NSKeyedArchiver.archivedData(withRootObject: msg)
        let myPeers = players.dropFirst().map({$0.peerId})
        
        do {
            print("Trying to send choice (Time's Up) ...")
            try session.send(dataToSend, toPeers: myPeers, with: .unreliable)
        }
        catch let err {
            print("There was a data transmission error in: SENDING /nError code: \(err)")
        }
        
        
        if numberOfLockedInAnswers >= numberOfPlayers {
            print("Going to Next (Time Up For All)")
            goNext()
        }
    }
    
    
    
    func shouldSubmit(_ selectIndex : Int) {
        
        let letter = options[selectIndex].currentTitle!.characters.first!
        
        timer.invalidate()
        
        options[selectIndex].backgroundColor = submitColor
        
        numberOfLockedInAnswers += 1
        hasLocalPeerSubmitted = true
        selectionIndex = -1
        
        let playersUndecided = numberOfPlayers - numberOfLockedInAnswers
        
        self.statusUpdateLabel.text = "Waiting on \(playersUndecided) more players ..."
        self.statusUpdateLabel.isHidden = false
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        //  On successful submission, share the result with all players
        var msg : [String : Any] = [:]
        msg["peerChoice"] = String(letter)
        msg["isCorrect"] = (String(letter) == quiz.questions[quiz.qIndex].answer)
        
        let dataToSend =  NSKeyedArchiver.archivedData(withRootObject: msg)
        let myPeers = players.dropFirst().map({$0.peerId})

        do {
            print("Trying to send choice (Submit) ...")
            try session.send(dataToSend, toPeers: myPeers, with: .unreliable)
        }
            
        catch let err {
            print("There was a data transmission error in: SENDING /nError code: \(err)")
        }
        

        
        // NOTE: this will only set player 1's speech overhead.
        // Need to loop through all players inside this func
        playerVisualChoice[0].text = String(letter)
        
        for option in options {
            option.isUserInteractionEnabled = false
        }
        
        if (String(letter) == quiz.questions[quiz.qIndex].answer) {
            cDownLabel.text = "Nice Job!"

            scores[0] += 1
            
        }
        else {
            cDownLabel.text = "Incorrect!"
        }
        
        
        revealAnswer()
        
        if numberOfLockedInAnswers >= numberOfPlayers {
            print("Going to Next (You Were Last Needed)")
            goNext()
        }
    }
    
    func revealAnswer() {
        // perhaps setup as a timer instead ?
        
        
        options[quiz.choices.index(of: quiz.questions[quiz.qIndex].answer)!].backgroundColor = revealColor
        
        
    }
    
    
    func goNext() {
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
        statusUpdateLabel.isHidden = true
        
        //  Update player scores only when all choices have been recorded
        for i in 0 ..< playerScores.count {
            playerScores[i].text = "\(scores[i])"
        }
        
        for player in players {
            if player.nickname == "Disconnected" {
                //  additional clean-up here
                players.removeAll()
                assignPeerIDs()
                numberOfPlayers = self.players.count
            }
        }
        
        
        quiz.qIndex += 1
        readyUpCount = 0
        
        hasLocalPeerSubmitted = false   // This is only needed so it does not conflict with actions to take when a peer leaves session
        
        _ = Timer.scheduledTimer(timeInterval: 3, target: self, selector: #selector(loadNextQuestion), userInfo: nil, repeats: false)
        
    }
    
    
    func quizTimer() {
        
        shakeCooldown = shakeCooldown ? false : shakeCooldown
        
        timeInSeconds += 1
        cDownLabel.text = String(COUNTDOWN_TIME - timeInSeconds)
        
        if timeInSeconds == COUNTDOWN_TIME {
            print("\(timeInSeconds) - \(COUNTDOWN_TIME)")
            timer.invalidate()
            timeUp(0)
        }
    }
    
    func loadNextQuestion(_ tTimer : Timer) {
        
        tTimer.invalidate()
        print("Next question loaded.")
        
        if quiz.qIndex == quiz.qCount {   // End of quiz number
            
            quiz.qIndex = 0               // Start from 1st question of new quiz
            
            let playerOneScore = scores[0]
            //  Determine the winner (if there is any)
            scores.sort(by: {$0 > $1})
            
            if playerOneScore == scores.first! {  //Satisfies predicate for a win-draw scenario
                if playerOneScore == scores[1] {
                    cDownLabel.text = "You tied !"
                }
                else {
                    cDownLabel.text = "You WON !"
                }
            }
            else {
                cDownLabel.text = "You lost."
            }
            
            startOverButton.isHidden = false
        }
            
        else {
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
            initialize()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    @IBAction func restartQuiz(_ sender: UIButton) {

        //  prepare for delayed response(s)
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        startOverButton.isHidden = true
        
        //  send forwarded request/action to all connected peers
        var msg = [String : Any]()
        msg["shouldRestart"] = true
        
        let dataToSend =  NSKeyedArchiver.archivedData(withRootObject: msg)
        let myPeers = self.players.dropFirst().map({$0.peerId})
        
        do {
            print("Restarting ...")
            try session.send(dataToSend, toPeers: myPeers, with: .unreliable)
        }
            
        catch let err {
            print("There was a data transmission error in: SENDING /nError code: \(err)")
        }
        
        
        //  perform actions for self - load next quiz
        quiz.number += 1
        
        // Resets own -copy- of scores for all players
        for i in 0 ..< maxPlayers {
            scores[i] = 0
        }
        
        DispatchQueue.main.async(){
            self.searchQuizData(quizNumber: self.quiz.number)
        }
        
    }
    
    func syncAllPlayers() {
        //  If all players are readied up, start the timer for everyone at the SAME time!
        
        if readyUpCount >= numberOfPlayers {
            readyUpCount = 0
            
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            
            print("READY UP CHECK - DONE")
            
            // start timer
            if timer != nil { timer.invalidate() }
            
            self.timeInSeconds = 0
            self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.quizTimer), userInfo: nil, repeats: true)
        }
    }
    
    //**********************************************************
    // required functions for MCSessionDelegate
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL, withError error: Error?) {
        
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer sender: MCPeerID) {
        

        // this needs to be run on the main thread
        DispatchQueue.main.async(execute: {
            guard
                let receivedDict = NSKeyedUnarchiver.unarchiveObject(with: data) as? [String : Any],
                let senderIndex = self.players.index(where: {$0.peerId == sender})
                
            else {
                print("There was a data transmission error in: RECEIVING")
                return
            }
            
            print("Trying to receive... Main Thread")
            
            //  Ready up - automatically handled
            if  let rc = receivedDict["readyCount"] {
                self.readyUpCount += (rc as! Int)
                
                
                print("READY UP CHECK: \(self.readyUpCount)/\(self.numberOfPlayers)")
                
                

                
                //BROADCAST
                let msg : [String : Any] = ["Broadcast" : [self.readyUpCount, self.numberOfPlayers]]
                
                
                let dataToSend =  NSKeyedArchiver.archivedData(withRootObject: msg)
                let myPeers = self.players.dropFirst().map({$0.peerId})
                
                do {
                    print("Broadcasting ready status ...")
                    try session.send(dataToSend, toPeers: myPeers, with: .unreliable)
                }
                
                catch let err {
                    print("There was a data transmission error in: SENDING /nError code: \(err)")
                }
                
                self.syncAllPlayers()
                
                
            }
            
            if let bc = receivedDict["Broadcast"] {
                let cast = bc as! [Int]
                let playerTag = self.players.first(where: {$0.peerId == sender})!.nickname
                
                //  Use for debugging purposes
                print("New Broadcast from \(playerTag): Readied \(cast[0])/\(cast[1]) needed")
            }
            
            
            //  DISMISS PEER    -   Player has prematurely left the game
            if  let dPC = receivedDict["dismissPeer"] {
                if (dPC as! Bool) {
                    self.numberOfLockedInAnswers -= 1
                }
                
                print("Received dismiss")
                
                let p = self.players.index(where: {$0.peerId == sender})!
                
                // Temporarily add empty placeholder for leaving player (TB finalized on round end)
                self.players[p].nickname = "Disconnected"
                
                self.playerIcons[p].image = #imageLiteral(resourceName: "User-Unfilled")
                self.playerIcons[p].alpha = 0.02
                self.playerScores[p].isEnabled = false
                self.playerScores[p].alpha = 0.5
                self.playerSpeechBubble[p].isHidden = true
                self.playerVisualChoice[p].isHidden = true
                self.playerScores[p].text = "Left"
                
                self.scores.remove(at: p)
                self.scores.append(0)

                let playersUndecided = self.numberOfPlayers - self.numberOfLockedInAnswers
                self.statusUpdateLabel.text = "Waiting on \(playersUndecided) more players ..."
                
                if self.numberOfPlayers < 2 {
                    print("Less than 2 players.")
                    session.disconnect()
                    
                    self.navigationController!.popToRootViewController(animated: true)
                }
                
                if  (self.numberOfLockedInAnswers >= self.numberOfPlayers) {
                    print("Going to Next (received from last needed)")
                    self.goNext()
                }
            }
    
            
            
            
            if  let choice = receivedDict["peerChoice"],
                let isCorrect = receivedDict["isCorrect"]
            {

                self.playerVisualChoice[senderIndex].text = choice as? String
                self.scores[senderIndex] += isCorrect as! Bool ? 1 : 0
                self.numberOfLockedInAnswers += 1

                print("Received player choice (\(choice)) - Submitted \(self.numberOfLockedInAnswers) ")
 
                
                let playersUndecided = self.numberOfPlayers - self.numberOfLockedInAnswers
                self.statusUpdateLabel.text = "Waiting on \(playersUndecided) more players ..."
                if  (self.numberOfLockedInAnswers >= self.numberOfPlayers) {
                        print("Going to Next (received from last needed)")
                        self.goNext()
                }
                
            }
            
            if let shouldRestart = receivedDict["shouldRestart"] {
                if (shouldRestart as! Bool) {
                    //  prepare for delayed response(s)
                    UIApplication.shared.isNetworkActivityIndicatorVisible = true
                    self.startOverButton.isHidden = true
                    
                    //  perform actions for self - load next quiz
                    self.quiz.number += 1
                
                    // Resets own -copy- of scores for all players
                    for i in 0 ..< self.maxPlayers {
                        self.scores[i] = 0
                    }
                
                    //DispatchQueue.main.async(){
                    self.searchQuizData(quizNumber: self.quiz.number)
                    //}
        
                }
            }
        })
        
    }
    
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        
    }
    
    
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        switch state {
        case MCSessionState.connected:
            print("Connected: \(peerID.displayName)")
            
        case MCSessionState.connecting:
            print("Connecting: \(peerID.displayName)")
            
        case MCSessionState.notConnected:
            print("Player disconnected.")
//            print("Not Connected: \(exitingPlayer.nickname)")
            
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
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        initialize()
        quiz.qIndex = 0
        
        headerLabel.text = "Question \(quiz.qIndex + 1)/\(quiz.qCount)"
        sentenceLabel.text = quiz.questions[quiz.qIndex].questionPrompt
        
        let multipleChoices = ["A", "B", "C", "D"]
        for (i, option) in options.enumerated() {
            
            option.setTitle(multipleChoices[i] + ") " + quiz.questions[quiz.qIndex].choices[multipleChoices[i]]! , for: .normal)
        }
        
        print("setup() ran successfully, final end RC: \(readyUpCount)")
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
    
    
    /** CORE    MOTION */
    

    override func motionBegan(_ motion: UIEventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            makeRandomChoice()
        }
    }
    
    func switchSelection(_ directionLR: Bool){
        
        var nextSelection = -1
        
        if !hasLocalPeerSubmitted {
            switch(selectionIndex){
            case 0:
                nextSelection = directionLR ? 1 : 2
            case 1:
                nextSelection = directionLR ? 0 : 3
            case 2:
                nextSelection = directionLR ? 3 : 0
            case 3:
                nextSelection = directionLR ? 2 : 1
            default:
                break
            }
            if nextSelection > -1 {
                selectOption(options[nextSelection])
            }
            
        }
        
    }
    
    
    func makeRandomChoice() {
        
        var possibleChoices = [0, 1, 2, 3]
        
        if !hasLocalPeerSubmitted {
            
            if selectionIndex != -1 { possibleChoices.remove(at: selectionIndex) }
            let rand = Int(arc4random_uniform(UInt32(possibleChoices.count)))
            selectOption(options[possibleChoices[rand]])
        }
    }
    
    override func motionEnded(_ motion: UIEventSubtype, with event: UIEvent?) {
        //print("motionEnded")
    }
    
    
    func updateDeviceMotion(){
        
        if let data = self.motionManager.deviceMotion {
            
            // orientation of body relative to a reference frame
            let attitude = data.attitude
            let userAcceleration = data.userAcceleration
            let rotation = data.rotationRate
            
            if shakeCooldown {
                return
            }
            
            // Force user submission (upon yaw or negative-z acceleration)
            if selectionIndex != -1 && !hasLocalPeerSubmitted {
                if fabs(CGFloat(attitude.yaw - initialAttitude.yaw)) > 1.50 {
                    shakeCooldown = true
                    shouldSubmit(selectionIndex)
                }
                
                if CGFloat(userAcceleration.z) < -3.00 {
                    shakeCooldown = true
                    shouldSubmit(selectionIndex)
                }
            }
            
            
            if fabs(CGFloat(attitude.pitch - initialAttitude.pitch)) > 1.50 { // pitch is equivalent to tilting device UP/DOWN
                shakeCooldown = true
                switchSelection(false)
            }
            
            if fabs(CGFloat(attitude.roll - initialAttitude.roll)) > 1.50 { // roll is equivalent to tilting device LEFT/RIGHT
                shakeCooldown = true
                switchSelection(true)
            }
            
        }
        
    }
    
    
    func record(){
        if CMSensorRecorder.isAccelerometerRecordingAvailable() {
            let recorder = CMSensorRecorder()
            recorder.recordAccelerometer(forDuration: 20 * 60)  // Record for 20 minutes
        }
    }
}
