//
//  MainViewController.swift
//  RaderViewFromOtherProject
//
//  Created by Apinun Wongintawang on 8/8/17.
//  Copyright © 2017 Apinun Wongintawang. All rights reserved.
//

import UIKit
import CoreLocation
import CoreMotion

class MainViewController: UIViewController {
    let kFilteringFactor = 0.05

    //#define M_2PI 2.0 * M_PI
    let BOX_WIDTH = 150
    let BOX_HEIGHT = 100
    let BOX_GAP = 10
    let ADJUST_BY = 30
    let DISTANCE_FILTER = 2.0
    let HEADING_FILTER = 1.0
    let INTERVAL_UPDATE = 0.75
    let SCALE_FACTOR = 1.0
    let HEADING_NOT_SET = -1.0
    let DEGREE_TO_UPDATE = 1
    
    var locationManager: CLLocationManager?
    var accelerometerManager : CMMotionManager?
    var centerCoordinate: ARCoordinate?
    var latestHeading: Double = 0.0
    var degreeRange: Double = 0.0
    
    var viewAngle: Double = 0.0
    var prevHeading: Double = 0.0
    var cameraOrientation: Int = 0
    var radarRange : Double! = 50.0
    
    weak var delegate: ARDelegate?
    var showsRadar : Bool! = true
    var coordinates :[ARGeoCoordinate]! = []
    var pois : [ARGeoCoordinate]! = []

    @IBOutlet weak var containRadarView : UIView!
    var radarView : Radar! = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        radarView = Radar.init(frame: CGRect.init(x: 0, y: 0, width: self.containRadarView.frame.width, height: self.containRadarView.frame.height))
        coordinates.append(ARGeoCoordinate.init(location: CLLocation.init(latitude: 13.760259, longitude: 100.565423), locationTitle: "title1"))
        coordinates.append(ARGeoCoordinate.init(location: CLLocation.init(latitude: 13.761285, longitude: 100.541752), locationTitle: "title2"))
        coordinates.append(ARGeoCoordinate.init(location: CLLocation.init(latitude: 13.763038, longitude: 100.543548), locationTitle: "title3"))
        radarView.pois = coordinates
        self.containRadarView.addSubview(radarView)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.deviceOrientationDidChange), name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
        
        self.startListening()

        // Do any additional setup after loading the view.
    }
    
    func deviceOrientationDidChange() {
        prevHeading = HEADING_NOT_SET
        self.currentDeviceOrientation()
    }
    
    func currentDeviceOrientation() {
        let orientation: UIDeviceOrientation = UIDevice.current.orientation
        if orientation != .unknown && orientation != .faceUp && orientation != .faceDown {
            switch orientation {
            case .landscapeLeft:
                cameraOrientation = UIDeviceOrientation.landscapeRight.rawValue
            case .landscapeRight:
                cameraOrientation = UIDeviceOrientation.landscapeLeft.rawValue
            case .portraitUpsideDown:
                cameraOrientation = UIDeviceOrientation.portraitUpsideDown.rawValue
            case .portrait:
                cameraOrientation = UIDeviceOrientation.portrait.rawValue
            default:
                break
            }
        }
    }

    
    func degreesToRadian(x: Double) -> Double {
        return Double.pi * (x) / 180.0
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func startListening() {
        // start our heading readings and our accelerometer readings.
        if locationManager == nil {
            let newLocationManager = CLLocationManager()
            newLocationManager.headingFilter = HEADING_FILTER
            newLocationManager.distanceFilter = DISTANCE_FILTER
            newLocationManager.desiredAccuracy = kCLLocationAccuracyBest
            newLocationManager.startUpdatingHeading()
            newLocationManager.startUpdatingLocation()
            newLocationManager.requestAlwaysAuthorization()
            newLocationManager.delegate = self
            self.locationManager = newLocationManager
        }
        
        if accelerometerManager == nil {
            
            accelerometerManager = CMMotionManager.init()
            accelerometerManager?.startAccelerometerUpdates()
            accelerometerManager?.accelerometerUpdateInterval = INTERVAL_UPDATE
        }
        
        if centerCoordinate == nil{
            centerCoordinate = ARCoordinate(radialDistance: 1.0, inclination: 0, azimuth: 0)
        }

    }
    
    func stopListening() {
        UIDevice.current.endGeneratingDeviceOrientationNotifications()
        NotificationCenter.default.removeObserver(self)
        if self.locationManager != nil {
            locationManager?.delegate = nil
        }
        if self.accelerometerManager != nil {
            accelerometerManager?.stopAccelerometerUpdates()
        }
    }
}

extension MainViewController : CLLocationManagerDelegate{
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        //update accellometer
        if let accelerometerData = accelerometerManager?.accelerometerData{
            print(accelerometerData.acceleration.x)
            print(accelerometerData.acceleration.y)
            print(accelerometerData.acceleration.z)
        }
        
        self.setCenter(locations[0])
        self.delegate?.didUpdate(locations[0])
    }
    
    func setCenter(_ newLocation: CLLocation) {
//        self.centerLocation = newLocation
        for index in 0..<coordinates.count {
            let geoLocation: ARGeoCoordinate! = coordinates[index]
            let distance = newLocation.distance(from: geoLocation.geoLocation)
            coordinates[index].radialDistance = distance
            print("distance : ",distance)
        }
        
        self.updateCenterCoordinate()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        latestHeading = degreesToRadian(x: newHeading.magneticHeading)
        //Let's only update the Center Coordinate when we have adjusted by more than X degrees
        
        if self.showsRadar == true {
            var gradToRotate: Int = Int(newHeading.magneticHeading - 90.0 - 22.5)
            if UIDevice.current.orientation == .landscapeLeft {
                gradToRotate += 90
            }
            if UIDevice.current.orientation == .landscapeRight {
                gradToRotate -= 90
            }
            if gradToRotate < 0 {
                gradToRotate = 360 + gradToRotate
            }
            
            print("gradToRotate : ",gradToRotate)
            
            for index in 0..<radarView.pois.count{
                if let item = radarView.pois[index] as? ARGeoCoordinate{
                    print("degree to radian : ",degreesToRadian(x: Double(gradToRotate)))
                    item.azimuth = degreesToRadian(x: Double(gradToRotate))
                    radarView.pois[index] = item
                }
            }
            
            radarView.setNeedsDisplay()
//            radarViewPort.referenceAngle = gradToRotate
//            radarViewPort.setNeedsDisplay()
        }

    }
    
    func updateCenterCoordinate() {
        var adjustment: Double = 0
        switch cameraOrientation {
        case UIDeviceOrientation.landscapeLeft.rawValue:
            adjustment = degreesToRadian(x: 270.0)
        case UIDeviceOrientation.landscapeRight.rawValue:
            adjustment = degreesToRadian(x: 90)
        case UIDeviceOrientation.portraitUpsideDown.rawValue:
            adjustment = degreesToRadian(x: 180)
        default:
            adjustment = 0
        }
        
        self.centerCoordinate!.azimuth = latestHeading - adjustment
        
        updateLocations()
    }
    
    
    
    func updateLocations() {
        var radarPointValues = [ARGeoCoordinate]() /* capacity: coordinates.count() */
        for item: ARGeoCoordinate in self.coordinates {
//            item.azimuth = self.centerCoordinate!.azimuth
            radarPointValues.append(item)
        }
        
        if self.showsRadar == true{
            self.radarView.pois     = radarPointValues
            self.radarView.radius    = Float(radarRange)
            print(self.radarView.radius)
            self.radarView.setNeedsDisplay()
        }
    }

}

