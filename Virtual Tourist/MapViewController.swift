//
//  MapViewController.swift
//  Virtual Tourist
//
//  Created by Fatima Aljaber on 28/01/2019.
//  Copyright © 2019 Fatima. All rights reserved.
//

import UIKit
import MapKit
import CoreData
import SVProgressHUD
class MapViewController: UIViewController ,MKMapViewDelegate{
    
    var flag: Bool = false
    var mapData: MapData!
    @IBOutlet var map: MKMapView!
    var dataController:DataController!
    @IBOutlet weak var editButton: UIBarButtonItem!
    @IBOutlet weak var deleteLabel: UILabel!
    var fetchedResultsController:NSFetchedResultsController<MapData>!


    override func viewDidLoad() {
        super.viewDidLoad()
        map.delegate = self
        deleteLabel.isHidden = true
        editButton.title = "Edit"
        
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleTap))
        gestureRecognizer.minimumPressDuration = 1
        gestureRecognizer.delegate = self as? UIGestureRecognizerDelegate
        map.addGestureRecognizer(gestureRecognizer)
        
        fetchData()
        
    }
    //_________________Edit and Done Button______________________//
    
    @IBAction func edit(_ sender: UIBarButtonItem) {
        if !flag{
            flag = true
            editButton.title = "Done"
            deleteLabel.isHidden = false
        }
        else{
            if flag {
                flag = false
                editButton.title = "Edit"
                deleteLabel.isHidden = true
                
            }
        }
    }

    //_________________Fetch Pin______________________//

   func fetchData(){
 
    let fetchRequest: NSFetchRequest<MapData> = MapData.fetchRequest()

    if let data = try? dataController.viewContext.fetch(fetchRequest) {
        
        for location in data {
            
            let lat = CLLocationDegrees(location.lati!)
            let long = CLLocationDegrees(location.long!)
            let coordinate = CLLocationCoordinate2D(latitude: lat!, longitude: long!)
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            map.addAnnotation(annotation)
            
        }
    }
    }
    
    //_________________Drop PIN______________________//

    @objc func handleTap(gestureReconizer: UILongPressGestureRecognizer) {
        if gestureReconizer.state != UIGestureRecognizerState.ended {
            return
        }
        let location = gestureReconizer.location(in: self.map)
        let coordinate = map.convert(location,toCoordinateFrom: map)
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        let mapData = MapData(context: self.dataController.viewContext)
        mapData.lati = "\(annotation.coordinate.latitude)"
        mapData.long = "\(annotation.coordinate.longitude)"
            mapData.title = "\(annotation.coordinate.latitude),\(annotation.coordinate.longitude)"
        
        try! dataController.viewContext.save()
        map.addAnnotation(annotation)
        
    }
    //_________________Map Control______________________//

    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView)
    {
        let fetchRequest: NSFetchRequest<MapData> = MapData.fetchRequest()
        let title = "\(view.annotation!.coordinate.latitude),\(view.annotation!.coordinate.longitude)"
        let predicate = NSPredicate(format: "title == %@", title)
        
        fetchRequest.predicate = predicate
        let data = try? dataController.viewContext.fetch(fetchRequest)
        
        if flag {
                for pin in data!{
                    dataController.viewContext.delete(pin)
                    map.removeAnnotation(view.annotation!)
                    print("This Taped pin is deleted")}
        }
        else{
             for pin in data!{
            let iteminfo = self.storyboard?.instantiateViewController(withIdentifier: "ViewController") as! PhotoAlbumViewController
            iteminfo.lon = view.annotation!.coordinate.longitude
            iteminfo.lat = view.annotation!.coordinate.latitude
            iteminfo.dataController = dataController
                if pin.lati == String(iteminfo.lat) && pin.long == String(iteminfo.lon) {
                    iteminfo.mapData = pin
                    self.navigationController?.pushViewController(iteminfo, animated: true)

                }
            }
        }
    }
}
