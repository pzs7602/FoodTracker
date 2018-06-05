//
//  FoodListViewController.swift
//  FoodTracker
//
//  Created by PZS on 16/7/18.
//  Copyright © 2016年 SCNU. All rights reserved.
//

import UIKit
import CoreLocation
import ReplayKit

class FoodListViewController: UITableViewController,CLLocationManagerDelegate,MyLocationDelegate,UIViewControllerPreviewingDelegate{

    private var  foods: [Food] = [Food]()
    let locationManager = CLLocationManager()
    var currentLocation:CLLocation?
    var sharedRecorder: RPScreenRecorder = RPScreenRecorder.shared()
//    var previewViewController: RPPreviewViewController?
//    var broadcastController: RPBroadcastController?
    
    @IBOutlet weak var recordStopButton: UIBarButtonItem!
    func loadFoods() -> [Food]? {
        return NSKeyedUnarchiver.unarchiveObject(withFile: Food.ArchiveURL.path) as? [Food]
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        if( traitCollection.forceTouchCapability == .available){
            
            registerForPreviewing(with: self, sourceView: view)
            
        }

        if let savedFoods = loadFoods() {
            foods += savedFoods
        } else {
            loadDefaultFoods()
        }
        if ( CLLocationManager.authorizationStatus() == .notDetermined){
            locationManager.requestWhenInUseAuthorization()
        }
        locationManager.delegate = self
        
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        // allow background location updates
//        locationManager.allowsBackgroundLocationUpdates = true
//        locationManager.startMonitoringVisits()
        
        locationManager.startUpdatingLocation()
    }

    func loadDefaultFoods(){


    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return self.foods.count
    }

    
//    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        let cell = tableView.dequeueReusableCell(withIdentifier: "foodCell", for: indexPath) as! FoodCell
//        
//        cell.foodName.text = foods[(indexPath as NSIndexPath).row].name
//        if let image = foods[(indexPath as NSIndexPath).row].photo{
//            cell.foodImage!.image = self.resizedImage(image)
//        }
//        if cell.accessoryView == nil {
//            let indicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
//            cell.accessoryView = indicator
//        }
//        let indicator = cell.accessoryView as! UIActivityIndicatorView
//
//        return cell
//    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "foodCell", for: indexPath)  as! FoodCell
        
        cell.subTitle?.text = foods[(indexPath as NSIndexPath).row].restaurant
        cell.foodName?.text = foods[(indexPath as NSIndexPath).row].name
        if let image = foods[(indexPath as NSIndexPath).row].photo{
            cell.foodImage!.image = self.resizedImage(image)
        }
        else{
            cell.foodImage?.image = self.resizedImage(UIImage(named:"defaultImg" )!)
        }
        return cell
    }

    func resizedImage(_ image:UIImage) -> UIImage{
        // resize the image to width=64,height=64
        let scaleSize = CGSize(width: 64, height: 64)
        UIGraphicsBeginImageContextWithOptions(scaleSize, false, 0.0)
        image.draw(in: CGRect(x: 0, y: 0, width: scaleSize.width, height: scaleSize.height))
        let resizedImage:UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        // we keep the resized image data
        return resizedImage
    }
    
    @IBAction func exitToFoodList(_ segue: UIStoryboardSegue){
        print("source=\(segue.source)")
        if let preVC = segue.source as? FoodViewController{
            let food = preVC.food!
            if let selectedIndexPath = tableView.indexPathForSelectedRow {
                // Update an existing meal.
                foods[(selectedIndexPath as NSIndexPath).row] = food
                tableView.reloadRows(at: [selectedIndexPath], with: .none)
            } else {
                // Add a new meal.
                food.name = preVC.foodNameText.text!
                food.phone = preVC.phoneText.text!
                food.restaurant = preVC.restaurantText.text!
                let newIndexPath = IndexPath(row: foods.count, section: 0)
                foods.append(food)
                tableView.insertRows(at: [newIndexPath], with: .bottom)
            }
            // Save the meals.
            saveFoods()
        }
        
    }
    
    func saveFoods() {
        let success = NSKeyedArchiver.archiveRootObject(foods, toFile: Food.ArchiveURL.path)
        if !success {
            print("Failed ...")
        }
    }

    
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // if the food has associated video, delete it
            let food = foods[indexPath.row]
            // we only deal with the video taken by our app
            if let name = food.videoFileName{
                let filePath = (self.applicationDocumentsDirectory.path! as NSString).appendingPathComponent(name)
                do{
                    print("remove:\(filePath)")
                    try FileManager.default.removeItem(atPath: filePath)
                }
                catch let error as NSError?{
                    print("error removing file:\(error?.description)")
                }
            }
            // Delete the row from the data source
            foods.remove(at: (indexPath as NSIndexPath).row)
            saveFoods()
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showfood" {
            let foodViewController = segue.destination as! FoodViewController
            foodViewController.delegate = self
            
            // Get the cell that generated this segue.
            if let selectedCell = sender as? UITableViewCell {
                let indexPath = tableView.indexPath(for: selectedCell)!
                let selectedFood = foods[(indexPath as NSIndexPath).row]
                foodViewController.food = selectedFood
            }
        }
        else if segue.identifier == "addnew"{
            let foodViewController = (segue.destination as! UINavigationController).topViewController as! FoodViewController
            foodViewController.delegate = self
        
        }
    }
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        self.currentLocation = locations.last
//        print("location=\(self.currentLocation)")
    }
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse:
            locationManager.startUpdatingLocation()
        case .denied:
            
            let alertController = UIAlertController(title: "Locating Denied", message: "You did not grant the locating permission for this app.", preferredStyle: .alert)
            
            let OKAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alertController.addAction(OKAction)
            
            self.present(alertController, animated: true, completion: nil)
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        default:
            return
        }
    }
    // MyLocationDelegate
    func getCurrentLocation() -> CLLocation? {
        return self.currentLocation
    }
    
    // MARK: UIViewControllerPreviewingDelegate methods
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        
        guard let indexPath = tableView?.indexPathForRow(at: location) else { return nil }
        
        guard let cell = tableView?.cellForRow(at: indexPath) else { return nil }
        
        guard let previewVC = storyboard?.instantiateViewController(withIdentifier: "foodviewcontroller") as? FoodViewController else { return nil }
        
        let food = foods[(indexPath as NSIndexPath).row]
        previewVC.food = food
        
        previewVC.preferredContentSize = CGSize(width: 0.0, height: 0.0)
        
        previewingContext.sourceRect = cell.frame
        
        return previewVC
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        
        show(viewControllerToCommit, sender: self)
        
    }
    

    lazy var applicationDocumentsDirectory: NSURL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "com.gdou.RadioPlayer" in the application's documents Application Support directory.
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return urls[urls.count-1] as NSURL
    }()
}
