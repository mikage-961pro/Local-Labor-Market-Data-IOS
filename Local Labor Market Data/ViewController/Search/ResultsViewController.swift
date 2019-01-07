//
//  ResultsViewController.swift
//  Local Labor Market Data
//
//  Created by Nidhi Chawla on 7/27/18.
//  Copyright © 2018 Department of Labor. All rights reserved.
//

import UIKit

class ResultsViewController: UIViewController {

    var currentArea: Area?
    
    var sections : [(rowIndex: Int, title: String)] = Array()
    var resultAreas: [Area]? {
        didSet {
            sections.removeAll()
            guard let areas = resultAreas else {return}
            var prevPrefix = ""
            for (index, area) in (areas.enumerated()) {
                let title = area.title ?? ""
                let nextPrefix = String(title[title.startIndex])
                
                if nextPrefix != prevPrefix {
                    let newSection = (rowIndex: index, title: nextPrefix)
                    sections.append(newSection)
                    prevPrefix = nextPrefix
                }
            }
            
            if (tableView != nil) {
                tableView.reloadData()
            }
        }
    }

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        setupView()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setupView() {
        titleLabel.text = currentArea?.title
        titleLabel.accessibilityLabel = currentArea?.accessibilityStr
//        titleLabel.accessibilityTraits |= UIAccessibilityTraits.header
        titleLabel.accessibilityTraits = UIAccessibilityTraits.header
        // Get the result types
        if let resultArea = resultAreas?[0] {
            title = resultArea.areaType + " Results"
        }
        
        tableView.sectionIndexColor = #colorLiteral(red: 0.1607843137, green: 0.2117647059, blue: 0.5137254902, alpha: 1)  
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

// MARK: TableView Datasource
extension ResultsViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return resultAreas?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: "ResultCell")
        let resultArea = resultAreas?[indexPath.row]
        cell.textLabel?.text = resultArea?.title
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.font = UIFont.systemFont(ofSize: 14)
        cell.indentationLevel = 4
        cell.accessibilityLabel = resultArea?.accessibilityStr
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if let resultArea = resultAreas?[0] {
            return "Select a " + resultArea.areaType
        }
        
        return ""
    }
    
    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return sections.map{ $0.title }
    }
    
    func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        
        let rowIndex = sections[index].rowIndex
        tableView.scrollToRow(at: IndexPath(row: rowIndex, section: 0), at: .top, animated: true)
        return -1
    }

}

// MARK: TableView Delegate
extension ResultsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard let selectedArea = resultAreas?[indexPath.row] else { return }
        
        let areaVC: AreaViewController
        if selectedArea is County {
            areaVC = CountyViewController.instantiateFromStoryboard()
        }
        else {
            areaVC = MetroStateViewController.instantiateFromStoryboard()
        }
        
        areaVC.area = selectedArea
        let navVC = UINavigationController(rootViewController: areaVC)
        areaVC.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
        areaVC.navigationItem.leftItemsSupplementBackButton = true
        splitViewController?.showDetailViewController(navVC, sender: nil)
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView,
                   forSection section: Int) {
        
        guard let header = view as? UITableViewHeaderFooterView else { return }
        header.textLabel?.textColor = .black
        header.textLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
    }
}


