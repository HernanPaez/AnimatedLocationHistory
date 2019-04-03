//
//  ViewController.swift
//  LocationHistoryAnimated
//
//  Created by Hernan Paez on 23/02/2019.
//  Copyright © 2019 InfinixSoft. All rights reserved.
//

import UIKit
import MapKit

class Annotation : NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D
    let imageName:String
    
    init(coordinate: CLLocationCoordinate2D, imageName:String) {
        self.coordinate = coordinate
        self.imageName = imageName
        super.init()
    }
}

class MyLine : MKPolyline {
    var timing:Double = 0
}

class MapViewAnimationDirector : NSObject {
    let mapView:MKMapView
    init(_ mapView:MKMapView) {
        self.mapView = mapView
        super.init()
        
        mapView.delegate = self
    }
    
    private var currentIndex = 0
    var coordinates = [Annotation]()
    
    func start() {
        currentIndex = 0
        guard coordinates.isEmpty == false else { return }
        animateToPoint(coordinates[currentIndex])
    }
    
    private func addPolyLine(annotation:Annotation) {
        guard currentIndex != 0 else { return }
        let lastAnnotation = coordinates[currentIndex-1]
        
        let location1 = CLLocation(latitude: lastAnnotation.coordinate.latitude, longitude: lastAnnotation.coordinate.longitude)
        let location2 = CLLocation(latitude: annotation.coordinate.latitude, longitude: annotation.coordinate.longitude)
        
        let points = getLocationArrayFrom(startLocation: location1, endLocation: location2)
        var currentPoint = location1.coordinate
        
        let time = (Double(2) / Double(points.count))
        var acumTime:Double = 0
        
        for point in points {
            let coords = [currentPoint, point]
            let line = MyLine(coordinates: coords, count: 2)
            line.timing = acumTime
            
            self.mapView.addOverlay(line)
            
            acumTime += time
            currentPoint = point
        }
    }
    
    private func animateToPoint(_ annotation:Annotation) {
        
        MKMapView
            .animate(
                withDuration: 1,
                delay: 1,
                animations: { [weak self] in
                    let span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                    let region = MKCoordinateRegion(center: annotation.coordinate, span: span)
                    self?.mapView.region = region
                },
                completion: {[weak self] finished in
                    self?.dropAnnotation(annotation)
            })
        
        self.addPolyLine(annotation: annotation)
        
    }
    
    private func dropAnnotation(_ annotation:Annotation) {
        self.mapView.addAnnotation(annotation)
    }
    
    private func handleAnimationEnd() {
        currentIndex += 1
        guard currentIndex < coordinates.count else { return }
        animateToPoint(coordinates[currentIndex])
    }
    
    //////// UTILS //////
    
    func getLocationArrayFrom(startLocation: CLLocation, endLocation: CLLocation) -> [CLLocationCoordinate2D] {
        var coordinatesArray: [CLLocationCoordinate2D] = []
        if let points = getPointsOnRoute(from: startLocation, to: endLocation, on: mapView) {
            for point in points {
                let coordinate  = point.coordinate
                coordinatesArray.append(coordinate)
            }
        }
        return coordinatesArray
    }
    
    //MARK: get cordinates from line
    func getPointsOnRoute(from: CLLocation?, to: CLLocation?, on mapView: MKMapView?) -> [CLLocation]? {
        let NUMBER_OF_PIXELS_TO_SKIP: Int = 10
        //lower number will give a more smooth animation, but will result in more layers
        var ret = [Any]()
        
        var fromPoint: CGPoint? = nil
        if let aCoordinate = from?.coordinate {
            fromPoint = mapView?.convert(aCoordinate, toPointTo: mapView)
        }
        var toPoint: CGPoint? = nil
        if let aCoordinate = to?.coordinate {
            toPoint = mapView?.convert(aCoordinate, toPointTo: mapView)
        }
        let allPixels = getAllPoints(from: fromPoint!, to: toPoint!)
        var i = 0
        while i < (allPixels?.count)! {
            let pointVal = allPixels![i] as? NSValue
            ret.append(point(toLocation: mapView, from: (pointVal?.cgPointValue)!)!)
            i += NUMBER_OF_PIXELS_TO_SKIP
        }
        ret.append(point(toLocation: mapView, from: toPoint!)!)
        return ret as? [CLLocation]
    }
    
    /**convert a CGPoint to a CLLocation according to a mapView*/
    func point(toLocation mapView: MKMapView?, from fromPoint: CGPoint) -> CLLocation? {
        let coord: CLLocationCoordinate2D? = mapView?.convert(fromPoint, toCoordinateFrom: mapView)
        return CLLocation(latitude: coord?.latitude ?? 0, longitude: coord?.longitude ?? 0)
    }
    
    func getAllPoints(from fPoint: CGPoint, to tPoint: CGPoint) -> [Any]? {
        /*Simplyfied implementation of Bresenham's line algoritme */
        var ret = [AnyHashable]()
        let deltaX: Float = fabsf(Float(tPoint.x - fPoint.x))
        let deltaY: Float = fabsf(Float(tPoint.y - fPoint.y))
        var x: Float = Float(fPoint.x)
        var y: Float = Float(fPoint.y)
        var err: Float = deltaX - deltaY
        var sx: Float = -0.5
        var sy: Float = -0.5
        if fPoint.x < tPoint.x {
            sx = 0.5
        }
        if fPoint.y < tPoint.y {
            sy = 0.5
        }
        repeat {
            ret.append(NSValue(cgPoint: CGPoint(x: CGFloat(x), y: CGFloat(y))))
            let e: Float = 2 * err
            if e > -deltaY {
                err -= deltaY
                x += sx
            }
            if e < deltaX {
                err += deltaX
                y += sy
            }
        } while round(Float(x)) != round(Float(tPoint.x)) && round(Float(y)) != round(Float(tPoint.y))
        ret.append(NSValue(cgPoint: tPoint))
        //add final point
        return ret
    }
    
}

extension MapViewAnimationDirector : MKMapViewDelegate {
    //Set the icon for every pin
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        if let annotation = annotation as? Annotation {
            let view = MKAnnotationView(annotation: annotation, reuseIdentifier: "pin")
            view.image = UIImage(named: annotation.imageName)
            view.centerOffset = CGPoint(x: 0, y: -17)
            return view
        }
        
        return nil
    }
    
    //Every Pin Dropped into the map will be animated with a 'pop' animation
    func mapView(_ mapView: MKMapView, didAdd views: [MKAnnotationView]) {
        for view in views {
            view.transform = CGAffineTransform(scaleX: 0.01, y: 0.01)
        }
        
        UIView.animate(withDuration: 1.0,
                       delay: 0,
                       usingSpringWithDamping: 0.5,
                       initialSpringVelocity: 0,
                       options: .curveEaseInOut,
                       animations: {
                        
                        for view in views {
                            view.transform = CGAffineTransform.identity
                        }
                        
        }, completion: { [weak self] finished in
            self?.handleAnimationEnd()
        })
        
    }
    
    //The lines must be animated by using a simple timer. It's not nice, but it works
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer
    {
        if let overlay = overlay as? MyLine {
            let polylineRenderer = MKPolylineRenderer(overlay: overlay)
            polylineRenderer.strokeColor = UIColor.lightGray
            polylineRenderer.lineWidth = 5
            
            if overlay.timing != 0 {
                polylineRenderer.alpha = 0
                DispatchQueue.main.asyncAfter(deadline: .now() + overlay.timing) {
                    polylineRenderer.alpha = 1
                    overlay.timing = 0
                }
            }
            
            return polylineRenderer
        }
        
        fatalError()
        
    }
}

class ViewController: UIViewController {
    @IBOutlet weak var mapView: MKMapView!
    
    lazy var coordinates:[Annotation] = {
        let start = CLLocationCoordinate2D(latitude: -34.617863, longitude: -58.789541)
        let coordinates = CLLocationCoordinate2D.getMockLocationsFor(location: start, itemCount: 10)
        let images = ["marker-1", "marker-2", "marker-3", "marker-4", "marker-5", "marker-6"]
        return coordinates.map({ (coord) -> Annotation in
            let idx = arc4random_uniform(UInt32(images.count))
            return Annotation(coordinate: coord, imageName: images[Int(idx)])
        })
    }()
    
    lazy var director : MapViewAnimationDirector = {
        return MapViewAnimationDirector(mapView)
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //        for coordinate in coordinates {
        //            let annotation = Annotation(coordinate)
        //            mapView.addAnnotation(annotation)
        //        }
        
        director.coordinates = coordinates
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.director.start()
        }
    }
    
    
}

