//
//  manager.swift
//  Assignment5 - Collab
//
//  Created by Charles O Nimo on 5/2/17.
//  Copyright © 2017 Eyuphan Bulut. All rights reserved.
//

import UIKit
import MultipeerConnectivity

class MCPeerManager: NSObject, MCSessionDelegate {
    var session : MCSession!
    var peer : MCPeerID!
    var browser : MCNearbyServiceBrowser!
    var advertiser : MCNearbyServiceAdvertiser!
    var foundPeers = [MCPeerID]()
    var invitationHandler : ((Bool, MCSession?)->Void)!
    
    override init() {
        super.init()
        peer = MCPeerID(displayName: UIDevice.current.name)
        session = MCSession(peer: peer)
        session.delegate = self
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
    
}
