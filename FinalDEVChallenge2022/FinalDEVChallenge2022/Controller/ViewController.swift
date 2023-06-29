//
//  ViewController.swift
//  FinalDEVChallenge2022
//
//

import UIKit
import CoreLocation
import MapKit

final class ViewController: UIViewController {

    private enum LightningState: String {
        case on, off
    }

    @IBOutlet private weak var mapView: MKMapView! {
        didSet {
            mapView.delegate = self
        }
    }

    @IBOutlet private weak var lightningListenView: UIView! {
        didSet {
            lightningListenView.isHidden = true
        }
    }

    @IBOutlet private weak var backgroundView: UIView! {
        didSet {
            backgroundView.layer.cornerRadius = 93
        }
    }

    @IBOutlet private weak var descriptionMapView: UIView! {
        didSet {
            descriptionMapView.isHidden = true
            descriptionMapView.layer.cornerRadius = 24
        }
    }

    @IBOutlet private weak var descriptionMapViewAddress: UILabel!
    @IBOutlet private weak var descriptionMapViewDate: UILabel!
    @IBOutlet private weak var descriptionMapViewDistance: UILabel!
    @IBOutlet private weak var descriptionMapViewDb: UILabel!

    private let locationManager = CLLocationManager()
    private let audioRecorderService: AudioRecorderProtocol = AudioRecorderService()

    private var levelTimer = Timer()
    private var currentLocation: CLLocationCoordinate2D?
    private var db: String?
    private var isLightningListen = false

    private let switchLightningListenControl: UISwitch = {
        let switchControl = UISwitch()
        switchControl.translatesAutoresizingMaskIntoConstraints = false
        switchControl.isOn = false
        return switchControl
    }()

    private lazy var clusterManager: ClusterManager = { [unowned self] in
        let manager = ClusterManager()
        manager.delegate = self
        manager.maxZoomLevel = 17
        manager.minCountForClustering = 3
        manager.clusterPosition = .nearCenter
        return manager
    }()

    private lazy var sensorID: String = {
        if let id = UserDefaults.user.string(for: .sensorID) {
            return id
        }
        let uuid = UUID().uuidString
        UserDefaults.user[.sensorID] = uuid
        return uuid
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        configureNavigationBarButtons()

        switchLightningListenControl.addTarget(self, action: #selector(switchValueDidChange), for: .valueChanged)

        configureAnnotation(.start)

        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()

        audioRecorderService.configure()

        levelTimer = Timer.scheduledTimer(timeInterval: 0.1,
                                          target: self,
                                          selector: #selector(levelTimerCallback),
                                          userInfo: nil,
                                          repeats: true)

    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        configureNavigationBar()
    }

    private func configureNavigationBar() {
        let appearance = UINavigationBarAppearance()
        appearance.backgroundColor = UIColor(rgb: 0x26221F)
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]

        navigationController?.navigationBar.tintColor = .white
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.compactAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
    }

    private func configureNavigationBarButtons() {
        navigationItem.title = navigationItemTitle(.off)
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: switchLightningListenControl)
        let infoButton = UIButton(frame: CGRect(x: 0, y: 0, width: 25, height: 25))
        infoButton.setImage(UIImage(named: "icInfoCircle"), for: .normal)
        infoButton.addTarget(self, action: #selector(infoButtonAction), for: .touchUpInside)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: infoButton)
    }

    private func navigationItemTitle(_ lightning: LightningState) -> String {
        "Lightning listening is \(lightning.rawValue)"
    }

    @objc private func switchValueDidChange(sender: UISwitch) {
        descriptionMapView.isHidden = true
        if sender.isOn {
            isLightningListen = true
            lightningListenView.isHidden = false
            navigationItem.title = navigationItemTitle(.on)
        } else {
            isLightningListen = false
            lightningListenView.isHidden = true
            navigationItem.title = navigationItemTitle(.off)
        }
    }

    @objc private func infoButtonAction () {
        let viewController: UIViewController = UIStoryboard(name: "Description", bundle: nil).instantiateViewController(withIdentifier: "DescriptionViewController") as! DescriptionViewController
        navigationController?.pushViewController(viewController, animated: true)
    }

    @objc private func levelTimerCallback() {
        audioRecorderService.updateMeters()
        if audioRecorderService.isLoud, isLightningListen {
            switchLightningListenControl.isOn = false
            isLightningListen = false
            lightningListenView.isHidden = true
            navigationItem.title = navigationItemTitle(.off)
            db = String(120 - abs(audioRecorderService.level))
            let model = Lightning(sensorID: sensorID,
                                  lat: currentLocation?.latitude ?? 0,
                                  lon: currentLocation?.longitude ?? 0,
                                  timestamp: Date().timeIntervalSince1970,
                                  eventID: UUID().uuidString,
                                  db: db)
            if var array = UserDefaults.user.object([Lightning].self, with: .sensorLightning) {
                array.append(model)
                UserDefaults.user.set(object: array, forKey: .sensorLightning)
            } else {
                UserDefaults.user.set(object: [model], forKey: .sensorLightning)
            }
            descriptionMapView.isHidden = true
            configureAnnotation(.point)
        }
    }
}

extension ViewController {

    private enum Zoom {
        case start, point
    }

    private func configureAnnotation(_ zoom: Zoom) {
        var annotations = getTestAnnotation()
        annotations += getMyAnnotation()
        clusterManager.removeAll()
        clusterManager.add(annotations)
        clusterManager.reload(mapView: mapView) { [weak mapView] _ in
            switch zoom {
            case.start:
                mapView?.fitAll(annotations)
            case .point:
                if let annotation = annotations.last {
                    let annotationPoint = MKMapPoint(annotation.coordinate)
                    let pointRect = MKMapRect(x: annotationPoint.x,
                                              y: annotationPoint.y,
                                              width: 0,
                                              height: 0)
                    mapView?.setVisibleMapRect(pointRect, animated: true)
                }
            }
        }
    }

    private func getTestAnnotation() -> [Annotation] {
        getTestLightning().map { Annotation(lightning: $0) }
    }

    private func getTestLightning() -> [Lightning] {
        if let pathNames = Bundle.main.path(forResource: "test_data", ofType: "json") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: pathNames), options: [])
                if let eventsJSON = try? JSONDecoder().decode(LightningResult.self, from: data) {
                    return eventsJSON
                } else {
                    return []
                }
            } catch {
                return []
            }
        }
        return []
    }

    private func getMyAnnotation() -> [Annotation] {
        if let array = UserDefaults.user.object([Lightning].self, with: .sensorLightning) {
            return array.map { Annotation(lightning: $0) }
        }
        return []
    }
}

extension ViewController: MKMapViewDelegate {

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if let annotation = annotation as? ClusterAnnotation {
            let identifier = "Cluster\(0)"
            let selection = Selection(rawValue: 0)!
            return mapView.annotationView(selection: selection, annotation: annotation, reuseIdentifier: identifier)
        } else if let annotation = annotation as? MeAnnotation {
            let identifier = "Me"
            let annotationView = mapView.annotationView(of: MKAnnotationView.self, annotation: annotation, reuseIdentifier: identifier)
            annotationView.image = .me
            return annotationView
        } else {
            let identifier = "Pin"
            let annotationView = mapView.annotationView(of: MKAnnotationView.self, annotation: annotation, reuseIdentifier: identifier)
            annotationView.image = UIImage(named: "icPin")
            return annotationView
        }
    }

    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        clusterManager.reload(mapView: mapView)
    }

    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        guard let annotation = view.annotation else { return }

        if let cluster = annotation as? ClusterAnnotation {
            descriptionMapView.isHidden = true
            var zoomRect = MKMapRect.null
            for annotation in cluster.annotations {
                let annotationPoint = MKMapPoint(annotation.coordinate)
                let pointRect = MKMapRect(x: annotationPoint.x,
                                          y: annotationPoint.y,
                                          width: 0,
                                          height: 0)
                zoomRect = zoomRect.isNull ? pointRect : zoomRect.union(pointRect)
            }
            mapView.setVisibleMapRect(zoomRect, animated: true)
        } else if let pin = annotation as? Annotation {
            descriptionMapView.isHidden = false
            descriptionMapViewDate.text = DateFormatter.shotFormatter.string(from: Date(timeIntervalSince1970: pin.lightning.timestamp) as Date)

            if let currentLocation = currentLocation {
                // Measuring my distance to my buddy's (in km)
                let distance = currentLocation.distance(from: pin.coordinate) / 1000
                descriptionMapViewDistance.text = String(format: "%.01fkm from your location", distance)
            }
            if let db = pin.lightning?.db {
                descriptionMapViewDb.text = db + " dB"
            }

            let address = CLGeocoder()
            address.reverseGeocodeLocation(CLLocation(latitude: pin.lightning.lat,
                                                      longitude: pin.lightning.lon)) { [weak descriptionMapViewAddress] places, error in
                guard error == nil, let place = places?.first else {
                    return
                }
                descriptionMapViewAddress?.text = place.name
            }
        }

    }

    func mapView(_ mapView: MKMapView, didAdd views: [MKAnnotationView]) {
        views.forEach { $0.alpha = 0 }
        UIView.animate(withDuration: 0.35,
                       delay: 0,
                       usingSpringWithDamping: 1,
                       initialSpringVelocity: 0,
                       options: [],
                       animations: {
            views.forEach { $0.alpha = 1 }
        }, completion: nil)
    }
}

extension ViewController: ClusterManagerDelegate {

    func cellSize(for zoomLevel: Double) -> Double? {
        nil
    }

    func shouldClusterAnnotation(_ annotation: MKAnnotation) -> Bool {
        !(annotation is MeAnnotation)
    }
}

extension ViewController {
    enum Selection: Int {
        case count, imageCount, image
    }
}

extension MKMapView {
    func annotationView(selection: ViewController.Selection, annotation: MKAnnotation?, reuseIdentifier: String) -> MKAnnotationView {
        switch selection {
        case .count:
            let annotationView = annotationView(of: CountClusterAnnotationView.self,
                                                annotation: annotation,
                                                reuseIdentifier: reuseIdentifier)
            annotationView.countLabel.backgroundColor = .red
            return annotationView
        case .imageCount:
            let annotationView = annotationView(of: ImageCountClusterAnnotationView.self,
                                                annotation: annotation,
                                                reuseIdentifier: reuseIdentifier)
            annotationView.countLabel.textColor = .red
            return annotationView
        case .image:
            let annotationView = annotationView(of: MKAnnotationView.self,
                                                annotation: annotation,
                                                reuseIdentifier: reuseIdentifier)
            return annotationView
        }
    }
}

final class MeAnnotation: Annotation {}


extension ViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            let latitude = location.coordinate.latitude
            let longitude = location.coordinate.longitude
            currentLocation = .init(latitude: latitude, longitude: longitude)
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        debugPrint(error)
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse {
            debugPrint("User allowed us to access location")
        }
    }
}
