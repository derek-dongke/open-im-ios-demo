





import UIKit
import RxSwift
import SVProgressHUD

class SingleChatSettingTableViewController: UITableViewController {
    
    private let _viewModel: SingleChatSettingViewModel
    
    init(viewModel: SingleChatSettingViewModel, style: UITableView.Style) {
        _viewModel = viewModel
        super.init(style: style)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "聊天设置".innerLocalized()
        configureTableView()
        initView()
        _viewModel.getConversationInfo()
    }
    
    private let sectionItems: [[RowType]] = [
        [.members],
        [.chatRecord],
        [.setTopOn, .setDisturbOn],
        [.complaint],
        [.clearRecord]
    ]
    
    private let _disposeBag = DisposeBag()
    
    private func configureTableView() {
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }
        tableView.backgroundColor = StandardUI.color_F1F1F1
        tableView.rowHeight = UITableView.automaticDimension
        tableView.register(SingleChatMemberTableViewCell.self, forCellReuseIdentifier: SingleChatMemberTableViewCell.className)
        tableView.register(SingleChatRecordTableViewCell.self, forCellReuseIdentifier: SingleChatRecordTableViewCell.className)
        tableView.register(SwitchTableViewCell.self, forCellReuseIdentifier: SwitchTableViewCell.className)
        tableView.register(OptionTableViewCell.self, forCellReuseIdentifier: OptionTableViewCell.className)
    }
    
    private func initView() {
        
    }
    
    enum RowType: CaseIterable {
        case members
        case chatRecord
        case setTopOn
        case setDisturbOn
        case complaint
        case clearRecord
        
        var title: String {
            switch self {
            case .members:
                return ""
            case .chatRecord:
                return "查找聊天记录".innerLocalized()
            case .setTopOn:
                return "置顶联系人".innerLocalized()
            case .setDisturbOn:
                return "消息免打扰".innerLocalized()
            case .complaint:
                return "投诉".innerLocalized()
            case .clearRecord:
                return "清空聊天记录".innerLocalized()
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 12
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return UIView()
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return sectionItems.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sectionItems[section].count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let rowType = sectionItems[indexPath.section][indexPath.row]
        switch rowType {
        case .members:
            let cell = tableView.dequeueReusableCell(withIdentifier: SingleChatMemberTableViewCell.className) as! SingleChatMemberTableViewCell
            _viewModel.membesRelay.asDriver(onErrorJustReturn: []).drive(cell.memberCollectionView.rx.items) { (collectionView, row, item: UserInfo) in
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SingleChatMemberTableViewCell.MemberCell.className, for: IndexPath.init(row: row, section: 0)) as! SingleChatMemberTableViewCell.MemberCell
                if item.isButton {
                    cell.avatarImageView.image = UIImage.init(nameInBundle: "setting_add_btn_icon")
                    cell.nameLabel.text = nil
                } else {
                    cell.avatarImageView.setImage(with: item.faceURL, placeHolder: "contact_my_friend_icon")
                    cell.nameLabel.text = item.nickname
                }
                return cell
            }.disposed(by: cell.disposeBag)
            
            cell.memberCollectionView.rx.modelSelected(UserInfo.self).subscribe(onNext: { [weak self] (userInfo: UserInfo) in
                if userInfo.isButton {
                    let vc = SelectContactsViewController()
                    vc.selectedContactsBlock = { [weak vc, weak self] (users: [UserInfo]) in
                        guard let sself = self else { return }
                        var allUsers: [UserInfo] = sself._viewModel.membesRelay.value
                        allUsers.append(contentsOf: users)
                        IMController.shared.createConversation(users: allUsers) { (groupInfo: GroupInfo?) in
                            guard let groupInfo = groupInfo else { return }
                            IMController.shared.getConversation(sessionType: groupInfo.groupType, sourceId: groupInfo.groupID) { (conversation: ConversationInfo?) in
                                guard let conversation = conversation else { return }

                                let viewModel: MessageListViewModel = MessageListViewModel.init(groupId: groupInfo.groupID, conversation: conversation)
                                let chatVC = MessageListViewController.init(viewModel: viewModel)
                                self?.navigationController?.pushViewController(chatVC, animated: false)
                            }
                        }
                    }
                    self?.navigationController?.pushViewController(vc, animated: true)
                }
            }).disposed(by: cell.disposeBag)
            return cell
        case .chatRecord:
            let cell = tableView.dequeueReusableCell(withIdentifier: SingleChatRecordTableViewCell.className) as! SingleChatRecordTableViewCell
            cell.titleLabel.text = rowType.title
            
            cell.searchTextBtn.tap.rx.event.subscribe(onNext: { [weak self] _ in
                guard let sself = self else { return }
                let vc = SearchContainerViewController.init(conversationId: sself._viewModel.conversation.conversationID)
                self?.navigationController?.pushViewController(vc, animated: true)
            }).disposed(by: cell.disposeBag)
            
            cell.searchImageBtn.tap.rx.event.subscribe(onNext: { [weak self] _ in
                guard let sself = self else { return }
                let searchViewModel = SearchRecordViewModel.init(conversationId: sself._viewModel.conversation.conversationID)
                let vc = ImageRecordViewController.init(viewModel: searchViewModel, viewType: .image)
                self?.navigationController?.pushViewController(vc, animated: true)
            }).disposed(by: cell.disposeBag)
            
            cell.searchVideoBtn.tap.rx.event.subscribe(onNext: { [weak self] _ in
                guard let sself = self else { return }
                let searchViewModel = SearchRecordViewModel.init(conversationId: sself._viewModel.conversation.conversationID)
                let vc = ImageRecordViewController.init(viewModel: searchViewModel, viewType: .video)
                self?.navigationController?.pushViewController(vc, animated: true)
            }).disposed(by: cell.disposeBag)
            
            cell.searchFileBtn.tap.rx.event.subscribe(onNext: { [weak self] _ in
                guard let sself = self else { return }
                let viewModel = SearchRecordViewModel.init(conversationId: sself._viewModel.conversation.conversationID)
                let vc = FileRecordViewController.init(viewModel: viewModel)
                self?.navigationController?.pushViewController(vc, animated: true)
            }).disposed(by: cell.disposeBag)
            return cell
        case .setTopOn:
            let cell = tableView.dequeueReusableCell(withIdentifier: SwitchTableViewCell.className) as! SwitchTableViewCell
            _viewModel.setTopContactRelay.bind(to: cell.switcher.rx.isOn).disposed(by: cell.disposeBag)
            cell.switcher.rx.controlEvent(.valueChanged).subscribe(onNext: { [weak self] in
                self?._viewModel.toggleTopContacts()
            }).disposed(by: cell.disposeBag)
            cell.titleLabel.text = rowType.title
            return cell
        case .setDisturbOn:
            let cell = tableView.dequeueReusableCell(withIdentifier: SwitchTableViewCell.className) as! SwitchTableViewCell
            _viewModel.noDisturbRelay.bind(to: cell.switcher.rx.isOn).disposed(by: cell.disposeBag)
            cell.switcher.rx.controlEvent(.valueChanged).subscribe(onNext: { [weak self] in
                self?._viewModel.toggleNoDisturb()
            }).disposed(by: cell.disposeBag)
            cell.titleLabel.text = rowType.title
            return cell
        case .complaint:
            let cell = tableView.dequeueReusableCell(withIdentifier: OptionTableViewCell.className) as! OptionTableViewCell
            cell.titleLabel.text = rowType.title
            return cell
        case .clearRecord:
            let cell = tableView.dequeueReusableCell(withIdentifier: OptionTableViewCell.className) as! OptionTableViewCell
            cell.titleLabel.text = rowType.title
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let rowType: RowType = sectionItems[indexPath.section][indexPath.row]
        switch rowType {
        case .complaint:
            print("跳转投诉页面")
        case .clearRecord:
            AlertView.show(onWindowOf: self.view, alertTitle: "确认清空所有聊天记录吗？".innerLocalized(), confirmTitle: "确认".innerLocalized()) { [weak self] in
                self?._viewModel.clearRecord(completion: { _ in
                    SVProgressHUD.showSuccess(withStatus: "清空成功".innerLocalized())
                })
            }
        default:
            break
        }
    }
}