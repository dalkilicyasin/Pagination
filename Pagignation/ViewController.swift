//
//  ViewController.swift
//  Pagignation
//
//  Created by Yasin Dalkilic on 25.02.2023.
//

import UIKit

class ViewController: UIViewController {
    var peopleList : [Person]?
    lazy var refreshControl = UIRefreshControl()
    var nextValue : String?
    
    let tableView: UITableView = {
        let tableView = UITableView()
        tableView.register(CustomTableViewCell.self, forCellReuseIdentifier: CustomTableViewCell.identifier)
        tableView.separatorStyle = CustomTableViewCell.SeparatorStyle.singleLine
        return tableView
    }()
    let label = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 21))
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(tableView)
        view.addSubview(label)
        
        tableView.delegate = self
        tableView.dataSource = self
        
        self.fetchPeopleList(nextValue: nil)
       
        refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
        refreshControl.addTarget(self, action: #selector(self.refresh(_:)), for: .valueChanged)
        tableView.addSubview(refreshControl)
    }
 
    @objc func refresh(_ sender: AnyObject) {
       print("refreshed")
       let dispatchTime = DispatchTime.now() + 1
        
        DispatchQueue.global(qos: .background).asyncAfter(deadline: dispatchTime){
            self.fetchPeopleList(nextValue: self.nextValue)
            DispatchQueue.main.async {
                self.refreshControl.endRefreshing()
            }
        }
    }
    
    func fetchPeopleList( nextValue : String?){
        DataSource.fetch(next: nextValue) { response, error in
            if error != nil {
                print(error?.errorDescription ?? "Error")
                if self.peopleList == nil {
                    self.showLabel(labelDescription: error?.errorDescription, showLabel: true)
                }
            }else{
                if response != nil {
                    self.peopleList = response?.people
                    self.nextValue = response?.next
                    if self.peopleList != nil {
                        self.peopleList = self.removeDuplicateElements(personList: self.peopleList!)
                    }
                    self.showLabel(labelDescription: nil, showLabel: false)
                    if nextValue == nil {
                            self.showLabel(labelDescription: error?.errorDescription, showLabel: true)
                        if error == nil && self.peopleList == nil{
                            self.showLabel(labelDescription: "No list please try again", showLabel: true)
                        }
                    }
                    self.tableView.reloadData()
                }
            }
        }
    }
    
    func showLabel(labelDescription : String?, showLabel : Bool){
        if showLabel {
            self.label.isHidden = false
            self.label.textAlignment = .center
            self.label.text = labelDescription
            
        }else{
            self.label.isHidden = true
        }
    }
   
    
    func removeDuplicateElements(personList: [Person]) -> [Person] {
        var uniquePerson = [Person]()
        for person in personList {
            if !uniquePerson.contains(where: {$0.id == person.id }) {
                uniquePerson.append(person)
            }
        }
        return uniquePerson
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.tableView.frame = view.bounds
        self.label.frame = view.bounds
    }
}


extension ViewController : UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.peopleList?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CustomTableViewCell.identifier, for : indexPath) as! CustomTableViewCell
        cell.myLabel.text = "\(self.peopleList?[indexPath.row].fullName ?? "")(\(self.peopleList?[indexPath.row].id ?? 0))"
        return cell
    }
}

