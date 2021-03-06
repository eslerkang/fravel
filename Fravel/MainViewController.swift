//
//  MainViewController.swift
//  Fravel
//
//  Created by 강태준 on 2022/06/29.
//

import UIKit

class MainViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    
    var hiddenSections = Set<Int>()
    var tableViewData = [[Any]]()
    
    let noticeCellId = "NoticeTableViewCell"
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .light
        
        self.tableViewData = [
            [1, 2, 3, 4, 5],
            [6, 7, 8],
            [9, 10, 11, 21, 13, 14]
        ]
        
        setupTableView()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    
    func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UINib(nibName: noticeCellId, bundle: nil), forCellReuseIdentifier: noticeCellId)
    }
}

extension MainViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.tableViewData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: noticeCellId, for: indexPath) as? NoticeTableViewCell else {return UITableViewCell()}
        cell.selectionStyle = .none
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.hiddenSections.contains(section) {
            return 0
        }
        
        return self.tableViewData[section].count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.spacing = 0
        stackView.backgroundColor = .systemMint
        stackView.layoutMargins = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        stackView.isLayoutMarginsRelativeArrangement = true
        
        let sectionButton = UIButton()
        sectionButton.setTitle(String(section), for: .normal)
        sectionButton.contentHorizontalAlignment = .left
        sectionButton.tag = section
        sectionButton.titleLabel?.font = .systemFont(ofSize: 16)
        sectionButton.addTarget(self, action: #selector(hideSection(sender:)), for: .touchUpInside)
        
        
        let moreButton = UIButton()
        moreButton.setTitle("더보기", for: .normal)
        moreButton.sizeToFit()
        moreButton.contentHorizontalAlignment = .right
        moreButton.tag = section
        moreButton.addTarget(self, action: #selector(moveToSectionBoard(sender:)), for: .touchUpInside)
        moreButton.titleLabel?.font = .systemFont(ofSize: 16)
        
        stackView.addArrangedSubview(sectionButton)
        stackView.addArrangedSubview(moreButton)
        
        return stackView
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 30
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        debugPrint(indexPath.section, indexPath.row)
    }
    
    @objc
    private func hideSection(sender: UIButton) {
        let section = sender.tag
        
        func indexPathForSection() -> [IndexPath] {
            var indexPaths = [IndexPath]()
            
            for row in 0..<self.tableViewData[section].count {
                indexPaths.append(IndexPath(row: row, section: section))
            }
            
            return indexPaths
        }
        
        if self.hiddenSections.contains(section) {
            self.hiddenSections.remove(section)
            self.tableView.insertRows(at: indexPathForSection(), with: .fade)
        } else {
            self.hiddenSections.insert(section)
            self.tableView.deleteRows(at: indexPathForSection(), with: .fade)
        }
    }
    
    @objc
    private func moveToSectionBoard(sender: UIButton) {
        debugPrint(sender.tag)
    }
    
}
