//
//  ARExampleViewController+Actions.swift
//  DigitalImageDemonstration_Swift
//
//  Created by liubo on 2017/12/7.
//  Copyright © 2017年 devliubo. All rights reserved.
//

import UIKit
import SceneKit

extension ARExampleViewController: UIPopoverPresentationControllerDelegate {
    
    // MARK: - Interface Actions
    
    @objc func chooseObject(_ button: UIButton) {
        // Abort if we are about to load another object to avoid concurrent modifications of the scene.
        if isLoadingObject { return }
        
        textManager.cancelScheduledMessage(forType: .contentPlacement)
        
        let settingVC = VirtualObjectSelectionViewController()
        settingVC.delegate = self;
        settingVC.modalPresentationStyle = .popover
        settingVC.popoverPresentationController?.delegate = self
        settingVC.popoverPresentationController?.sourceView = button
        settingVC.popoverPresentationController?.sourceRect = button.bounds
        
        present(settingVC, animated: true)
    }
    
    /// - Tag: restartExperience
    @objc func restartExperience(_ sender: Any) {
        guard restartExperienceButtonIsEnabled, !isLoadingObject else { return }
        
        DispatchQueue.main.async {
            self.restartExperienceButtonIsEnabled = false
            
            self.textManager.cancelAllScheduledMessages()
            self.textManager.dismissPresentedAlert()
            self.textManager.showMessage("STARTING A NEW SESSION")
            
            self.virtualObjectManager.removeAllVirtualObjects()
            self.focusSquare?.isHidden = true
            
            self.resetTracking()
            
            // Show the focus square after a short delay to ensure all plane anchors have been deleted.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                self.setupFocusSquare()
            })
            
            // Disable Restart button for a while in order to give the session enough time to restart.
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0, execute: {
                self.restartExperienceButtonIsEnabled = true
            })
        }
    }
    
    // MARK: - UIPopoverPresentationControllerDelegate
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
    
}
