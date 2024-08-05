
import AVFoundation
import Foundation
import LiveKitClient
import Lottie
import RxSwift
import SnapKit
import OUICore
import ProgressHUD

public class CallingReceiverController: CallingBaseController {
    
    private var signal: ReceiverSignalViewController?
    private var isPresented: Bool = false

    public var duration: Int {
        signal?.linkingDuration ?? 0
    }
    
    public override func connectRoom(liveURL: String, token: String) {
        signal?.connectRoom(liveURL: liveURL, token: token)
    }
    
    public override func dismiss() {
        isPresented = false
        signal?.dismiss()
    }
    
    public override func startLiveChat(inviter: @escaping UserInfoHandler,
                                       others: @escaping UserInfoHandler,
                                       isVideo: Bool = true) {
        if isPresented {
            return
        }
        isPresented = true
        
        signal = ReceiverSignalViewController()
        signal!.inviter = inviter
        signal!.users = others
        signal!.isVideo = isVideo
        signal!.onAccepted = onAccepted
        signal!.onRejected = onRejected
        signal!.onHungup = onHungup
        signal!.onDisconnect = onDisconnect
        signal!.onConnectFailure = onConnectFailure
        signal!.onBeHungup = onBeHungup
        
        signal!.modalPresentationStyle = .overCurrentContext
        UIViewController.currentViewController().present(signal!, animated: true)
    }
}

class ReceiverSignalViewController: CallingBaseViewController {
    private var verStackView: UIStackView?
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        playSounds()
        room.add(delegate: self)
        setupView()
    }
    
    func setupView() {
        let inviter = inviter().first

        let avatarView = AvatarView()
        avatarView.setAvatar(url: inviter?.faceURL, text: inviter?.nickname)
        avatarView.snp.makeConstraints { make in
            make.width.height.equalTo(70)
        }
        
        let nameLabel = UILabel()
        nameLabel.layer.cornerRadius = 6
        nameLabel.layer.masksToBounds = true
        nameLabel.text = inviter?.nickname
        nameLabel.font = .systemFont(ofSize: 28)
        nameLabel.textAlignment = .center
        nameLabel.textColor = .white
        
        if !isVideo {
            let infoStackView = UIStackView(arrangedSubviews: [avatarView, nameLabel, tipsLabel])
            infoStackView.axis = .vertical
            infoStackView.spacing = 24
            infoStackView.alignment = .center
            
            tipsLabel.text = "invitedVoiceCallHint".innerLocalized()
            verStackView = UIStackView(arrangedSubviews: [infoStackView, UIView()])
        } else {
            let infoStackView = UIStackView(arrangedSubviews: [nameLabel, tipsLabel])
            infoStackView.axis = .vertical
            infoStackView.distribution = .equalSpacing
            infoStackView.alignment = .leading
            
            let rowStackView = UIStackView(arrangedSubviews: [SizeBox(width: 24), avatarView, SizeBox(width: 8), infoStackView, SizeBox(width: 24)])
            rowStackView.axis = .horizontal
            rowStackView.spacing = 8
            
            tipsLabel.text = "invitedVideoCallHint".innerLocalized()
            verStackView = UIStackView(arrangedSubviews: [rowStackView, UIView()])
        }
        
        verStackView!.axis = .vertical
        verStackView!.distribution = .equalSpacing
        view.addSubview(verStackView!)
        
        verStackView!.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(minimizeButton.snp_bottom).offset(24)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }
        
        insertLinkingViewAbove(aboveView: verStackView!)
        
        if !isJoinRoom {
            previewFuncButtons()
        }
    }
}

extension ReceiverSignalViewController: RoomDelegate {
    func room(_ room: Room, didFailToConnectWithError error: LiveKitError?) {
        onConnectFailure?()
        dismiss()
    }
    
    func room(_ room: Room, didUpdateConnectionState connectionState: ConnectionState, from oldValue: ConnectionState) {
        print("connection state did update")
        DispatchQueue.main.async { [self] in
            if case .disconnected = connectionState {
                onDisconnect?()
            } else if case .connected = connectionState {
                publishMicrophone()
            }
        }
    }
    
    func room(_ room: Room, participantDidDisconnect participant: RemoteParticipant) {
        print("\(#function)")
    }
    
    func room(_ room: Room, participant localParticipant: LocalParticipant, didPublishTrack publication: LocalTrackPublication) {
        print("\(#function)")
        DispatchQueue.main.async { [self] in
            onlineFuncButtons()
            linkingTimer()
            showLinkingView(show: false)
        }
        guard let track = localParticipant.firstCameraVideoTrack else {
            print("receiver did publish track return")
            return
        }
        
        DispatchQueue.main.async { [self] in
            self.smallTrack = track
//            self.smallVideoView.track = track
        }
    }
    
    func room(_ room: Room, participantDidConnect participant: RemoteParticipant) {
        print("\(#function)")
    }
    
    func room(_ room: Room, participant: RemoteParticipant, didSubscribeTrack publication: RemoteTrackPublication) {
        print("\(#function)")
        DispatchQueue.main.async { [self] in
            if isVideo {
                if let track = participant.firstCameraVideoTrack {
//                    bigVideoView.track = track
                    self.bigTrack = track
                }
                verStackView?.isHidden = true
            }
        }
    }
    
    func room(_ room: Room, participant: RemoteParticipant, didUnsubscribeTrack publication: RemoteTrackPublication) {
        if linkedTimer != nil, participant.identity?.stringValue == inviter().first?.userID {
            linkedTimer = nil
            DispatchQueue.main.async { [self] in
                if !room.allParticipants.isEmpty {
                     onBeHungup?(linkingDuration)
                }
            }
        }
    }
    
    func room(_ room: Room, participant: Participant, trackPublication publication: TrackPublication, didUpdateIsMuted muted: Bool) {        
        if publication.kind == .video, publication.source != .microphone {
            DispatchQueue.main.async { [self] in
                let participantUser = CallingUserInfo(userID: participant.identity?.stringValue, nickname: participant.showName, faceURL: participant.faceURL)

                if let user = inviter().first, participant.identity?.stringValue == user.userID {
                    remoteMuted = muted
                    
                    if smallViewIsMe {
                        bigDisableVideoImageView.isHidden = !muted
                        setupBigPlaceholerView(user: participantUser)
                    } else {
                        smallDisableVideoImageView.isHidden = !muted
                        setupSmallPlaceholerView(user: participantUser)
                    }
                } else if let user = users().first, participant.identity?.stringValue == user.userID {
                    localMuted = muted
                    
                    if smallViewIsMe {
                        smallDisableVideoImageView.isHidden = !muted
                        setupSmallPlaceholerView(user: participantUser)
                    } else {
                        bigDisableVideoImageView.isHidden = !muted
                        setupBigPlaceholerView(user: participantUser)
                    }
                }
            }
        }
    }
}

