//
//  ViewController.swift
//  MVVMBinding-Observable
//
//  Created by Vikas on 15/05/23.
//

import UIKit

// Observable

class Observable<T> {
    // When ever the value changed then we will listen to the value
    var value: T? {
        didSet {
            listener?(value) // listener.forEach {$0.value}
        }
    }
    
    init(value: T? = nil) {
        self.value = value
    }
    
    private var listener: ((T?) -> Void)? // [((T?) -> Void)] = []
    
    func bind(_ listener: @escaping (T?) -> Void) {
        listener(value)
        self.listener = listener // self.listener.append(listener)
    }
}

// Model

struct User: Codable {
    let name: String
    let website: String
}

// ViewModel
struct UserViewModel {
    var user: Observable<[UserTableViewCellViewModel]> = Observable(value: [])
}

struct UserTableViewCellViewModel {
    let name: String
    let website: String
}


class ViewController: UIViewController {

    private let tableView: UITableView = {
        let table = UITableView()
        table.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        return table
    }()
    
    private var viewmodel = UserViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(tableView)
        tableView.frame = view.bounds
        tableView.dataSource = self
        
        viewmodel.user.bind { [weak self] _ in
            DispatchQueue.main.async {
                self?.tableView.reloadData()
            }
        }
        
        fetchData()
    }
}

extension ViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewmodel.user.value?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = viewmodel.user.value?[indexPath.row].name
        cell.detailTextLabel?.text = viewmodel.user.value?[indexPath.row].website
        return cell
    }

}

extension ViewController {
    
    func fetchData() {
        guard let url = URL(string: "https://jsonplaceholder.typicode.com/users") else { return }
        
        URLSession.shared.dataTask(with: URLRequest(url: url)) { data, response, error in
            guard let data = data else { return }
            do {
                let userModel = try JSONDecoder().decode([User].self, from: data)
                self.viewmodel.user.value = userModel.compactMap({
                    UserTableViewCellViewModel(name: $0.name, website: $0.website)
                })
            } catch {
                dump(print("Error Decoding \(error.localizedDescription)"))
            }
        }.resume()
    }
    
}

