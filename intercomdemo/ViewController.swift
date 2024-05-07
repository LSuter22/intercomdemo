//
//  ViewController.swift
//  intercomdemo
//
//  Created by Luke Suter on 01/05/2024.
//

import UIKit
import SignalRClient
import WebRTC

class ViewController: UIViewController {
    @IBOutlet weak var videoViewContainer: UIView! // Connect this IBOutlet to your UIView in the storyboard
    @IBOutlet weak var endButton: UIButton!
    
    @IBAction func endcallPress(){
        print("Ending call...")
                // Send a message to the server to leave the call
        connection?.invoke(method: "LeaveCall", arguments: ["YourCallIdHere"], invocationDidComplete: { error in
                    if let error = error {
                        print("Error leaving call: \(error)")
                    }
                })
                
    // Close the peer connection
        peerConnection?.close()  // Close the peer connection
        peerConnection = nil
    }

    var remoteVideoView: RTCVideoRenderer!
    var peerConnection: RTCPeerConnection?  // WebRTC Peer Connection
    private var API = VIntercomAPI()
    private let serverUrl = "https://video-chat-api.oski.site/call-hub"
    var connection: HubConnection?
    var chatHubConnectionDelegate: HubConnectionDelegate?

    
    var authtoken = ""
    var refreshtoken = ""
    var authObject = TokenInfo(policy: "", token: "", expires: Date())
    
    var token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJlOGI5ZTg2Mi0yN2QyLTQ1MzItYjhhMy02ZTcwMzY0NDZjMWYiLCJuYW1lIjoicmVzaWRlbnQyMjYiLCJlbWFpbCI6InJlc2lkZW50QGludGVyY29tLmNvbSIsImV4cCI6MTY4ODEyNTA4NywiaXNzIjoiaHR0cDovL2xvY2FsaG9zdDo3Mjg4IiwiYXVkIjoiaHR0cDovL2xvY2FsaG9zdDozMDAwIn0.l-jqekLWWeKuCV3YPbD03lYx0LpIfPsn8DqdojyeLHs"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "Virtual Intercom"
        setupRemoteVideoView()
        
        API.loginUser(
            login: "LukeSuter", password: "Tlj23456!", remember: true,
            onSuccess: { loginResponse in
                print("User successfully authenticated. Auth Token: \(loginResponse.authToken.token)")
                DispatchQueue.main.async {
                    self.authtoken = loginResponse.authToken.token
                    self.refreshtoken = loginResponse.refreshToken.token
                    self.authObject = loginResponse.authToken
                    self.setupSignalRAuth()
                    self.peerConnection = self.createPeerConnection()
                }
            },
            onFailure: { errorMessage in
                print(errorMessage)
            }
        )
        
    }
    
    private func setupRemoteVideoView() {
        // Use RTCMTLVideoView directly if targeting iOS 9.0 or later
        let metalVideoView = RTCMTLVideoView(frame: videoViewContainer.bounds)
        metalVideoView.videoContentMode = .scaleAspectFill // Ensures video covers the entire UIView while maintaining aspect ratio
        videoViewContainer.addSubview(metalVideoView)
        remoteVideoView = metalVideoView

        // Set constraints for auto-resizing
        metalVideoView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            metalVideoView.topAnchor.constraint(equalTo: videoViewContainer.topAnchor),
            metalVideoView.bottomAnchor.constraint(equalTo: videoViewContainer.bottomAnchor),
            metalVideoView.leadingAnchor.constraint(equalTo: videoViewContainer.leadingAnchor),
            metalVideoView.trailingAnchor.constraint(equalTo: videoViewContainer.trailingAnchor)
        ])
    }
}
