//
//  ViewController.swift
//  MapOverlay
//
//  Created by Don Mag on 6/15/20.
//  Copyright © 2020 DonMag. All rights reserved.
//

import UIKit

import MapKit

class Lake {
	var name: String?
	var boundary: [CLLocationCoordinate2D] = []
	
	var midCoordinate = CLLocationCoordinate2D()
	var overlayTopLeftCoordinate = CLLocationCoordinate2D()
	var overlayTopRightCoordinate = CLLocationCoordinate2D()
	var overlayBottomLeftCoordinate = CLLocationCoordinate2D()
	var overlayBottomRightCoordinate: CLLocationCoordinate2D {
		return CLLocationCoordinate2D(
			latitude: overlayBottomLeftCoordinate.latitude,
			longitude: overlayTopRightCoordinate.longitude)
	}
	
	var overlayBoundingMapRect: MKMapRect {
		let topLeft = MKMapPoint(overlayTopLeftCoordinate)
		let topRight = MKMapPoint(overlayTopRightCoordinate)
		let bottomLeft = MKMapPoint(overlayBottomLeftCoordinate)
		
		return MKMapRect(
			x: topLeft.x,
			y: topLeft.y,
			width: fabs(topLeft.x - topRight.x),
			height: fabs(topLeft.y - bottomLeft.y))
	}
	
	init(filename: String) {
		guard
			let properties = Lake.plist(filename) as? [String: Any],
			let boundaryPoints = properties["boundary"] as? [String]
			else { return }
		
		midCoordinate = Lake.parseCoord(dict: properties, fieldName: "midCoord")
		overlayTopLeftCoordinate = Lake.parseCoord(
			dict: properties,
			fieldName: "overlayTopLeftCoord")
		overlayTopRightCoordinate = Lake.parseCoord(
			dict: properties,
			fieldName: "overlayTopRightCoord")
		overlayBottomLeftCoordinate = Lake.parseCoord(
			dict: properties,
			fieldName: "overlayBottomLeftCoord")
		
		let cgPoints = boundaryPoints.map { NSCoder.cgPoint(for: $0) }
		boundary = cgPoints.map { CLLocationCoordinate2D(
			latitude: CLLocationDegrees($0.x),
			longitude: CLLocationDegrees($0.y))
		}
	}
	
	static func plist(_ plist: String) -> Any? {
		guard
			let filePath = Bundle.main.path(forResource: plist, ofType: "plist"),
			let data = FileManager.default.contents(atPath: filePath)
			else { return nil }
		
		do {
			return try PropertyListSerialization.propertyList(from: data, options: [], format: nil)
		} catch {
			return nil
		}
	}
	
	static func parseCoord(dict: [String: Any], fieldName: String) -> CLLocationCoordinate2D {
		if let coord = dict[fieldName] as? String {
			let point = NSCoder.cgPoint(for: coord)
			return CLLocationCoordinate2D(
				latitude: CLLocationDegrees(point.x),
				longitude: CLLocationDegrees(point.y))
		}
		return CLLocationCoordinate2D()
	}
}


class LakeMapOverlay: NSObject, MKOverlay {
	let coordinate: CLLocationCoordinate2D
	let boundingMapRect: MKMapRect
	
	init(park: Lake) {
		boundingMapRect = park.overlayBoundingMapRect
		coordinate = park.midCoordinate
	}
}

class LakeMapOverlayView: MKOverlayRenderer {
	let overlayImage: UIImage
	
	// 1
	init(overlay: MKOverlay, overlayImage: UIImage) {
		self.overlayImage = overlayImage
		super.init(overlay: overlay)
	}
	
	// 2
	override func draw(
		_ mapRect: MKMapRect,
		zoomScale: MKZoomScale,
		in context: CGContext
	) {
		guard let imageReference = overlayImage.cgImage else { return }
		
		let rect = self.rect(for: overlay.boundingMapRect)
		context.scaleBy(x: 1.0, y: -1.0)
		context.translateBy(x: 0.0, y: -rect.size.height)
		context.draw(imageReference, in: rect)
	}
}

class ViewController: UIViewController, MKMapViewDelegate {
	
	@IBOutlet private var mapView: MKMapView!

	let lake = Lake(filename: "LakeWaubesa")

	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view.
		
		let latDelta = lake.overlayTopLeftCoordinate.latitude - lake.overlayBottomRightCoordinate.latitude
		let span = MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: 0.0)
		let region = MKCoordinateRegion(center: lake.midCoordinate, span: span)
		
		mapView.region = region;

		mapView.delegate = self
	}
	
	func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {

		guard let img = UIImage(named: "LakeWaubesa") else {
			fatalError("Could not load overlay image!")
		}
		return LakeMapOverlayView(overlay: overlay, overlayImage: img)
	}
	
	@IBAction func didTap(_ sender: Any) {
		if mapView.overlays.count > 0 {
			mapView.removeOverlays(mapView.overlays)
		} else {
			let parkMapOverlay = LakeMapOverlay(park: lake)
			mapView.addOverlay(parkMapOverlay)
		}
	}
	

}

