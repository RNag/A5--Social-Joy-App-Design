//
//  HomeScreen.swift
//  Assignment5 - Collab
//
//  Created by Ritvik on 4/22/17.
//  Copyright © 2017 Ritvik Nag. All rights reserved.
//

import UIKit
import MultipeerConnectivity



class HomeScreen : UIViewController, MCBrowserViewControllerDelegate, MCSessionDelegate {
    
    enum playerModes : Int {
        case SinglePlayer = 0
        case MultiPlayer = 1
    }
    
    @IBOutlet weak var gamePlayMode: UISegmentedControl!
    
    var session: MCSession!
    var peerID: MCPeerID!
    
    var browser: MCBrowserViewController!
    var assistant: MCAdvertiserAssistant!
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        
        if assistant == nil {
            // This prevents viewWillAppear() from running if the Browser VC is being dismissed
            
            print("Refreshing ...")
            self.peerID = MCPeerID(displayName: UIDevice.current.name)
            self.session = MCSession(peer: peerID)
            self.browser = MCBrowserViewController(serviceType: "quiz", session: session)
            self.assistant = MCAdvertiserAssistant(serviceType: "quiz", discoveryInfo: nil, session: session)
            assistant.start()
            session.delegate = self
            browser.delegate = self
        }
        

        
        // Do any additional setup after loading the view.
    }
    
    override func viewWillDisappear(_ animated: Bool) {

        if !browser.isBeingPresented {
            assistant.stop()
            assistant = nil
            print("Dismissing homescreen ...")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let screenWidthClass = self.traitCollection.horizontalSizeClass.rawValue
        
        if screenWidthClass == UIUserInterfaceSizeClass.regular.rawValue {// Regular Size Width indicates an iPad model screen
            let font = UIFont.systemFont(ofSize: 24)
            gamePlayMode.setTitleTextAttributes([NSFontAttributeName: font], for: .normal)
        }
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Connect", style: .plain, target: self, action: #selector(RTapped))
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func RTapped() -> ()
    {
        present(browser, animated: true, completion: nil)
        
        
        
    }
    
    
    
    
    //  My function to print out an alert to user
    func presentAlert(_ _title: String, _ _msg: String, _ btnNames : String ...){
        
        let alert = UIAlertController(title: _title, message: _msg, preferredStyle: .alert)
        
        for btnName in btnNames {
            
            let btnStyle = btnName.lowercased() == "cancel" ? UIAlertActionStyle.cancel : UIAlertActionStyle.default
            
            alert.addAction(UIAlertAction(title: btnName, style: btnStyle))
        }
        
        self.present(alert, animated: true, completion: nil)
        
    }
    
    
    @IBAction func startQuizWithMode(_ sender: UIButton) {
        
        switch(gamePlayMode.selectedSegmentIndex) {
        
        case playerModes.SinglePlayer.rawValue:
                performSegue(withIdentifier: "homeToSingle", sender: self)
            
        case playerModes.MultiPlayer.rawValue:
            
            switch(session.connectedPeers.count){
            
            case 0:
                presentAlert("No Peers Found", "Please add at least one other peer.", "Cancel")
            case 4 ... .max:
                presentAlert("Too Many Peers", "Maximum number of players (4) reached.\nPlease disconnect or drop some peers.", "Cancel")
            default:
                performSegue(withIdentifier: "homeToMulti", sender: self)
            
            }
            
        default:
            break
            
        }
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        browser.dismiss(animated: false, completion: nil)
        
        if segue.identifier == "homeToSingle" {
            let _ = segue.destination as! Singleplayer
        }
        
        if segue.identifier == "homeToMulti"
        {
            let multi = segue.destination as! Multiplayer
            multi.session = session
            
            //  Immediately send/forward all connected peers to the destination view controller
            let msg : [String : Any] = ["segueId" : "forwardToMulti"]
            let dataToSend =  NSKeyedArchiver.archivedData(withRootObject: msg)
            let myPeers = session.connectedPeers.filter({$0 != session.myPeerID})

            do {
                try session.send(dataToSend, toPeers: myPeers, with: .unreliable)
            }
            
            catch let err {
                print("Error in sending data \(err)")
            }
            
        }
        
        if segue.identifier == "forwardToMulti"
        {
            let multi = segue.destination as! Multiplayer
            multi.session = session
        }
        
    }
    
    
    //**********************************************************
    // required functions for MCBrowserViewControllerDelegate
    func browserViewControllerDidFinish(_ browserViewController: MCBrowserViewController) {
        // Called when the browser view controller is dismissed
        dismiss(animated: true, completion: nil)
        
        let msg : [String : Any] = ["connected_MSG" : "There are (\(session.connectedPeers.count + 1)) Players connected."]
        let dataToSend =  NSKeyedArchiver.archivedData(withRootObject: msg)
        let myPeers = session.connectedPeers
        
        do {
            try session.send(dataToSend, toPeers: myPeers, with: .unreliable)
        }
        catch let err {
            print("Error in sending data \(err)")
        }
        print(msg["connected_MSG"]!)    // Prints on debug screen (for player who is dismissing)
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
            guard let receivedDict = NSKeyedUnarchiver.unarchiveObject(with: data) as? [String : Any]
            else {
                print("Error receiving data ...")
                return
            }
            if let forwardedSegueId = receivedDict["segueId"] as? String {
                
                self.browser.dismiss(animated: false, completion: nil)
                self.performSegue(withIdentifier: forwardedSegueId, sender: self)
            }
            
            if let connected_MSG = receivedDict["connected_MSG"] as? String {
                print(connected_MSG)
            }
            
        })
    
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        
    }
    
    
    func session(_ session: MCSession, peer: MCPeerID, didChange state: MCSessionState) {
        
        // Called when a connected peer changes state (for example, goes offline)
        
        switch state {
        case MCSessionState.connected:
            print("Connected: \(session.connectedPeers.last!.displayName) - Peer #\(session.connectedPeers.count)")
            

        case MCSessionState.connecting:
            print("Connecting with ... Player \(session.connectedPeers.count + 2)")
            
        case MCSessionState.notConnected:
            print("Not Connected: \(peer.displayName)")
        }
        
        
    }
    //**********************************************************
    
    
    
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    
}
