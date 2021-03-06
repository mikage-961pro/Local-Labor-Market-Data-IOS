//
//  CountyViewController.swift
//  Local Labor Market Data
//
//  Created by Nidhi Chawla on 7/27/18.
//  Copyright © 2018 Department of Labor. All rights reserved.
//

import UIKit


struct CountyReport {
    static let unemploymentRate = "Unemployment Rate"
    static let employmentWageTotal = "Employment & Wages"
    static let employmentWagePrivate = "Private"
    static let employmentWageFederal = "Federal Government"
    static let employmentWageState = "State Government"
    static let employmentWageLocal = "Local Government"
}

class CountyViewController: AreaViewController {
    
    var county: County {
        get {
            return area as! County
        }
    }
    lazy var activityIndicator = ActivityIndicatorView(text: "Loading", inView: view)
//    var ownershipCell: OwnershipTableViewCell?
    
    var seasonalAdjustment: SeasonalAdjustment = .notAdjusted {
        didSet {
            localAreaReportsDict.removeAll()
            nationalAreaReportsDict.removeAll()
            tableView.reloadData()
            loadReports()
        }
    }
    
    var openSectionIndex: Int = -1
    var reportSections =
        [ReportSection(title: CountyReport.unemploymentRate, collapsed: false, reportTypes: [.unemployment(measureCode: .unemploymentRate)]),
         ReportSection(title: CountyReport.employmentWageTotal, reportTypes:
            [.quarterlyEmploymentWageFrom(ownershipCode: .totalCovered, dataType: .allEmployees),
             .quarterlyEmploymentWageFrom(ownershipCode: .totalCovered, dataType: .avgWeeklyWage)],
                 children: [
                ReportSection(title: CountyReport.employmentWagePrivate, reportTypes:
                    [.quarterlyEmploymentWageFrom(ownershipCode: .privateOwnership, dataType: .allEmployees),
                     .quarterlyEmploymentWageFrom(ownershipCode: .privateOwnership, dataType: .avgWeeklyWage)]),
                ReportSection(title: CountyReport.employmentWageFederal, reportTypes:
                    [.quarterlyEmploymentWageFrom(ownershipCode: .federalGovt, dataType: .allEmployees),
                     .quarterlyEmploymentWageFrom(ownershipCode: .federalGovt, dataType: .avgWeeklyWage)]),
                ReportSection(title: CountyReport.employmentWageState, reportTypes:
                    [.quarterlyEmploymentWageFrom(ownershipCode: .stateGovt, dataType: .allEmployees),
                     .quarterlyEmploymentWageFrom(ownershipCode: .stateGovt, dataType: .avgWeeklyWage)]),
                ReportSection(title: CountyReport.employmentWageLocal, reportTypes:
                    [.quarterlyEmploymentWageFrom(ownershipCode: .localGovt, dataType: .allEmployees),
                     .quarterlyEmploymentWageFrom(ownershipCode: .localGovt, dataType: .avgWeeklyWage)])]
            )]
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        setupView()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    override func setupView() {
        super.setupView()
        title = "County"

        rightSubArea.setTitle("Metro", for: .normal)
        leftSubArea.setTitle("State", for: .normal)
        
        tableView.register(UINib(nibName: UnEmploymentRateTableViewCell.nibName, bundle: nil), forCellReuseIdentifier: UnEmploymentRateTableViewCell.reuseIdentifier)
        tableView.register(UINib(nibName: EmploymentWageTableViewCell.nibName, bundle: nil), forCellReuseIdentifier: EmploymentWageTableViewCell.reuseIdentifier)
        tableView.register(UINib(nibName: OwnershipTableViewCell.nibName, bundle: nil), forCellReuseIdentifier: OwnershipTableViewCell.reuseIdentifier)

        tableView.estimatedRowHeight = 230
        tableView.rowHeight = UITableView.automaticDimension
        
        tableView.register(UINib(nibName: AreaSectionHeaderView.nibName, bundle: nil), forHeaderFooterViewReuseIdentifier: AreaSectionHeaderView.reuseIdentifier)
        tableView.sectionHeaderHeight = UITableView.automaticDimension;
        tableView.estimatedSectionHeaderHeight = 44
        
        tableView.register(UINib(nibName: AreaSectionFooterView.nibName, bundle: nil), forHeaderFooterViewReuseIdentifier: AreaSectionFooterView.reuseIdentifier)
        tableView.sectionFooterHeight = UITableView.automaticDimension;
        tableView.estimatedSectionFooterHeight = 44
        
        seasonallyAdjustedSwitch.isOn = (seasonalAdjustment == .adjusted) ? true:false

        setupAccessbility()
        loadReports()
    }
    
    override func setupAccessbility() {
        super.setupAccessbility()
        leftSubArea.accessibilityHint = "Tap to View State Report for County"
        rightSubArea.accessibilityHint = "Tap to View Metro Report for County"
    }

    // MARK: Actions
    
    @IBAction func seasonallyAdjustClick(_ sender: Any) {
        seasonalAdjustment = seasonallyAdjustedSwitch.isOn ? .adjusted : .notAdjusted
    }
    
    @IBAction func leftSubAreaClicked(_ sender: Any) {
        displayStates()
    }

    @IBAction func rightSubAreaClicked(_ sender: Any) {
        displayMetros()
    }

    func displayStates() {
        guard let state = county.getState() else { return }
        
        let stateVC = MetroStateViewController.instantiateFromStoryboard()
        stateVC.area = state
        displayAreaViewController(vc: stateVC)
    }
    
    func displayMetros() {
        guard let metros = county.getMetros() else { return }
        
        if metros.count > 1 {
            let resultsVC = ResultsViewController.instantiateFromStoryboard()
            resultsVC.currentArea = county
            resultsVC.resultAreas = metros
            
            navigationController?.pushViewController(resultsVC, animated: true)
        }
        else if metros.count == 1 {
            let metroVC = MetroStateViewController.instantiateFromStoryboard()
            metroVC.area = metros[0]
            displayAreaViewController(vc: metroVC)
        }
        else {
            displayError(message: "This county is not a part of a Metropolitan Statistical Area.", title: "")
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        // Display History
        if segue.identifier == "showHistory" {
            if let destVC = segue.destination as? HistoryViewController,
                let reportType = sender as? ReportType {
                
                if let localAreaReport = localAreaReportsDict[reportType] {
                    let nationalAreaReport = nationalAreaReportsDict[reportType]
                        
                    let viewModel = HistoryViewModel(area: county,
                                                     localAreaReport: localAreaReport, nationalAreaReport: nationalAreaReport, seasonalAdjustment: seasonalAdjustment)
                    destVC.viewModel = viewModel
                }
            }
        }
        else if segue.identifier == "showIndustries" {
            if let destVC = segue.destination as? ItemViewController,
                let reportType = sender as? ReportType {
//                var latestYear: String = ""
//                let localAreaReport = localAreaReportsDict[reportType]
//                if let latestData = localAreaReport?.seriesReport?.latestData() {
//                    latestYear = latestData.year
//                }
                var ownershipCode = QCEWReport.OwnershipCode.privateOwnership
                if case .quarterlyEmploymentWage(let ownership, _, _, _) = reportType {
                    ownershipCode = ownership
                }
                let viewModel = QCEWIndustryViewModel(area: area, parent: nil, ownershipCode: ownershipCode)
                destVC.viewModel = viewModel
                destVC.title = "Industry - Sectors"
            }
        }
    }
}



// Load Reports
extension CountyViewController {
    
    func loadReports() {
        loadLocalReports()
    }
    
    func loadLocalReports() {
        loadLocalUnemploymentReport()
        loadLocalQuarterlyReport()
    }
    
    func loadLocalUnemploymentReport() {
        guard let unEmploymentSection =
            (reportSections.filter{ $0.title == CountyReport.unemploymentRate }.first) else {return}
        
        guard let reportTypes = unEmploymentSection.allReportTypes() else { return}
        
        activityIndicator.startAnimating(disableUI: true)
        ReportManager.getReports(forArea: county, reportTypes: reportTypes,
                                 seasonalAdjustment: seasonalAdjustment) {
            [weak self] (apiResult) in
            guard let strongSelf = self else {return}
            strongSelf.activityIndicator.stopAnimating()

            switch apiResult {
            case .success(let areaReportsDict):
                strongSelf.displayLocalReportResults(areaReportsDict: areaReportsDict)
            case .failure(let error):
                print(error.localizedDescription)
                strongSelf.handleError(error: error)
            }
        }
    }
    
    func loadLocalQuarterlyReport() {
        guard let employmentSection =
            (reportSections.filter{ $0.title == CountyReport.employmentWageTotal }.first) else {return}
        
        guard let reportTypes = employmentSection.allReportTypes() else { return}

        //Quarterly report with latest, returns annual Data, since we want quarterly data,
        // Get report for Current year and last year, since quartely data may not be available
        // for current year
//        let today = Date()
//        let endYear = Calendar.current.component(.year, from: today)
        activityIndicator.startAnimating()
//        ReportManager.getReports(forArea: county, reportTypes: reportTypes,
//                                 seasonalAdjustment: seasonalAdjustment,startYear: String(endYear-1), endYear: String(endYear)) {
        ReportManager.getReports(forArea: county, reportTypes: reportTypes,
                                 seasonalAdjustment: seasonalAdjustment) {
                [weak self] (apiResult) in
                guard let strongSelf = self else {return}
                strongSelf.activityIndicator.stopAnimating()
                switch apiResult {
                case .success(let areaReportsDict):
                    strongSelf.displayLocalReportResults(areaReportsDict: areaReportsDict)
                case .failure(let error):
                    print(error)
                }
        }
    }

    func displayLocalReportResults(areaReportsDict: [ReportType: AreaReport]) {
        localAreaReportsDict = localAreaReportsDict + areaReportsDict
        
        loadNationalReport(areaReportsDict: areaReportsDict)
        
        tableView.reloadData()
        UIAccessibility.post(notification: UIAccessibility.Notification.announcement, argument: "Loaded Local Report")
    }
    
    func displayNationsReportResults(areaReportsDict: [ReportType: AreaReport]) {
        nationalAreaReportsDict = nationalAreaReportsDict + areaReportsDict
        tableView.reloadData()
        UIAccessibility.post(notification: UIAccessibility.Notification.announcement, argument: "Loaded National Report")
    }
    
    func loadNationalReport(areaReportsDict: [ReportType: AreaReport]) {
        
//        guard let nationalArea = nationalArea else {return}
        var reportStartYear: Int = 9999
        var reportEndYear: Int = -1
        var nationalReportTypes = [ReportType]()
        areaReportsDict.forEach { (reportType, areaReport) in
            
//            // Check if report exist in Cache
//            if let nationalSeriesId = reportType.seriesId(forArea: nationalArea, adjustment: seasonalAdjustment),
//                let localLatestData = areaReport.seriesReport?.latestData(),
//                let report = CacheManager.shared().getReport(seriesId: nationalSeriesId, forPeriod: localLatestData.period, year: localLatestData.year) {
//
//                var nationalReport = AreaReport(reportType: reportType, area: area)
//                nationalReport.seriesReport = report
//                nationalReport.seriesId = nationalSeriesId
//                nationalAreaReportsDict[reportType] = nationalReport
//            }
//            else
            if let localLatestData = areaReport.seriesReport?.latestData() {
                if reportStartYear > Int(localLatestData.year)! {
                    reportStartYear = Int(localLatestData.year)!
                }
                if reportEndYear < Int(localLatestData.year)! {
                    reportEndYear = Int(localLatestData.year)!
                }
                nationalReportTypes.append(reportType)
            }
            else {
               nationalReportTypes.append(reportType)
            }
        }
        
        if nationalReportTypes.count > 0 {
            let startYear = (reportStartYear != 9999) ? String(reportStartYear) : nil
            let endYear = (reportEndYear != -1) ?  String(reportEndYear) : nil
//            loadNationalReports(reportTypes: nationalReportTypes, startYear: startYear,
//                                endYear: endYear)
            loadNationalReports(reportTypes: nationalReportTypes, startYear: nil,
                                endYear: nil)
        }
    }
    
    func loadNationalReports(reportTypes: [ReportType], startYear: String?, endYear: String?) {
        guard let nationalArea = nationalArea else {return}
        
        ReportManager.getReports(forArea: nationalArea,
                                    reportTypes: reportTypes,
                                    seasonalAdjustment: seasonalAdjustment,
                                    startYear: startYear,
                                     endYear: endYear) {[weak self] (apiResult) in
            guard let strongSelf = self else {return}
            switch apiResult {
            case .success(let areaReportsDict):
                strongSelf.displayNationsReportResults(areaReportsDict: areaReportsDict)
            case .failure(let error):
                print(error)
            }
        }
    }
}


// MARK: - TableView Datasource
extension CountyViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return reportSections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var numRows = 0
        
        let currentReportSection = reportSections[section]
        if currentReportSection.collapsed == false {
            numRows = 1
            if !nationalAreaReportsDict.isEmpty {
                numRows = numRows + 1
            }
            
            // If Section has children, display them on last row
            if let children = currentReportSection.children, children.count > 0 {
                numRows = numRows + 1
            }
        }
        
        return numRows
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell? = nil
        
        let reportSection = reportSections[indexPath.section]
        if reportSection.title == CountyReport.unemploymentRate {
            let unEmploymentCell = tableView.dequeueReusableCell(withIdentifier: UnEmploymentRateTableViewCell.reuseIdentifier) as! UnEmploymentRateTableViewCell
            
            if let reportType = reportSections[indexPath.section].reportTypes?.first {
                let localAreaSeriesReport = localAreaReportsDict[reportType]?.seriesReport
                if indexPath.row == 0 {
                    unEmploymentCell.displaySeries(area: county, seriesReport: localAreaSeriesReport, seasonallyAdjusted: seasonalAdjustment)
                }
                else {
                    unEmploymentCell.displaySeries(area: nationalArea, seriesReport: nationalAreaReportsDict[reportType]?.seriesReport, periodName: localAreaSeriesReport?.latestDataPeriodName(), year: localAreaSeriesReport?.latestDataYear(), seasonallyAdjusted: seasonalAdjustment)
                }
            }
            cell = unEmploymentCell
        }
        else if reportSection.title == CountyReport.employmentWageTotal  {
            if indexPath.row == 0 {
                let employmentWageCell = tableView.dequeueReusableCell(withIdentifier: EmploymentWageTableViewCell.reuseIdentifier) as! EmploymentWageTableViewCell
                displayEmploymentWage(area: area, cell: employmentWageCell, section: reportSection)
                cell = employmentWageCell
            }
            else if indexPath.row ==
                self.tableView(tableView, numberOfRowsInSection: indexPath.section)-1 {
                let ownershipCell = tableView.dequeueReusableCell(withIdentifier: OwnershipTableViewCell.reuseIdentifier, for:indexPath) as? OwnershipTableViewCell
                let sectionReportTypes = reportSection.allReportTypes()
                ownershipCell?.area = area
                ownershipCell?.seasonalAdjustment = seasonalAdjustment
                ownershipCell!.localAreaReportsDict = localAreaReportsDict.filter {sectionReportTypes?.contains($0.key) ?? false}
                ownershipCell!.nationalAreaReportsDict = nationalAreaReportsDict.filter {sectionReportTypes?.contains($0.key) ?? false}
                ownershipCell!.reportSections = reportSection.children
                ownershipCell!.delegate = self
//                ownershipCell?.tableView.reloadData()
//                ownershipCell?.setNeedsUpdateConstraints()
//                ownershipCell?.setNeedsLayout()
//                ownershipCell?.layoutIfNeeded()
                cell = ownershipCell!
            }
            else {
                let employmentWageCell = tableView.dequeueReusableCell(withIdentifier: EmploymentWageTableViewCell.reuseIdentifier) as! EmploymentWageTableViewCell
                displayEmploymentWage(area: nationalArea, cell: employmentWageCell, section: reportSection)
                cell = employmentWageCell
            }
        }
        
        return cell!
    }

    func displayEmploymentWage(area: Area?, cell: EmploymentWageTableViewCell, section: ReportSection) {
        guard let area = area else {return}

        let reportTypes = section.reportTypes
        let reportsDict = localAreaReportsDict.filter {
            (reportTypes?.contains($0.key)) ?? false
        }

        guard reportsDict.count > 0 else {
            cell.displayEmploymentLevel(area: area, seriesReport: nil, periodName: nil, year: nil,
                                        seasonalAdjustment: seasonalAdjustment)
            cell.displayAverageWage(area: area, seriesReport: nil, periodName: nil, year: nil)
            return
        }
        
        reportsDict.forEach { (reportType, areaReport) in
            switch reportType {
            case .quarterlyEmploymentWage( _, _, _, let dataType):
                let latestLocalSeriesData = localAreaReportsDict[reportType]?.seriesReport?.latestData()
                
                let seriesReport: SeriesReport?
                if area is National {
                    seriesReport = nationalAreaReportsDict[reportType]?.seriesReport
                }
                else {
                    seriesReport = localAreaReportsDict[reportType]?.seriesReport
                }
                
                if dataType == QCEWReport.DataTypeCode.allEmployees {
                    cell.displayEmploymentLevel(area: area, seriesReport: seriesReport, periodName: latestLocalSeriesData?.periodName, year: latestLocalSeriesData?.year,
                                                seasonalAdjustment: seasonalAdjustment)
                }
                else if dataType == QCEWReport.DataTypeCode.avgWeeklyWage {
                    cell.displayAverageWage(area: area, seriesReport: seriesReport, periodName: latestLocalSeriesData?.periodName, year: latestLocalSeriesData?.year)
                }
                
            default: break
                
            }
        }
    }
}

extension CountyViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let sectionHeaderView =
            tableView.dequeueReusableHeaderFooterView(withIdentifier: "AreaSectionHeaderView") as? AreaSectionHeaderView
            else { return nil }
        
        let currentSection = reportSections[section]
        sectionHeaderView.configure(title: currentSection.title, section: section, collapse: currentSection.collapsed)

        sectionHeaderView.delegate = self
        return sectionHeaderView
    }

    /*
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row ==
            self.tableView(tableView, numberOfRowsInSection: indexPath.section)-1 {

            if let cell = ownershipCell {
////                cell.needsUpdateConstraints()
////                cell.updateConstraintsIfNeeded()
////
////                cell.bounds = CGRect(x: 0, y: 0, width: tableView.bounds.width, height: cell.bounds.height)
                cell.setNeedsLayout()
                cell.layoutIfNeeded()
                let height = cell.contentView.systemLayoutSizeFitting(UILayoutFittingCompressedSize).height
                let height1 = cell.contentHeight()
                return height
        }

    }
        return UITableViewAutomaticDimension
    }
 */
/*
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        let currentReportSection = reportSections[indexPath.section]
        if let children = currentReportSection.children, children.count > 0,
            indexPath.row == self.tableView(tableView, numberOfRowsInSection: indexPath.section)-1 {
            if let cell = ownershipCell {
                cell.setNeedsLayout()
                cell.layoutIfNeeded()
                print("Height Returned: %@", cell.contentHeight())
                return cell.contentHeight()
            }
        }
        
        let cell = self.tableView(tableView, cellForRowAt: indexPath)
        cell.setNeedsLayout()
        cell.layoutIfNeeded()

        print("HEight: %@, IndexPat: %@, %@", cell.bounds.height, indexPath.section, indexPath.row)
        return UITableViewAutomaticDimension
    }
    */
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        
        let currentReportSection = reportSections[indexPath.section]
        if let children = currentReportSection.children, children.count > 0,
                indexPath.row == self.tableView(tableView, numberOfRowsInSection: indexPath.section)-1 {
            let employmentSection = currentReportSection
            let expanded = employmentSection.children?.reduce(false) {$0 || $1.collapsed} ?? false
            
            if expanded {
                return 450
            }
        }
        return 230
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let currentSection = reportSections[section]
        
        guard currentSection.collapsed == false else { return nil }
        
        guard currentSection.title == CountyReport.unemploymentRate else { return nil }
        
        guard let sectionFooterView =
            tableView.dequeueReusableHeaderFooterView(withIdentifier: AreaSectionFooterView.reuseIdentifier) as? AreaSectionFooterView
            else { return nil }
        
        sectionFooterView.section = section
        sectionFooterView.delegate = self
        sectionFooterView.historyView.accessibilityHint = "Tap to display \(currentSection.title) history"
        return sectionFooterView
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        let currentSection = reportSections[section]
        guard currentSection.title == CountyReport.unemploymentRate,
            currentSection.collapsed == false else { return 0}
        
        return UITableView.automaticDimension
    }

}

extension CountyViewController: AreaSectionHeaderDelegate {
    
    // If user opens a section, close any previous opened Section
    func sectionHeader(_ sectionHeader: AreaSectionHeaderView, toggleExpand section: Int) {
        guard  Util.isVoiceOverRunning == false else {
            return
        }
        var addIndexPaths = [IndexPath]()
        var removeIndexPaths = [IndexPath]()

        var reloadSections = IndexSet(integer: section)
        
        // If user is toggling collapsed section, the collapse already opened Sections
        if reportSections[section].collapsed {
            for (index, currentSection) in reportSections.enumerated() {
                if false == currentSection.collapsed {
                    let rows = tableView(tableView, numberOfRowsInSection: index)
                    for row in 0..<rows {
                        removeIndexPaths.append(IndexPath(row: row, section: index))
                    }
                    currentSection.collapsed = true
                    reloadSections.update(with: index)
                }
            }
        }
        if reportSections[section].collapsed {
            reportSections[section].collapsed = !reportSections[section].collapsed
            let rows = tableView(tableView, numberOfRowsInSection: section)
            for row in 0..<rows {
                addIndexPaths.append(IndexPath(row: row, section: section))
            }
        }
        else {
            let rows = tableView(tableView, numberOfRowsInSection: section)
            for row in 0..<rows {
                removeIndexPaths.append(IndexPath(row: row, section: section))
            }
            reportSections[section].collapsed = !reportSections[section].collapsed
        }


        tableView.reloadSections(reloadSections, with: .automatic)
        tableView.beginUpdates()
//        if addIndexPaths.count > 0 {
//            tableView.insertRows(at: addIndexPaths, with: .none)
//        }
//        if removeIndexPaths.count > 0 {
//            tableView.deleteRows(at: removeIndexPaths, with: .none)
//        }
        tableView.endUpdates()
    }
    
    func sectionHeader(_ sectionHeader: AreaSectionHeaderView, displayDetails section: Int) {
        let section = reportSections[section]
        
        // For Industry Title
        if section.title == CountyReport.employmentWageTotal {
            displayQCEWIndustry()
        }
    }
    func displayQCEWIndustry() {
        let reportType: ReportType = .quarterlyEmploymentWageFrom(ownershipCode: .totalCovered, dataType: .allEmployees)
        performSegue(withIdentifier: "showIndustries", sender: reportType)
    }
}

// MARK: AreaSectionFooterDelegate
extension CountyViewController: AreaSectionFooterDelegate {
    func sectionFooter(_ sectionFooter: AreaSectionFooterView, displayHistory section: Int) {
        let section = reportSections[section]
        
        if section.title == CountyReport.unemploymentRate {
            displayUnemploymentHistory()
        }
    }
    
    func displayUnemploymentHistory() {
        let reportType: ReportType = .unemployment(measureCode: .unemploymentRate)
        performSegue(withIdentifier: "showHistory", sender: reportType)
    }
}

extension CountyViewController: OwnershipTableViewCellDelegate {
    func contentDidChange(cell: UITableViewCell) {
        guard  Util.isVoiceOverRunning == false else {
            return
        }

        cell.needsUpdateConstraints()
        cell.updateConstraintsIfNeeded()
        
        cell.setNeedsLayout()
        cell.layoutIfNeeded()
        self.tableView.beginUpdates()
        self.tableView.endUpdates()
    }
    
    func ownership(_ cell: OwnershipTableViewCell, displayDetails reportSection: ReportSection) {
        guard reportSection.reportTypes?.count ?? 0 > 0,
            let reportTypes = reportSection.reportTypes else {return}
        
        performSegue(withIdentifier: "showIndustries", sender: reportTypes[0])
    }
}

