//
//  HomeViewController.swift
//  holodule-ios
//
//  Created by ymgn on 2020/08/12.
//  Copyright © 2020 ymgn. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import APIKit

class HomeViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let channelNib = UINib(nibName: "ChannelCell", bundle: nil)
        tableView.register(channelNib, forCellReuseIdentifier: "ChannelCell")
        tableView.indexPathsForSelectedRows?.forEach { [weak self] in
            self?.tableView.deselectRow(at: $0, animated: true)
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Session.rx_send(request: GetChannelList(username: "桐生ココ")).subscribe{ res in
            print(res)
        }
    }
}
