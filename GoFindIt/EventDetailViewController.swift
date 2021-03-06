//
//  EventDetailViewController.swift
//  RatingsTest
//
//  Created by Rui Lebre on 12/28/16.
//  Copyright © 2016 Rui Lebre. All rights reserved.
//

import UIKit

var firstTime:Bool = true

class EventDetailViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate, UITableViewDataSource, UITableViewDelegate {

    var event: Event?
    var wasEditted = false
    var indexOnTable: Int?
    var caller = ""
    
    @IBOutlet weak var label_name: UILabel!
    @IBOutlet weak var label_location: UILabel!
    @IBOutlet weak var label_comp_beacons: UILabel!
    @IBOutlet weak var label_comp_date: UILabel!
    @IBOutlet weak var label_creation_date: UILabel!
    @IBOutlet weak var label_elapsed_time: UILabel!
    
    @IBOutlet weak var image_main: UIImageView!
    @IBOutlet weak var image_rating: UIImageView!
    var image_main_base64: String = ""
    
    @IBOutlet weak var buttonEditBeaconList: UIButton!
    @IBOutlet weak var beaconsList: UITableView!
    
    @IBOutlet weak var buttonStart: UIButton!
    
    let image = UIImagePickerController()
    
    
    @IBAction func buttonDonePressed(_ sender: Any) {
        if caller == "EventMap" {
            performSegue(withIdentifier: "saveEventDetailMap", sender: self)
        }else if caller == "EventTable" {
            performSegue(withIdentifier: "saveEventDetailTable", sender: self)
        }
    }
    
    
    @IBAction func buttonCancelPressed(_ sender: Any) {
        if caller == "EventMap" {
            performSegue(withIdentifier: "cancelToEventMap", sender: self)
        }else if caller == "EventTable" {
            performSegue(withIdentifier: "cancelToEventTable", sender: self)
        }
    }
    
    @IBAction func buttonStartPressed(_ sender: Any) {
        let sorted1 = (event?.beaconList)!.sorted()
        let sorted2 = (event?.completedBeacons)!.sorted()
        //print(sorted1)
        //print(sorted2)
        //        if (event?.beaconList)!.count - (event?.completedBeacons)!.count <= 0 && firstTime {
        if sorted1 == sorted2 && event?.completedDate != ""{
            let alert = UIAlertController(title: "Info", message: "You have already completed the event.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [] (_) in
                 self.buttonEditBeaconList.isEnabled = false
            }))
            self.present(alert, animated: true, completion: nil)
        } else if sorted1.count == 0 && sorted2.count == 0 {
            let alert = UIAlertController(title: "Info", message: "The event has no beacons associated.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [] (_) in
                self.buttonEditBeaconList.isEnabled = false
            }))
            self.present(alert, animated: true, completion: nil)
        } else {
            performSegue(withIdentifier: "goToStartEvent", sender: self)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        image.delegate = self
        beaconsList.delegate = self
        beaconsList.dataSource = self
        
        label_name.text = event?.name
        let locationTemp = (event?.location)?.characters.split{$0 == "!"}.map(String.init)
        if locationTemp?.count == 2 {
            label_location.text = locationTemp?[1]
        }else{
            label_location.text = locationTemp?[0]
        }
        
        label_creation_date.text = event?.addedDate
        label_comp_date.text = event?.completedBeacons.count == event?.beaconList.count ? event?.completedDate : "Go Find It!"
        label_comp_beacons.text = "\(event!.completedBeacons.count)"
        label_elapsed_time.text = "\(String(format: "%02d", event!.elapsedTime / 3600)):\(String(format: "%02d", event!.elapsedTime % 3600 / 60)):\(String(format: "%02d",(event!.elapsedTime % 3600) % 60))"
        image_rating.image = imageForRating(rating: (event!.rating))
        image_main.image = event?.mainImage
        
        let ratingTap = UITapGestureRecognizer(target: self, action: #selector(EventDetailViewController.ratingTapDetected))
        ratingTap.numberOfTapsRequired = 1
        image_rating.isUserInteractionEnabled = true
        image_rating.addGestureRecognizer(ratingTap)
        
        let mainImageTap = UITapGestureRecognizer(target: self, action: #selector(EventDetailViewController.mainImageTapDetected))
        mainImageTap.numberOfTapsRequired = 1
        image_main.isUserInteractionEnabled = true
        image_main.addGestureRecognizer(mainImageTap)
        
        createDirectory(eventID: (event?.id)!)
        
        if (event?.beaconList)!.count - (event?.completedBeacons)!.count <= 0 && event?.completedDate != ""{
            buttonEditBeaconList.isEnabled = false
            buttonStart.isEnabled = false
        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func imageForRating(rating:Int) -> UIImage? {
        var imageName = "\(rating)Stars"
        
        if rating == 0{
            imageName = "\(1)Stars"
        }
        
        return UIImage(named: imageName)
    }
    
    
    
    func ratingTapDetected() {
        wasEditted = true

        event?.rating += 1
        
        if (event?.rating)! > 5 {
            event?.rating = 1
        }
        
        image_rating.image = imageForRating(rating: (event!.rating))
    }
    
    func mainImageTapDetected() {
        wasEditted = true
        
        let alert = UIAlertController(title: "Event Image", message: "Choose from", preferredStyle: .alert)

        
        alert.addAction(UIAlertAction(title: "Photos", style: .default, handler: { (_) in
            self.imageChoser(type: "photos")
        }))

        alert.addAction(UIAlertAction(title: "Camera", style: .default, handler: { (_) in
            self.imageChoser(type: "camera")
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { (_) in
            alert.dismiss(animated: true, completion: nil)
        }))
        
        self.present(alert, animated: true, completion: nil)
    }

    func imageChoser(type: String) {
       
        switch type {
        case "photos":
            image.sourceType = UIImagePickerControllerSourceType.photoLibrary
            break
        case "camera":
            image.sourceType = UIImagePickerControllerSourceType.camera
            break
        default:
            break
        }
        
        image.allowsEditing = false
        
        present(image, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        completion:
            if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
                self.image_main.image = image
                event?.mainImage = image
            }
      
        DispatchQueue.global(qos: .background).async {
            let imageData = UIImagePNGRepresentation((self.event?.mainImage)!)! as NSData
            self.image_main_base64 = imageData.base64EncodedString(options: .lineLength64Characters)
            print("conversion done")
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "BeaconCellDetail", for: indexPath)
        //let a = (event?.beaconList[indexPath.row])! as String
        //print(a)
        let beaconPlusLocation = ((event?.beaconList[indexPath.row])! as String).characters.split{$0 == "="}.map(String.init)
        
        if beaconPlusLocation.count == 1 {
            cell.textLabel?.text = beaconPlusLocation[0]
            cell.detailTextLabel?.text = "Pick Location Please"
        }else if beaconPlusLocation.count == 2 {
            cell.textLabel?.text = beaconPlusLocation[0]
            cell.detailTextLabel?.text = beaconPlusLocation[1]
        }

        //cell.textLabel?.text = event?.beaconList[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (event?.beaconList.count)!
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == UITableViewCellEditingStyle.delete {
            event?.beaconList.remove(at: indexPath.row)
            wasEditted = true
            beaconsList.deleteRows(at: [indexPath], with: .fade)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToRegisterBeaconsFromEdit" {
            let temp = (segue.destination as! UINavigationController)
            let dest = temp.topViewController as! RegisterBeaconsTableViewController
            dest.beacons = (event?.beaconList)!
            dest.invoker = "EditViewController"
        }else if segue.identifier == "goToStartEvent" {
            let temp = (segue.destination as! UINavigationController)
            let dest = temp.topViewController as! LetsFindItViewController
            dest.event = event
        }else if segue.identifier == "goToShowPictures" {
            let temp = (segue.destination as! UINavigationController)
            let dest = temp.topViewController as! PhotosCollectionViewController
            //let dest = segue.destination as! PhotosCollectionViewController
            dest.images = (event?.photosReferences)!
            dest.eventId = (event?.id)!
        }else if segue.identifier == "goToBeaconsMap" {
            let dest = (segue.destination as! BeaconMapViewController)
            dest.event = self.event
        }
    }
    
    @IBAction func cancelToEventDetailViewController(segue:UIStoryboardSegue) {
        
    }
    
    @IBAction func saveBeaconsDetail(segue:UIStoryboardSegue) {
        if let registerBeaconsViewController = segue.source as? RegisterBeaconsTableViewController {
            
            if !registerBeaconsViewController.beacons.isEmpty{
                wasEditted=true
                event?.beaconList=registerBeaconsViewController.beacons
                beaconsList.reloadData()
            }
        }
    }
    
    @IBAction func savePhotoReferences(segue:UIStoryboardSegue) {
        if let photosCollectionViewController = segue.source as? PhotosCollectionViewController {
            
            if photosCollectionViewController.images.count != event?.photosReferences.count {
                wasEditted = true
                event?.photosReferences = photosCollectionViewController.images
            }
        }
    }
    
    @IBAction func stopEvent(segue:UIStoryboardSegue) {
        if let letsFindItViewController = segue.source as? LetsFindItViewController {
            self.event = letsFindItViewController.event
            wasEditted = true
            label_name.text = event?.name
            label_location.text = event?.location
            label_creation_date.text = event?.addedDate
            label_comp_date.text = event?.completedBeacons.count == event?.beaconList.count ? event?.completedDate : "Go Find It!"
            label_comp_beacons.text = "\(event!.completedBeacons.count)"
            label_elapsed_time.text = "\(String(format: "%02d", event!.elapsedTime / 3600)):\(String(format: "%02d", event!.elapsedTime % 3600 / 60)):\(String(format: "%02d",(event!.elapsedTime % 3600) % 60))"

            if (event?.beaconList)!.count - (event?.completedBeacons)!.count <= 0 {
                let alert = UIAlertController(title: "Info", message: "You have already completed the event.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [] (_) in
                }))
                self.present(alert, animated: true, completion: nil)

            }
        }
    }
    
    func createDirectory(eventID: String){
        let fileManager = FileManager.default
        let paths = (NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString).appendingPathComponent(eventID)
        if !fileManager.fileExists(atPath: paths){
            try! fileManager.createDirectory(atPath: paths, withIntermediateDirectories: true, attributes: nil)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        let sorted1 = (event?.beaconList)!.sorted()
        let sorted2 = (event?.completedBeacons)!.sorted()
        
        if sorted1 == sorted2 && firstTime && event?.completedDate != "" {
            let alert = UIAlertController(title: "Congratulations!", message: "You have completed event. You found it all!", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [] (_) in
 
            }))
 
            buttonEditBeaconList.isEnabled = false
            self.present(alert, animated: true, completion: nil)
            firstTime = false
            
        }
    }
}
