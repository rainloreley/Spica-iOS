//
// Spica for iOS (Spica)
// File created by Adrian Baumgart on 01.08.20.
//
// Licensed under the GNU General Public License v3.0
// Copyright © 2020 Adrian Baumgart. All rights reserved.
//
// https://github.com/SpicaApp/Spica-iOS
//

import Combine
import JGProgressHUD
import SwiftUI
import UIKit

class FollowersFollowingViewController: UIViewController {
    typealias DataSource = UITableViewDiffableDataSource<Section, User>
    typealias Snapshot = NSDiffableDataSourceSnapshot<Section, User>

    var tableView: UITableView!
    var segmentedControl: UISegmentedControl!
    var refreshControl = UIRefreshControl()
    var loadingHud: JGProgressHUD!

    private var subscriptions = Set<AnyCancellable>()
    private lazy var dataSource = makeDataSource()

    var verificationString = ""
    var selectedIndex = 0

    var followersFollowing: Followers = Followers(followers: [], following: [])

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = SLocale(.FOLLOWER_PLURAL)

        navigationController?.navigationBar.prefersLargeTitles = true
        view.backgroundColor = .systemBackground

        tableView = UITableView(frame: view.bounds, style: .insetGrouped)
        tableView.delegate = self
        tableView.dataSource = dataSource
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        view.addSubview(tableView)

        segmentedControl = UISegmentedControl(items: [SLocale(.FOLLOWER_PLURAL), SLocale(.FOLLOWING_ACTION)])
        segmentedControl.selectedSegmentIndex = selectedIndex
        segmentedControl.addTarget(self, action: #selector(loadData), for: .valueChanged)

        navigationItem.title = segmentedControl.selectedSegmentIndex == 0 ? SLocale(.FOLLOWER_PLURAL) : SLocale(.FOLLOWING_ACTION)

        view.addSubview(segmentedControl)

        segmentedControl.snp.makeConstraints { make in
            make.bottom.equalTo(view.snp.bottom).offset(-8)
            make.leading.equalTo(view.snp.leading).offset(16)
            make.trailing.equalTo(view.snp.trailing).offset(-16)
            make.height.equalTo(30)
        }

        tableView.snp.makeConstraints { make in
            make.top.equalTo(view.snp.top)
            make.leading.equalTo(view.snp.leading)
            make.trailing.equalTo(view.snp.trailing)
            make.bottom.equalTo(segmentedControl.snp.top).offset(-8)
        }
        refreshControl.addTarget(self, action: #selector(loadData), for: .valueChanged)
        tableView.addSubview(refreshControl)

        loadingHud = JGProgressHUD(style: .dark)
        loadingHud.textLabel.text = SLocale(.LOADING_ACTION)
        loadingHud.interactionType = .blockNoTouches
    }

    override func viewWillAppear(_: Bool) {
        navigationController?.navigationBar.prefersLargeTitles = true
    }

    override func viewDidAppear(_: Bool) {
        loadData()
    }

    @objc func loadData() {
        navigationItem.title = segmentedControl.selectedSegmentIndex == 0 ? SLocale(.FOLLOWER_PLURAL) : SLocale(.FOLLOWING_ACTION)

        AllesAPI.loadFollowers()
            .receive(on: RunLoop.main)
            .sink {
                switch $0 {
                case let .failure(err):
                    self.refreshControl.endRefreshing()
                    self.loadingHud.dismiss()
                    AllesAPI.default.errorHandling(error: err, caller: self.view)

                default: break
                }
            } receiveValue: { [self] followers in
                followersFollowing = followers
                applyChanges(segmentedStatus: segmentedControl.selectedSegmentIndex)
                refreshControl.endRefreshing()
                loadingHud.dismiss()
                verificationString = randomString(length: 30)
                loadImages()
            }
            .store(in: &subscriptions)
    }

    func loadImages() {
        let veri = verificationString
        DispatchQueue.main.async { [self] in
            let segmentedStatus = segmentedControl.selectedSegmentIndex

            DispatchQueue.global(qos: .utility).async {
                let users = segmentedStatus == 0 ? followersFollowing.followers : followersFollowing.following
                let dispatchGroup = DispatchGroup()
                for (index, user) in users.enumerated() {
                    if veri != verificationString { return }
                    dispatchGroup.enter()
                    if index <= users.count - 1 {
                        if veri != verificationString { return }
                        if segmentedStatus == 0 {
                            followersFollowing.followers[index].image = ImageLoader.loadImageFromInternet(url: user.imgURL!)
                        } else {
                            followersFollowing.following[index].image = ImageLoader.loadImageFromInternet(url: user.imgURL!)
                        }

                        if veri != verificationString { return }
                        applyChanges(segmentedStatus: segmentedStatus)
                        dispatchGroup.leave()
                    }
                }
                applyChanges(segmentedStatus: segmentedStatus)
            }
        }
    }

    func makeDataSource() -> DataSource {
        let source = DataSource(tableView: tableView) { (tableView, indexPath, user) -> UITableViewCell? in
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)

            let content = UIHostingController(rootView: FollowerCell(follower: user)).view
            content?.backgroundColor = .secondarySystemGroupedBackground
            cell.contentView.addSubview(content!)
            content?.snp.makeConstraints { make in
                make.top.equalTo(cell.contentView.snp.top)
                make.leading.equalTo(cell.contentView.snp.leading)
                make.bottom.equalTo(cell.contentView.snp.bottom)
                make.trailing.equalTo(cell.contentView.snp.trailing)
            }
            return cell
        }
        source.defaultRowAnimation = .fade
        return source
    }

    func applyChanges(_ animated: Bool = true, segmentedStatus: Int) {
        var snapshot = Snapshot()
        snapshot.appendSections([.main])
        if segmentedStatus == 0 {
            snapshot.appendItems(followersFollowing.followers, toSection: .main)
        } else {
            snapshot.appendItems(followersFollowing.following, toSection: .main)
        }
        DispatchQueue.main.async {
            self.dataSource.apply(snapshot, animatingDifferences: animated)
        }
    }

    enum Section: Hashable {
        case main
    }
}

extension FollowersFollowingViewController: UITableViewDelegate {
    func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        let userByTag = segmentedControl.selectedSegmentIndex == 0 ? followersFollowing.followers[indexPath.row] : followersFollowing.following[indexPath.row]
        let vc = UserProfileViewController()

        vc.user = User(id: userByTag.id, name: userByTag.name, nickname: userByTag.nickname, image: userByTag.image!, imgURL: userByTag.imgURL)
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }
}

struct FollowerCell: View {
    var follower: User!

    var body: some View {
        HStack {
            Image(uiImage: follower.image ?? UIImage(systemName: "person.circle")).resizable().frame(width: 40, height: 40, alignment: .leading).cornerRadius(20)
            VStack(alignment: .leading) {
                Text("\(follower.name)").bold()
                Text("\(follower.name)#\(follower.tag)").foregroundColor(.secondary)
            }
            Spacer()
        }.padding()
    }
}
