//
//  HomeScreen.swift
//  Assignment5 - Collab
//
//  Created by Ritvik on 4/22/17.
//  Copyright © 2017 Ritvik Nag. All rights reserved.
//

import UIKit


class HomeScreen : UIViewController {
    
    enum playerModes : Int {
        case SinglePlayer = 0
        case MultiPlayer
    }
    
    @IBOutlet weak var gamePlayMode: UISegmentedControl!

    override func viewDidLoad() {
        super.viewDidLoad()
        let screenWidthClass = self.traitCollection.horizontalSizeClass.rawValue
        
        
        if screenWidthClass == UIUserInterfaceSizeClass.regular.rawValue {// Regular Size Width indicates an iPad model screen
            
            let font = UIFont.systemFont(ofSize: 24)
            gamePlayMode.setTitleTextAttributes([NSFontAttributeName: font], for: .normal)
            
        }
        
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
                presentAlert("Come back later", "Work in progress ...", "Cancel")
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
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
