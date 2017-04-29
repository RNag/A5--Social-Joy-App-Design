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
    
    var session: MCSession!
    var peerID: MCPeerID!
    
    var browser: MCBrowserViewController!
    var assistant: MCAdvertiserAssistant!
    
    
    
    @IBOutlet weak var gamePlayMode: UISegmentedControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let screenWidthClass = self.traitCollection.horizontalSizeClass.rawValue
        
        
        if screenWidthClass == UIUserInterfaceSizeClass.regular.rawValue {// Regular Size Width indicates an iPad model screen
            
            let font = UIFont.systemFont(ofSize: 24)
            gamePlayMode.setTitleTextAttributes([NSFontAttributeName: font], for: .normal)
            
        }
        
        self.peerID = MCPeerID(displayName: UIDevice.current.name)
        self.session = MCSession(peer: peerID)
        self.browser = MCBrowserViewController(serviceType: "quiz", session: session)
        self.assistant = MCAdvertiserAssistant(serviceType: "quiz", discoveryInfo: nil, session: session)
        
        assistant.start()
        session.delegate = self
        browser.delegate = self
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Connect", style: .plain, target: self, action: #selector(RTapped))
        
        // Do any additional setup after loading the view.
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
    
    
    
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if identifier == "homeToQuiz" {
            
            
            switch(gamePlayMode.selectedSegmentIndex) {
            case playerModes.SinglePlayer.rawValue:
                return true
            case playerModes.MultiPlayer.rawValue:
                if session.connectedPeers.count == 0
                {
                    let alert = UIAlertController(title: "PeerCount", message: "Peer Count is 0", preferredStyle: .alert)
                    let peerAction = UIAlertAction(title: "Need more peers", style: .default, handler: nil)
                    
                    alert.addAction(peerAction)
                    
                    present(alert, animated: true, completion: nil)
                    
                    break
                    
                }
                
                if session.connectedPeers.count > 4
                {
                    let alert = UIAlertController(title: "PeerCount", message: "Peer Count is more than 4", preferredStyle: .alert)
                    let peerAction = UIAlertAction(title: "Need", style: .default, handler: nil)
                    
                    alert.addAction(peerAction)
                    
                    present(alert, animated: true, completion: nil)
                    
                    break
                }
                
                performSegue(withIdentifier: "GoToMulti", sender: self)
                return false
                
            default:
                return false
            }
        }
        
        return true
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "homeToQuiz" {
            let _ = segue.destination as! QuizScreen
            
            
        }
        
        if segue.identifier == "GoToMulti"
        {
            let _ = segue.destination as! Multiplayer
        }
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
            
            //if let receivedString = NSKeyedUnarchiver.unarchiveObject(with: data) as? String{
            //self.updateChatView(newText: receivedString, id: peerID)
            //}
            
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
    
    
    
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    
}
