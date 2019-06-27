//
//  ViewController.swift
//  QR_ARkit
//
//  Created by Joe Chen on 2018/10/29.
//  Copyright © 2018 Joe Chen. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import Vision
import CoreData



class ViewController: UIViewController ,ARSCNViewDelegate, ARSessionDelegate, UIPopoverPresentationControllerDelegate  {

    //coredata setup
   let moc = RecordContext.shared()

    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var trackingStatusLabel: UILabel!
    @IBOutlet weak var showPopUpBtn: UIButton!
    var detectedDataAnchor: ARAnchor?
    var processing = false
    var qrCodeInfo:String? = ""
    var displayedQRInfo:String? = ""
    var objectsViewController: PopUpTableViewController?
    var linkType = [String:Bool]()
    var qrURL : String = ""
    let configuration = ARWorldTrackingConfiguration()
    var QRArray = [[String:String]]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.trackingStatusLabel.layer.masksToBounds = true
        self.trackingStatusLabel.layer.cornerRadius = 5
        
        sceneView.delegate = self
        sceneView.session.delegate = self
        sceneView.autoenablesDefaultLighting = true
        sceneView.automaticallyUpdatesLighting = true
        
        linkType = ["save":true,"link":false]
        addTapGestureToSceneView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        
        configuration.planeDetection = .horizontal
        sceneView.session.run(configuration)
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        sceneView.session.pause()
    }
    
    func pauseSession(){
        self.qrCodeInfo = ""
        self.displayedQRInfo = ""
        self.sceneView.session.pause()
        self.sceneView.scene.rootNode.enumerateChildNodes { (node, _) in
            node.removeFromParentNode()
        }
        
    }
    
    func restartSesstion(){
        self.sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
    
    @IBAction func resetBtnClick(_ sender: Any) {
        
        self.processing = true
        self.showMessage("Restarting")
        self.pauseSession()
        self.restartSesstion()
        self.processing = false
        
    }
    public func session(_ session: ARSession, didUpdate frame: ARFrame) {
        
        // Only run one Vision request at a time
        if self.processing {
            return
        }
        self.processing = true
        // Create a Barcode Detection Request
        self.showTrackingStatusInfo()
        let request = VNDetectBarcodesRequest { (request, error) in
            
            
            // Get the first result out of the results, if there are any
            if let results = request.results, let result = results.first as? VNBarcodeObservation {
                
             
                if let payload = result.payloadStringValue {
                    
                    self.qrCodeInfo = payload
                }
                
                if self.qrCodeInfo == self.displayedQRInfo{
                    self.processing = false
                    return
                }
                
                
                // Get the bounding box for the bar code and find the center
                let rect = result.boundingBox
                // Get center
                let center = CGPoint(x: rect.midX, y: rect.midY)
                
                // Go back to the main thread
                DispatchQueue.main.async {
                    
                    // Perform a hit test on the ARFrame to find a surface
                    let hitTestResults = frame.hitTest(center, types: [.featurePoint] )
                    
                    //check what item should be showed
                    self.linkType["link"] = false
                    self.checkLinkType(linkStr: self.qrCodeInfo!)
                    
                    // If we have a result, process it
                    if let hitTestResult = hitTestResults.first {
                        
                        // If we already have an anchor, update the position of the attached node
                        if let detectedDataAnchor = self.detectedDataAnchor,
                            let node = self.sceneView.node(for: detectedDataAnchor) {
                            
                                node.removeFromParentNode()
                                //prepare to save to database
                                self.modifyRQCode(code: self.qrCodeInfo!)

                                self.detectedDataAnchor = ARAnchor(transform: hitTestResult.worldTransform)
                                self.sceneView.session.add(anchor: self.detectedDataAnchor!)

                            
                        } else {
                            // Create an anchor. The node will be created in delegate methods
                            self.modifyRQCode(code: self.qrCodeInfo!)
                            self.detectedDataAnchor = ARAnchor(transform: hitTestResult.worldTransform)
                            self.sceneView.session.add(anchor: self.detectedDataAnchor!)
                        }
                    }
                    self.processing = false
                }
            }else{
                self.processing = false
            }
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                // Set it to recognize QR code only
                request.symbologies = [.QR]
                
                // Create a request handler using the captured image from the ARFrame
                let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: frame.capturedImage,
                                                                options: [:])
                // Process the request
                try imageRequestHandler.perform([request])
            } catch {
                
            }
        }
    }
   
    
    // MARK: - ARSCNViewDelegate
    
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        
        // If this is our anchor, create a node
        if self.detectedDataAnchor?.identifier == anchor.identifier {
            
            self.displayedQRInfo = self.qrCodeInfo
            
            let wrapperNode = SCNNode()
            wrapperNode.transform = SCNMatrix4(anchor.transform)
            
            
            let text = SCNText(string: self.qrCodeInfo!, extrusionDepth: 1)
            text.firstMaterial?.diffuse.contents = UIColor.red
            let textNode = SCNNode(geometry: text)
            let fontScale: Float = 0.002
            //            textNode.movabilityHint = .movable
            textNode.scale = SCNVector3(fontScale, fontScale, fontScale)
            
            let (min, max) = (text.boundingBox.min, text.boundingBox.max)
            let dx = min.x + 0.5 * (max.x - min.x)
            let dy = min.y + 0.5 * (max.y - min.y)
            let dz = min.z + 0.5 * (max.z - min.z)
            textNode.pivot = SCNMatrix4MakeTranslation(dx, dy, dz)
        
            
            wrapperNode.addChildNode(textNode)
            
            if linkType["link"] == true{
            
                let saveScene = SCNScene(named: "art.scnassets/save_model.scn")
                let saveSceneChildNode = saveScene!.rootNode.childNode(withName: "save", recursively: false)
                
                saveSceneChildNode?.scale = SCNVector3(0.01, 0.01, 0.01)
                saveSceneChildNode?.position = SCNVector3(textNode.transform.m11 , textNode.transform.m22 + 0.05, textNode.transform.m33)
                
                saveSceneChildNode?.eulerAngles.x = .pi / 2
                wrapperNode.addChildNode(saveSceneChildNode!)
                
                //---------------------
                
                let linkScene = SCNScene(named: "art.scnassets/Link_model.scn")
                let linkSceneChildNodes = linkScene!.rootNode.childNode(withName: "link", recursively: false)

                linkSceneChildNodes?.scale = SCNVector3(0.01, 0.01, 0.01)
                linkSceneChildNodes?.position = SCNVector3(textNode.transform.m11 + 0.1 , textNode.transform.m22 + 0.05, textNode.transform.m33)
                
                linkSceneChildNodes?.eulerAngles.x = .pi / 2
                wrapperNode.addChildNode(linkSceneChildNodes!)
            
            }else{

                //only save
                let saveScene = SCNScene(named: "art.scnassets/save_model.scn")
                let saveSceneChildNode = saveScene!.rootNode.childNode(withName: "save", recursively: false)
                
                saveSceneChildNode?.scale = SCNVector3(0.01, 0.01, 0.01)
                saveSceneChildNode?.position = SCNVector3(textNode.transform.m11 , textNode.transform.m22 + 0.05, textNode.transform.m33)
                
                saveSceneChildNode?.eulerAngles.x = .pi / 2
                wrapperNode.addChildNode(saveSceneChildNode!)
                
            }
            
            // Set its position based off the anchor
            
            return wrapperNode
        }
        
        return nil
    }
    
    func checkLinkType(linkStr : String){
        
        let detector = try! NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        
        detector.enumerateMatches(in: self.qrCodeInfo!, options: [], range: NSRange(location: 0, length: self.qrCodeInfo!.count)) { (result, flag, pointer) in
            
            if result?.resultType == NSTextCheckingResult.CheckingType.link{
                let url = result?.url?.absoluteString
                self.qrURL = url!
                linkType["link"]! = true
            }else{
                linkType["link"]! = false
            }
        }
        
    }
    
    func addTapGestureToSceneView() {
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTap(withGestureRecognizer:)))
        sceneView.addGestureRecognizer(tapGestureRecognizer)
        
    }
    
    @objc func didTap(withGestureRecognizer recognizer: UITapGestureRecognizer){
        
        let tapLocation = recognizer.location(in: sceneView)
        let hitTestResults = sceneView.hitTest(tapLocation)
        
        guard let node = hitTestResults.first?.node else {
            
            return
        }
        
        if node.name == "link" {
            performSegue(withIdentifier:"showWeb", sender: node)
        }else if node.name == "save"{
            saveQRInfoClick()
        }
        
        self.displayedQRInfo = ""

    }
    
    
    func updatePositionAndOrientationOf(_ node: SCNNode, withPosition position: SCNVector3, relativeTo referenceNode: SCNNode) {
        let referenceNodeTransform = matrix_float4x4(referenceNode.transform)
        
        // Setup a translation matrix with the desired position
        var translationMatrix = matrix_identity_float4x4
        translationMatrix.columns.3.x = position.x
        translationMatrix.columns.3.y = position.y
        translationMatrix.columns.3.z = position.z
        
        
        
        // Combine the configured translation matrix with the referenceNode's transform to get the desired position AND orientation
        let updatedTransform = matrix_multiply(referenceNodeTransform, translationMatrix)
        node.transform = SCNMatrix4(updatedTransform)
    }
    
    func showTrackingStatusInfo() {
        
        if self.displayedQRInfo == "" {
            self.showMessage("Please Scan The QR Code")
        }else{
            self.showMessage("QR Code Scanned")
        }
    }
    
    func showMessage(_ text: String, autoHide: Bool = true) {
        
        trackingStatusLabel.text = text

    }
    
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
    
    @IBAction func showPopUpBtnClick(_ sender: Any) {
        
        performSegue(withIdentifier:"showOptions", sender: showPopUpBtn)
        
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "showOptions"{
            if let popoverController = segue.destination.popoverPresentationController, let button = sender as? UIButton {
                popoverController.delegate = self
                popoverController.sourceView = button
                popoverController.sourceRect = button.bounds
            }
            
            let objectsViewController = segue.destination as! PopUpTableViewController
            self.objectsViewController = objectsViewController
        }else if segue.identifier == "showWeb"{
            if let webController = segue.destination as? ShowWebController{
                self.pauseSession()
                webController.resetTrackingDelegate = self
                webController.webURL = self.qrURL
            }
        }
        
    }
    
    
    
    func modifyRQCode(code : String){
        
        let codeDic = ["name":String(code)]
        self.QRArray.append(codeDic)

        
    }
    
    func saveQRInfoClick() {
        
        let entity = NSEntityDescription.entity(forEntityName:"QRRecord", in: moc)!
        
        if self.QRArray.count != 0 {
        
            for count in 0...self.QRArray.count-1{
                
                let tempRecordDic = self.QRArray[count]
                let description = tempRecordDic["name"]
                let request = NSFetchRequest<NSFetchRequestResult>(entityName: "QRRecord")
                
                request.predicate = NSPredicate(format: "name == %@ ", argumentArray:[description!])
                do {
                    let scanQR =
                        try moc.fetch(request) as! [QRRecord]
                    if scanQR.count == 0 {
                        
                        let indexRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "QRRecord")
                        indexRequest.sortDescriptors = [NSSortDescriptor(key: "index", ascending: false)]
                        let indexCount =  try moc.fetch(indexRequest) as! [QRRecord]

                        let record = NSManagedObject(entity: entity, insertInto: moc)
                        
                        if(indexCount.count == 0){
                            record.setValue(1, forKey: "index")
                        }else{
                            record.setValue(indexCount[0].index + 1, forKey: "index")
                        }

                        record.setValue(description, forKey: "name")
                       
                        do {
                            try moc.save()
                            
                        } catch let error as NSError {
                            fatalError("\(error)")
                            
                        }
                    }
                } catch {
                    fatalError("\(error)")
                    
                }
                self.showMessage("Save QR code Successfully")
            }
            
        }else{
            
            let alert = UIAlertController(title: "", message: "There is no QR code scanned", preferredStyle: .alert)
            let action = UIAlertAction(title: "OK", style: .default, handler: nil)
            
            alert.addAction(action)
            self.present(alert, animated: true)
            
        }
        self.QRArray.removeAll()
        
    }
    
}

extension float4x4 {
    var translation: float3 {
        let translation = self.columns.3
        return float3(translation.x, translation.y, translation.z)
    }
}

extension ViewController : resetTrackingDelegate {
    func resetTracking() {
        self.restartSesstion()
    }
}


