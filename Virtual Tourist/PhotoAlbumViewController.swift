//
//  ViewController.swift
//  Virtual Tourist
//
//  Created by Fatima Aljaber on 28/01/2019.
//  Copyright © 2019 Fatima. All rights reserved.
//

import UIKit
import MapKit
import CoreData
class PhotoAlbumViewController: UIViewController,MKMapViewDelegate,UICollectionViewDelegate,UICollectionViewDataSource,NSFetchedResultsControllerDelegate {
    
    
    var dataController:DataController!
    @IBOutlet weak var Map: MKMapView!
    @IBOutlet weak var collectionViewPhotos: UICollectionView!
    var fetchedResultsController:NSFetchedResultsController<Photos>!
    var insertedIndexPaths : [IndexPath]!
    var deletedIndexPaths : [IndexPath]!
    var updatedIndexPaths : [IndexPath]!
    var lat : Double!
    var lon : Double!
    var mapData: MapData!
    var pages : Int = 1
    override func viewDidLoad() {
        super.viewDidLoad()
        Map.delegate = self
        Map.isUserInteractionEnabled = false
        collectionViewPhotos.delegate = self
        collectionViewPhotos.dataSource = self
        
        guard let mapData = mapData else {return}
        loadLocationOfPin()
        let photosCount = mapData.photos?.count
        if(photosCount! == 0){
            getImageFromFliker(Page: pages)
        }
        fetchData()
    }
    
    //_________________Reload New Data______________________//
    
    @IBAction func reloadNewData(_ sender: Any) {
        let photosStore = mapData.photos
        for photo in photosStore! {
            dataController.viewContext.delete(photo as! NSManagedObject)
        }
        try! self.dataController.viewContext.save()
        self.collectionViewPhotos.reloadData()
        getImageFromFliker(Page: pages)
        
    }
    //_________________Load Pin In The Map ______________________//
    
    func loadLocationOfPin(){
        let lat = CLLocationDegrees(self.lat!)
        let long = CLLocationDegrees(self.lon!)
        let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: long)
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        Map.addAnnotation(annotation)
        Map.isZoomEnabled = true
        Map.setCenter(coordinate, animated: true)
    }
    
    
    //_________________Download Photo From Fliker_______________________//
    
    func getImageFromFliker(Page:Int){
        let randomPage = arc4random_uniform(UInt32(Page))
        let methodParameters = [
            "method": "flickr.photos.search",
            "api_key": "0f01c52be769b236ae7646e47ccf8b36",
            "format": "json",
            "lat":"\(lat!)",
            "lon":"\(lon!)",
            "extras": "url_m",
            "nojsoncallback" : "1",
            "tags":"",
            "per_page": "15",
            "accuracy": "6",
            "page": "\(randomPage)"
        ]
        
        // reguest for photo
        let urlString = API.APIBaseURL + escapedParameters(methodParameters as [String : AnyObject])
        let request = URLRequest(url: URL(string: urlString)!)
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            
            // If there is an error
            func displayError(_ error: String) {
                print(error)
            }
            guard (error == nil) else {
                displayError("There was an error with your request: \(error!)")
                return
            }
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
                displayError("Your request returned a status code other than 2xx!")
                return
            }
            guard let data = data else {
                displayError("No data was returned by the request!")
                return
            }
            
            // let's paresd the result
            let parsedResult: [String:AnyObject]!
            do {
                parsedResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String:AnyObject]
                
                guard let photos = parsedResult["photos"] as? [String:AnyObject] else{
                    self.showAlert(withTitle: "Sorry", withMessage: "No images available.")
                    return
                }
                
                guard let photoArray = photos["photo"] as? [[String:AnyObject]] else{return}
                if photoArray.count == 0 {
                    self.showAlert(withTitle: "Sorry", withMessage: "No images available.")
                    return
                }
                self.pages = photos["pages"] as! Int
                DispatchQueue.main.async {
                    self.collectionViewPhotos.reloadData()
                }
                for photo in photoArray{
                    guard let imageUrlString = photo["url_m"] as? String else {return}
                    let imageURL = URL(string: imageUrlString)
                    if let imageData = try? Data(contentsOf: imageURL!) {
                        if let image = UIImage(data: imageData){
                            if let data = UIImagePNGRepresentation(image) {
                                let mapdata = Photos(context: self.dataController.viewContext)
                                mapdata.photo = data
                                self.mapData.addToPhotos(mapdata)
                                try! self.dataController.viewContext.save()
                                DispatchQueue.main.async {
                                    self.collectionViewPhotos.reloadData()
                                }
                            }
                        }
                    }
                }
                
            } catch {
                displayError("Could not parse the data as JSON: '\(data)'")
                return
            }
            
            if parsedResult["stat"] as? String == "ok" {return}
            else {
                displayError("Flickr API returned an error.")
            }
        }
        task.resume()
    }
    
    private func escapedParameters(_ parameters: [String:AnyObject]) -> String {
        if parameters.isEmpty {
            return ""
        } else {
            var keyValuePairs = [String]()
            
            for (key, value) in parameters {
                let stringValue = "\(value)"
                let escapedValue = stringValue.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
                keyValuePairs.append(key + "=" + "\(escapedValue!)")
            }
            return "?\(keyValuePairs.joined(separator: "&"))"
        }
    }
    
    //_________________Fetch Photo_______________________//
    
    func fetchData(){
        let fetchRequest:NSFetchRequest<Photos> = Photos.fetchRequest()
        let predicate = NSPredicate(format: "mapData == %@", mapData)
        fetchRequest.sortDescriptors = []
        fetchRequest.predicate = predicate
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        do {
            try fetchedResultsController.performFetch()
            self.collectionViewPhotos.reloadData()
        } catch {
            print("Error performing initial fetch: \(error)")
        }
    }
    

    //_________________Collection View _______________________//
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        if let count = self.fetchedResultsController.sections?.count {
            return count
        }
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let count = self.fetchedResultsController.sections?[section].numberOfObjects
        {return count}
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let photo = fetchedResultsController.object(at: indexPath)
        let cell = collectionViewPhotos.dequeueReusableCell(withReuseIdentifier: "PhotoCollectionViewCell", for: indexPath) as! PhotoCollectionViewCell
        cell.image.image = UIImage(data: photo.photo!)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let deletedPhoto = fetchedResultsController.object(at: indexPath)
        dataController.viewContext.delete(deletedPhoto)
        try! self.dataController.viewContext.save()
    }
    
    //_________________controller the flow of clloction view _______________________//
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        insertedIndexPaths = []
        deletedIndexPaths = []
        updatedIndexPaths = []
    }
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        
        switch type {
        case .insert:
            insertedIndexPaths.append(newIndexPath!)
            break
        case .delete:
            deletedIndexPaths.append(indexPath!)
            break
        case .update:
            updatedIndexPaths.append(newIndexPath!)
            break
        default:
            break
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        let indexSet = IndexSet(integer: sectionIndex)
        switch type {
        case .insert: collectionViewPhotos.insertSections(indexSet)
        case .delete: collectionViewPhotos.deleteSections(indexSet)
        case .update, .move:
            fatalError("Invalid change type in controller(_:didChange:atSectionIndex:for:). Only .insert or .delete should be possible.")
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        
        collectionViewPhotos.performBatchUpdates({() -> Void in
            
            for indexPath in self.insertedIndexPaths {
                self.collectionViewPhotos.insertItems(at: [indexPath])
            }
            
            for indexPath in self.deletedIndexPaths {
                self.collectionViewPhotos.deleteItems(at: [indexPath])
            }
            
            for indexPath in self.updatedIndexPaths {
                self.collectionViewPhotos.reloadItems(at: [indexPath])
            }
            
        }, completion: nil)
    }
}

extension UIViewController{
    
    func showAlert(withTitle title: String, withMessage message:String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default , handler: nil))
        DispatchQueue.main.async(execute: {
            self.present(alert, animated: true)
        })
    }
}





