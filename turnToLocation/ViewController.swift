//
//  ViewController.swift
//  turnToLocation
//

import UIKit
import CoreLocation

class ViewController: UIViewController {
    
    // MARK: - outlets
    @IBOutlet weak var knob: UIImageView!
    @IBOutlet var locationButtons: [UIButton]!
    @IBOutlet weak var metersLabel: UILabel!
    
    // MARK: - members
    struct geoData {
        var name:String;
        var lat:Double;
        var lng:Double;
    }
    
    var manager:CLLocationManager = CLLocationManager()
    var currentLocation:geoData = geoData(name: "Rome", lat: 41.8919300, lng: 12.5113300)
    var direction:Int = 0
    var started:Bool = false
    var geoAngle:Double = 0.0
    var lastMeters:Double = 0.0
    
    var data:[geoData] = [
        geoData(name: "Rome", lat: 41.8919300, lng: 12.5113300),
        geoData(name: "Moscow", lat: 55.751244, lng: 37.618423),
        geoData(name: "New York", lat: 40.730610, lng: -73.935242),
        geoData(name: "Mecca", lat: 21.4225000, lng: 39.8261111),
        geoData(name: "Johannesburg", lat: -26.195246, lng: 28.034088),
        geoData(name: "Reykjavik", lat: 64.128288, lng: -21.926638)
    ]
    
    // MARK: - action for members collection
    @IBAction func onButtonTapped(_ sender: UIButton) {
        
        // buttons are tagged 0..5
        self.direction = sender.tag
        
        let buttons = locationButtons.count
        
        // if reduction  :-)
        for i in 0 ..< buttons  {
            locationButtons[i].isSelected = locationButtons[i].tag == sender.tag
        }
        
    }
    
    // MARK: dids
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        manager = CLLocationManager()
        manager.requestWhenInUseAuthorization();
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.requestAlwaysAuthorization()
        manager.startUpdatingLocation()
        manager.startUpdatingHeading()
        
        locationButtons[0].isSelected = true
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - various calculations functions
    
    // converts degrees to radians
    func degreesToRadians(_ degrees:Double)->Double{
        return degrees * .pi / 180.0
    }
    
    // unused, converts radians to degrees
    func radiansToDegrees (_ radians: Double)->Double {
        return radians * 180 / .pi
    }
    
    // cfr. http://www.movable-type.co.uk/scripts/latlong.html
    func getRadiansBearing(_ direction:Int)->Double{
        
        let lat1 = degreesToRadians(currentLocation.lat)
        let lon1 = degreesToRadians(currentLocation.lng)
        
        let lat2 = degreesToRadians(data[direction].lat)
        let lon2 = degreesToRadians(data[direction].lng)
        
        let dLon = lon2 - lon1;
        
        let y = sin(dLon)*cos(lat2)
        let x = cos(lat1)*sin(lat2)-sin(lat1)*cos(lat2)*cos(dLon)
        
        var radiansBearing = atan2(y, x);
        
        if(radiansBearing < 0.0)
        {
            radiansBearing = radiansBearing+2 * .pi
        }
        
        return radiansBearing
        
    }
    
    // calculates metric distance from a point to another
    func getMetricDistance(_ deviceLat:Double,deviceLon:Double,destinationLat:Double,destinationLon:Double) -> CLLocationDistance {
        
        let deviceLoc = CLLocation(latitude: deviceLat, longitude: deviceLon)
        let destinationLoc = CLLocation(latitude: destinationLat, longitude: destinationLon)
        
        return deviceLoc.distance(from: destinationLoc)
    }

}

// MARK: - ViewController extension
// moved CLLocationManager delegate to extension, needs review
extension ViewController:CLLocationManagerDelegate{
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]){
        
        guard let location = locations.last else {
            return;
        }
        
        currentLocation.lat = location.coordinate.latitude
        currentLocation.lng = location.coordinate.longitude
        
        geoAngle = getRadiansBearing(self.direction)
        
        let meters = getMetricDistance(location.coordinate.latitude,deviceLon: location.coordinate.longitude,destinationLat: self.data[self.direction].lat,destinationLon: self.data[self.direction].lng)
        
        self.metersLabel.text = "\(round(meters)) meters"
        
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        
        if CLLocationManager.locationServicesEnabled() {
            
            switch(CLLocationManager.authorizationStatus()) {
                
            // check if services were disallowed for this app
            case .restricted, .denied:
                print("No access")
                
            // check if services are allowed for this app
            case .authorizedAlways, .authorizedWhenInUse:
                print("Ok!")
                
            // check if we should ask for access
            case .notDetermined:
                print("Ask for access...")
                manager.requestAlwaysAuthorization()
            }
            
            guard let m = manager.location else {
                print("error");
                return
            }
            
            currentLocation.lat = m.coordinate.latitude
            currentLocation.lng = m.coordinate.longitude
            
            let meters = getMetricDistance(currentLocation.lat,deviceLon: currentLocation.lng,destinationLat: self.data[self.direction].lat,destinationLon: self.data[self.direction].lng)
            
            self.metersLabel.text = "\(round(meters)) meters"
            
            let direction = CGFloat(-newHeading.trueHeading)
            
            UIView.animate(withDuration: 2.0, animations: {
                
                self.knob.transform = CGAffineTransform(rotationAngle: (direction * CGFloat(Double.pi) / 180) + CGFloat(self.geoAngle))
            })
            
        
        }
        
    }

}
