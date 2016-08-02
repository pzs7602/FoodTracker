//
//  MapViewController.swift
//  FoodTracker
//
//  Created by panzhansheng on 2016/7/18.
//  Copyright © 2016年 idup. All rights reserved.
//

import UIKit
import MapKit

class MapViewController: UIViewController,MKMapViewDelegate {

    @IBOutlet weak var mapView: MKMapView!
    var annotation:MKPointAnnotation?
    var location:CLLocation?
    var addressDictionary: [String : AnyObject]?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    override func viewDidAppear(_ animated: Bool) {
        if let loc = self.location{
            self.mapView.showsUserLocation = true

            self.putAnnotation(location: loc)
            self.navigate(from: nil, to: loc)
        }
        
    }
    func navigate(from: CLLocation?, to: CLLocation)
    {
        let request = MKDirectionsRequest()
        if from == nil{
            request.source = MKMapItem.forCurrentLocation()
        }
        request.requestsAlternateRoutes = false
        CLGeocoder().reverseGeocodeLocation(location!, completionHandler:{(marks, error) in
            if error == nil, marks?.count>0{
                self.addressDictionary = marks![0].addressDictionary as? [String : AnyObject]
                let placeMark = MKPlacemark(coordinate: (self.location?.coordinate)!,addressDictionary:self.addressDictionary)
                print("name=\(marks![0].name),\(marks![0].addressDictionary)")
                request.destination = MKMapItem(placemark: placeMark)
                // show overlay in map
                let directions = MKDirections(request: request)
                directions.calculate { (response:MKDirectionsResponse?, error:Error?) in
                    if error != nil{
                        print("error=\(error?.localizedDescription)")
                    }
                    else{
                        self.showRoutes(response: response!)
                    }
                }
                // open map with MKMapItems in
                let options = [MKLaunchOptionsDirectionsModeKey:MKLaunchOptionsDirectionsModeDriving,MKLaunchOptionsShowsTrafficKey:true]
                MKMapItem.openMaps(with: [request.source!,request.destination!], launchOptions: options as? [String : AnyObject])
                

            }
        })
    }
//    func getPlaceMark(from location:CLLocation) -> MKPlacemark{
//        CLGeocoder().reverseGeocodeLocation(location, completionHandler:{(marks, error) in
//            if error == nil, marks?.count>0{
                
//            }
//        })
        
//    }
    func showRoutes(response:MKDirectionsResponse)
    {
        for route in response.routes{
            self.mapView.add(route.polyline, level: MKOverlayLevel.aboveRoads)
            for step in route.steps{
                print("instructions:\(step.instructions)")
            }
        }
    }
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay)
        renderer.strokeColor = UIColor.blue
        renderer.lineWidth = 5.0
        return renderer
    }
    @IBAction func okButtonAction(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }
    func putAnnotation(location:CLLocation){
        if self.annotation != nil{
            self.mapView .removeAnnotation(self.annotation!)
            self.annotation = nil
        }
        self.annotation = MKPointAnnotation()
        self.annotation?.title = "您位于：" + self.getStringLocationFrom(location: location)
        self.annotation?.subtitle = "北纬：\(location.coordinate.latitude)，东经：\(location.coordinate.longitude)"
        self.annotation?.coordinate = location.coordinate
        self.mapView.addAnnotation(self.annotation!)
        let viewRegion = MKCoordinateRegionMakeWithDistance(location.coordinate, 1000, 1000)
        let adjustedRegion = self.mapView.regionThatFits(viewRegion)
        self.mapView.setRegion(adjustedRegion, animated: true)
        
    }

    func getStringLocationFrom(location:CLLocation) -> String{
        var address = ""
        CLGeocoder().reverseGeocodeLocation(location, completionHandler:{(marks, error) in
            if error == nil, marks?.count>0{
                let country = (marks![0].country) ?? ""
                let admin = (marks![0].administrativeArea) ?? ""
                let subadmin = (marks?[0].subAdministrativeArea) ?? ""
                let name = (marks?[0].name) ?? ""
                address = address + country + " " + admin + " " + subadmin + " " + name
                DispatchQueue.main.async {
                    self.annotation?.title = "您位于：" + address
                    self.title = "您位于：" + address
                }
            }
        })
    
        // the returned address is empty, we can get proper address from completiuon handler
        return address
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
