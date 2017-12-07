//
//  ARExampleViewController.swift
//  DigitalImageDemonstration_Swift
//
//  Created by liubo on 2017/12/7.
//  Copyright © 2017年 devliubo. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ARExampleViewController: UIViewController {
    
    // MARK: - ARKit Config Properties
    
    var screenCenter: CGPoint?
    
    let session = ARSession()
    let standardConfiguration: ARWorldTrackingConfiguration = {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        return configuration
    }()
    
    // MARK: - Virtual Object Manipulation Properties
    
    var virtualObjectManager: VirtualObjectManager!
    var isLoadingObject: Bool = false {
        didSet {
            DispatchQueue.main.async {
                self.addObjectButton.isEnabled = !self.isLoadingObject
                self.restartExperienceButton.isEnabled = !self.isLoadingObject
            }
        }
    }
    
    // MARK: - Other Properties
    
    var textManager: TextManager!
    var restartExperienceButtonIsEnabled = true
    
    // MARK: - UI Elements
    
    var spinner: UIActivityIndicatorView?
    
    var sceneView: ARSCNView!
    var messageLabel: UILabel!
    var addObjectButton: UIButton!
    var restartExperienceButton: UIButton!
    
    // MARK: - Queues
    
    let serialQueue = DispatchQueue(label: "com.devliubo.seriaSceneKitQueue")
    
    // MARK: - View Controller Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.white
        
        navigationController?.isNavigationBarHidden = false
        navigationController?.navigationBar.isTranslucent = false
        navigationController?.isToolbarHidden = true
        edgesForExtendedLayout = .init(rawValue: 0)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        initSubviews()
        setupUIControls()
        setupScene()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        UIApplication.shared.isIdleTimerDisabled = true
        
        if ARWorldTrackingConfiguration.isSupported {
            // Start the ARSession.
            resetTracking()
        } else {
            displayErrorMessage(title: "Unsupported platform", message: sessionErrorMsg, allowRestart: false)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        session.pause()
    }
    
    // MARK: - Setup
    
    func initSubviews() {
        sceneView = ARSCNView(frame: view.bounds)
        view.addSubview(sceneView)
        
        messageLabel = UILabel(frame: CGRect(x: 10, y: 0, width: view.bounds.size.width-20, height: 40))
        messageLabel.backgroundColor = UIColor(white: 1.0, alpha: 0.7)
        messageLabel.textAlignment = .center
        messageLabel.adjustsFontSizeToFitWidth = true
        view.addSubview(messageLabel)
        
        addObjectButton = UIButton(type: .roundedRect)
        addObjectButton.frame = CGRect(x: 10, y: view.bounds.size.height-60, width: 90, height: 40)
        addObjectButton.backgroundColor = UIColor.red
        addObjectButton.setTitle("AddObject", for: .normal)
        addObjectButton.addTarget(self, action: #selector(ARExampleViewController.chooseObject), for: .touchUpInside)
        view.addSubview(addObjectButton)
        
        restartExperienceButton = UIButton(type: .roundedRect)
        restartExperienceButton.frame = CGRect(x: view.bounds.size.width-100, y: view.bounds.size.height-60, width: 90, height: 40)
        restartExperienceButton.backgroundColor = UIColor.red
        restartExperienceButton.setTitle("Restart", for: .normal)
        restartExperienceButton.addTarget(self, action: #selector(ARExampleViewController.restartExperience), for: .touchUpInside)
        view.addSubview(restartExperienceButton)
    }
    
    func setupScene() {
        // Synchronize updates via the `serialQueue`.
        virtualObjectManager = VirtualObjectManager(updateQueue: serialQueue)
        virtualObjectManager.delegate = self
        
        // set up scene view
        sceneView.setup()
        sceneView.delegate = self
        sceneView.session = session
        sceneView.showsStatistics = true
        
        sceneView.scene.enableEnvironmentMapWithIntensity(25, queue: serialQueue)
        
        setupFocusSquare()
        
        DispatchQueue.main.async {
            self.screenCenter = self.sceneView.bounds.mid
        }
    }
    
    func setupUIControls() {
        textManager = TextManager(viewController: self)
    }
    
    // MARK: - Gesture Recognizers
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        virtualObjectManager.reactToTouchesBegan(touches, with: event, in: self.sceneView)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        virtualObjectManager.reactToTouchesMoved(touches, with: event)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if virtualObjectManager.virtualObjects.isEmpty {
            chooseObject(addObjectButton)
        }
        virtualObjectManager.reactToTouchesEnded(touches, with: event)
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        virtualObjectManager.reactToTouchesCancelled(touches, with: event)
    }
    
    // MARK: - Planes
    
    var planes = [ARPlaneAnchor: Plane]()
    
    func addPlane(node: SCNNode, anchor: ARPlaneAnchor) {
        let plane = Plane(anchor)
        planes[anchor] = plane
        node.addChildNode(plane)
        
        textManager.cancelScheduledMessage(forType: .planeEstimation)
        textManager.showMessage("SURFACE DETECTED")
        if virtualObjectManager.virtualObjects.isEmpty {
            textManager.scheduleMessage("TAP + TO PLACE AN OBJECT", inSeconds: 7.5, messageType: .contentPlacement)
        }
    }
    
    func updatePlane(anchor: ARPlaneAnchor) {
        if let plane = planes[anchor] {
            plane.update(anchor)
        }
    }
    
    func removePlane(anchor: ARPlaneAnchor) {
        if let plane = planes.removeValue(forKey: anchor) {
            plane.removeFromParentNode()
        }
    }
    
    func resetTracking() {
        session.run(standardConfiguration, options: [.resetTracking, .removeExistingAnchors])
        
        textManager.scheduleMessage("FIND A SURFACE TO PLACE AN OBJECT", inSeconds: 7.5, messageType: .planeEstimation)
    }
    
    // MARK: - Focus Square
    
    var focusSquare: FocusSquare?
    
    func setupFocusSquare() {
        serialQueue.async {
            self.focusSquare?.isHidden = true
            self.focusSquare?.removeFromParentNode()
            self.focusSquare = FocusSquare()
            self.sceneView.scene.rootNode.addChildNode(self.focusSquare!)
        }
        
        textManager.scheduleMessage("TRY MOVING LEFT OR RIGHT", inSeconds: 5.0, messageType: .focusSquare)
    }
    
    func updateFocusSquare() {
        guard let screenCenter = screenCenter else { return }
        
        DispatchQueue.main.async {
            var objectVisible = false
            for object in self.virtualObjectManager.virtualObjects {
                if self.sceneView.isNode(object, insideFrustumOf: self.sceneView.pointOfView!) {
                    objectVisible = true
                    break
                }
            }
            
            if objectVisible {
                self.focusSquare?.hide()
            } else {
                self.focusSquare?.unhide()
            }
            
            let (worldPos, planeAnchor, _) = self.virtualObjectManager.worldPositionFromScreenPosition(screenCenter,
                                                                                                       in: self.sceneView,
                                                                                                       objectPos: self.focusSquare?.simdPosition,
                                                                                                       infinitePlane: false)
            if let worldPos = worldPos {
                self.serialQueue.async {
                    self.focusSquare?.update(for: worldPos, planeAnchor: planeAnchor, camera: self.session.currentFrame?.camera)
                }
                self.textManager.cancelScheduledMessage(forType: .focusSquare)
            }
        }
    }
    
    // MARK: - Error handling
    
    func displayErrorMessage(title: String, message: String, allowRestart: Bool = false) {
        // Blur the background.
        textManager.blurBackground()
        
        if allowRestart {
            // Present an alert informing about the error that has occurred.
            let restartAction = UIAlertAction(title: "Reset", style: .default) { _ in
                self.textManager.unblurBackground()
                self.restartExperience(self)
            }
            textManager.showAlert(title: title, message: message, actions: [restartAction])
        } else {
            textManager.showAlert(title: title, message: message, actions: [])
        }
    }
}
