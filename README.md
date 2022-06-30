# Open-IM-iOS-Demo: OpenIM Messaging Client for iOS

iOS client for [OpenIM](https://github.com/OpenIMSDK/Open-IM-Server) in Swift.


⚠️ New features are added continuously.⚠️

### Demo内容
Demo 是基于 Open-IM SDK 实现的一套 UI 组件，其包含会话、聊天、关系链、群组等功能，基于 UI 组件您可以快速搭建起自己的业务逻辑。

### 直接testflight下载app体验

<img src="https://github.com/OpenIMSDK/OpenIM-Docs/blob/main/docs/images/ios_native.png" alt="image" style="width: 200px; " />

### 源代码体验

1. 开发环境要求
    Xcode 10 及以上
    
    iOS 11 及以上（后续提高iOS13及以上）

2. git clone：
    ```ruby
    https://github.com/OpenIMSDK/Open-IM-iOS-Demo.git
    ```

3. 终端执行以下命令，安装依赖库。

    ```ruby
    //iOS
    cd Open-IM-iOS-Demo/Example
    pod install
    ```
4. 如果安装失败，执行以下命令更新本地的 CocoaPods 仓库列表。
    ```ruby
    pod repo update
    ```
5. 编译运行：

    进入Open-IM-iOS-Demo/Example 文件夹，打开OpenIMSDKUIKit.xcworkspace编译运行。
    
6. 体验自己的服务器
 
    如果自己搭建了OpenIM Server，可修改 [AppDelegate.swift](https://github.com/OpenIMSDK/Open-IM-iOS-Demo/blob/main/Example/OpenIMSDKUIKit/AppDelegate.swift)文件里的服务器地址为自己搭建的服务器地址
    
### Demo主要实现步骤介绍

常用的聊天软件都是由会话列表、聊天窗口、好友列表、音视频通话等几个基本的界面组成，参考下面步骤，您仅需几行代码即可在项目中快速搭建这些 UI 界面。
音视频通话，目前原生暂未支持，后续会增加。
    
步骤一：初始化SDK，设置ip：
1. 举例
    ```ruby
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // 自己业务服务器的地址，demo中负责业务服务器的登录操作
        DemoPlugin.shared.setup(baseUrl: "http://xxxx:10004/")
        // IM服务器的地址，OpenIM SDK使用
        IMController.shared.setup(apiAdrr: "http://xxxx:10002",
                                  wsAddr: "ws://xxxx:10001")
    }
    ```

步骤二：登录
1. 登录自己的业务服务器，获取userID 和 token；
2. 使用1.获取userID 和 token 登录OpenIM服务器；
3. 举例：
    ```ruby
    // 1: 登录自己的业务服务器，获取userID 和 token；
    LoginAPI.init(req: .init(phoneNumber: "", pwd: "")).send()
        .subscribe(onNext: { (api: LoginAPI) in
            guard let resp = api.response else { return }

            // 2: 登录OpenIM服务器；
            self?.loginIM(uid: resp.data.userID, token: resp.data.token, completion: { [weak controller] in
                controller?.dismiss(animated: true)
            })
        }, onError: { err in

        }).disposed(by: sself._disposeBag)
    ```
        
    ```ruby
    func loginIM(uid: String, token: String, completion: (() -> Void)?) {
        IMController.shared.login(uid: uid, token: token) { [weak self] (resp: String?) in

            print("login onSuccess \(String(describing: resp))")
            completion?()
        } onFail: { (code: Int, msg: String?) in
            print("login onFail: code \(code), reason \(String(describing: msg))")
        }
    }
    ```
    
步骤三：构建会话列表、聊天窗口、通讯录界面、设置：
1. 举例
    ```ruby
    // 会话列表
    let chat = ChatListViewController()
    // 聊天窗口
    let message = MessageListViewController()
    // 通讯录
    let contactVC = ContactsViewController()
    // 设置
    let mineNav = MineViewController()        
    ```

### 常见问题

1. 提醒: 在调用sdk相关API返回“resource loading is not complete”
    如果出现该问题，需在login的callback以后调用其它API。

2. 提醒：“target has transitive dependencies that include statically linked binaries”？
    如果在 pod 过程中出现该错误，是因为 TUIKit 使用到了第三方静态库，需要在 podfile 中注释掉 use_frameworks!。
    如果在某种情况下，需要使用use_frameworks!，则请使用 cocoapods 1.9.0及以上版本进行 pod install，并修改为：
    ```ruby
        use_frameworks! :linkage => :static
    ```
    如果您使用的是 swift，请将头文件引用改成 @import 模块名形式引用。
