//
//  MapKitViewController.swift
//  DigitalImageDemonstration_Swift
//
//  Created by liubo on 2017/11/30.
//  Copyright © 2017年 devliubo. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class MapKitViewController: UIViewController, CLLocationManagerDelegate {
    
    var mapView: MKMapView!
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}

extension MapKitViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        guard !(annotation is MKUserLocation) else {
            return nil
        }
        
        let annotationIdentifier = "AnnotationIdentifier"
        var annotationView: MKAnnotationView?
        if let dequeuedAnnotationView = mapView.dequeueReusableAnnotationView(withIdentifier: annotationIdentifier) {
            annotationView = dequeuedAnnotationView
            annotationView?.annotation = annotation
        }
        else {
            annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: annotationIdentifier)
            annotationView?.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
        }
        
        if let annotationView = annotationView {
            annotationView.canShowCallout = true
        }
        
        return annotationView
    }
}
