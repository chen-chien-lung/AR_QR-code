//
//  RecordTableViewController.swift
//  QR_ARkit
//
//  Created by Joe Chen on 2018/12/12.
//  Copyright © 2018 Joe Chen. All rights reserved.
//

import UIKit
import CoreData

class recordCell: UITableViewCell {
    
    
 
    @IBOutlet weak var qrName: UILabel!
    //    @IBOutlet weak var qrDate: UILabel!
    
}

class RecordTableViewController: UITableViewController {

    var recordCode = [QRRecord]()
    let moc = RecordContext.shared()
    var webLinkView : ShowWebController?
    var cellURL : String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "QRRecord")
        request.sortDescriptors = [NSSortDescriptor(key: "index", ascending: false)]
        do {
            self.recordCode =
                try moc.fetch(request) as! [QRRecord]
            
        } catch {
            fatalError("\(error)")
        }
        
    }
    
//    override func viewWillLayoutSubviews() {
//        preferredContentSize = CGSize(width: tableView.contentSize.width, height: tableView.contentSize.height)
//    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return self.recordCode.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "recordCell", for: indexPath) as! recordCell

        let item : QRRecord = self.recordCode[indexPath.row]
        cell.qrName.text = item.name
//        cell.qrDate.text = item.expiration
        // Configure the cell...
//        cell.visualEffectView.alpha = 0.1

        return cell
    }
 

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
//            tableView.deleteRows(at: [indexPath], with: .fade)
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: "QRRecord")
            request.predicate = NSPredicate(format: "index == %@", argumentArray:[self.recordCode[indexPath.row].index])
            //                        let indexCount =  try moc.count(for: indexRequest)
            do {
                let deleteItem =  try moc.fetch(request) as! [QRRecord]
                for item in deleteItem {
                    moc.delete(item)
                }
                self.recordCode.remove(at: indexPath.row)
                try moc.save()
                
            } catch {
                fatalError("\(error)")
                
            }
            self.tableView.reloadData()
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }
        
    }
 
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let cell = tableView.cellForRow(at: indexPath) as! recordCell
            
        self.checkLinkType(linkStr: cell.qrName.text ?? "" )
        
        
        
    }
    
    func checkLinkType(linkStr : String){
        
        let detector = try! NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        
        detector.enumerateMatches(in: linkStr, options: [], range: NSRange(location: 0, length: linkStr.count)) { (result, flag, pointer) in
            
            if result?.resultType == NSTextCheckingResult.CheckingType.link{
                let url = result?.url?.absoluteString
                self.cellURL = url!
                performSegue(withIdentifier:"recordShowWeb", sender: self)
            }else{
                
            }
        }
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
         if segue.identifier == "recordShowWeb"{
            if let webController = segue.destination as? ShowWebController{
                webController.webURL = self.cellURL
            }
        }
        
    }

    
    

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
//    override func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) {
//        
//        let cell = tableView.cellForRow(at: indexPath)
//        cell?.backgroundColor = UIColor.lightGray.withAlphaComponent(0.5)
//    }
//    
//    override func tableView(_ tableView: UITableView, didUnhighlightRowAt indexPath: IndexPath) {
//        
//        let cell = tableView.cellForRow(at: indexPath)
//        cell?.backgroundColor = .clear
//    }

}
