//
//  DescriptionViewController.swift
//  FinalDEVChallenge2022
//

import UIKit

final class DescriptionViewController: UIViewController {

    @IBOutlet private weak var myTextView: UITextView!
    @IBOutlet private weak var testTextView: UITextView!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTap)))

        setupContent()
    }

    private func getMyLightning() -> [Lightning] {
        UserDefaults.user.object([Lightning].self, with: .sensorLightning) ?? []
    }

    private func setupContent() {
        if let pathNames = Bundle.main.path(forResource: "test_data", ofType: "json") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: pathNames), options: [])
                if let myJsonString = NSString(data: data, encoding: String.Encoding.utf8.rawValue) as? String {
                    testTextView.text = myJsonString
                }
            } catch { }
        }

        let items = getMyLightning()
        let encoder = JSONEncoder()
        if let myData = try? encoder.encode(items),
           let string = NSString(data: myData, encoding: String.Encoding.utf8.rawValue) as? String {
            myTextView.text = string
        }
    }

    @objc func handleTap() {
        view.endEditing(true)
    }
}


