//
//  ViewController.swift
//  MyPosts
//
//  Created by AnhNguyen on 30/07/2022.
//

import UIKit

struct Post: Decodable {
    let id: Int
    let title, body: String
}

class Service: NSObject {
    static let shared = Service()
    
    func fetchPosts(completion: @escaping (Result<[Post], Error>) -> ()) {
        guard let url = URL(string: "http://localhost:1337/posts") else {
            return
        }
        
        URLSession.shared.dataTask(with: url) { (data, res, err) in
            if let err = err {
                print("Failed to fecth posts: ", err)
                return
            }
            guard let data = data else {return}
            
            print(String(data: data, encoding: .utf8) ?? "")
            
            do {
                let posts = try JSONDecoder().decode([Post].self, from: data)
                completion(.success(posts))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    func createPost(title: String, body: String, completion: @escaping (Error?) -> ()) {
        guard let url = URL(string: "http://localhost:1337/post") else {
            return
            
        }
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let params = ["title": title, "body": body]
        do {
            let data = try JSONSerialization.data(withJSONObject: params, options: [])
            urlRequest.httpBody = data
            URLSession.shared.dataTask(with: urlRequest) { (data, res, err) in
                if err != nil {
                    print("error create post")
                    completion(err)
                }
                guard let data = data else {return}
                print(String(data: data, encoding: .utf8) ?? "")
                completion(nil)
            }.resume()
        } catch {
            completion(error)
        }
        
    }
    
    func deletePost(id: Int, completion: @escaping (Error?) -> ()) {
        guard let url = URL(string: "http://localhost:1337/post/\(id)") else {
            return
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "DELETE"
        URLSession.shared.dataTask(with: urlRequest) { (data, res, err) in
            if err != nil {
                print("error create post")
                completion(err)
            }
            if let resp = res as? HTTPURLResponse, resp.statusCode != 200 {
                let errorString = String(data: data ?? Data(), encoding: .utf8) ?? ""
                completion(NSError(domain: "", code: resp.statusCode, userInfo: [NSLocalizedDescriptionKey: errorString]))
                return
            }
            completion(nil)
        }.resume()
    }
}



class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    fileprivate func fetchPosts() {
        Service.shared.fetchPosts { (res) in
            switch res {
            case .failure(let err):
                print("Failed to fetch posts: ", err)
            case .success(let posts):
                print(posts)
                self.posts = posts
                DispatchQueue.main.async {
                    self.myTableView.reloadData()
                }
                
            }
        }
    }
    
    var posts = [Post]()
    
    let myTableView = UITableView()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        view.addSubview(myTableView)
        myTableView.dataSource = self
        myTableView.register(UITableViewCell.self, forCellReuseIdentifier: "myPostCell")
        myTableView.translatesAutoresizingMaskIntoConstraints = false
        myTableView.topAnchor.constraint(equalTo:view.safeAreaLayoutGuide.topAnchor).isActive = true
        myTableView.leftAnchor.constraint(equalTo:view.leftAnchor).isActive = true
        myTableView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        myTableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
        
        self.navigationItem.title = "Posts"
        self.navigationItem.rightBarButtonItem = .init(title: "Create Post", style: .plain, target: self, action: #selector(handleCreatePost))
        fetchPosts()
    }


    @objc private func handleCreatePost() {
        Service.shared.createPost(title: "Oliver", body: "Nguyen") { err in
            if err != nil {
                print("Failed to create post")
                return
            }
            print("Finish create post")
            self.fetchPosts()
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return posts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "myPostCell")
        cell.textLabel?.text = posts[indexPath.row].title
        cell.detailTextLabel?.text = posts[indexPath.row].body
        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            print("delete post")
            let post = self.posts[indexPath.row]
            Service.shared.deletePost(id: post.id) { err in
                if err != nil {
                    print("Failed to create post", err)
                    return
                }
                print("Finish create post")
                self.posts.remove(at: indexPath.row)
                DispatchQueue.main.async {
                    self.myTableView.deleteRows(at:[indexPath], with:.automatic)
                }
            }
        }
    }
}

