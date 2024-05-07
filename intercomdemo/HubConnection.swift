//
//  Video Render.swift
//  intercomdemo
//
//  Created by Luke Suter on 03/05/2024.
//

import Foundation
import UIKit
import WebRTC
import SignalRClient

extension ViewController: HubConnectionDelegate {
    
    func setupSignalR() {
        connection = HubConnectionBuilder(url: URL(string: "https://dev-video-chat-api.oski.site/call-hub")!)
            .withLogging(minLogLevel: .info)
            .build()
        connection?.start()
    }
    
    func setupSignalRAuth(){
        print("Attempt to create login connection.")
        self.chatHubConnectionDelegate = ChatHubConnectionDelegate(controller: self)

        let connection = HubConnectionBuilder(url: URL(string: "https://video-chat-api.oski.site/call-hub")!)
            .withHttpConnectionOptions(configureHttpOptions: { (options) in
                options.accessTokenProvider = { return self.authtoken}
            })
            .withLogging(minLogLevel: .debug)
            .withHubConnectionDelegate(delegate: chatHubConnectionDelegate!)
            .build()
        
        connection.start()
    }
    
    func createPeerConnection() -> RTCPeerConnection? {
        print("Attempt to create peer connection.")
        let configuration = RTCConfiguration()
        configuration.iceServers = [RTCIceServer(urlStrings: ["stun:stun.l.google.com:19302"])]
        let constraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
        return RTCPeerConnectionFactory().peerConnection(with: configuration, constraints: constraints, delegate: nil)
    }

    func onReceiveCall(callId: String, offer: String) {
        print("call rec")
        guard let peerConnection = self.createPeerConnection() else {
            print("Failed to create peer connection.")
            return
        }
        self.peerConnection = peerConnection

        // Create an RTCSessionDescription with the offer
        let offerSD = RTCSessionDescription(type: .offer, sdp: offer)
        peerConnection.setRemoteDescription(offerSD) { error in
            if let error = error {
                print("Failed to set remote description: \(error)")
                return
            }

            // Create an answer to the offer
            peerConnection.answer(for: RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)) { answerSD, error in
                guard let answerSD = answerSD else {
                    print("Error creating answer: \(error!)")
                    return
                }

                // Set the local description with the answer
                peerConnection.setLocalDescription(answerSD) { error in
                    if let error = error {
                        print("Error setting local description: \(error)")
                        return
                    }

                    // Send the answer back to the server to complete the call setup
                    self.joinCall(callId: callId, answer: answerSD.sdp)
                }
            }
        }
    }


    func onIceCandidateReceived(candidate: RTCIceCandidate) {
        // Check if the peerConnection is available
        guard let peerConnection = self.peerConnection else {
            print("PeerConnection not initialized when trying to add ICE candidate.")
            return
        }

        // Add the ICE candidate to the peer connection
        peerConnection.add(candidate) { error in
            if let error = error {
                print("Failed to add ICE candidate: \(error)")
            } else {
                print("ICE candidate added successfully.")
            }
        }
    }

    func joinCall(callId: String, answer: String) {
        connection?.invoke(method: "JoinCall", arguments: [callId, answer]) { error in
            if let error = error {
                print("Error joining call: \(error)")
            } else {
                print("Successfully joined call")
            }
        }
    }

    func sendCandidate(callId: String, candidate: String) {
        connection?.invoke(method: "SendCandidate", arguments: [callId, candidate]) { error in
            if let error = error {
                print("Error sending candidate: \(error)")
            } else {
                print("Candidate sent successfully")
            }
        }
    }

    func leaveCall(callId: String) {
        connection?.invoke(method: "LeaveCall", arguments: [callId]) { error in
            if let error = error {
                print("Error leaving call: \(error)")
            } else {
                print("Successfully left the call")
            }
        }
    }

    func connectionDidOpen(hubConnection: SignalRClient.HubConnection) {
        print("connection Open")
    }
    
    func connectionDidFailToOpen(error: Error) {
        print("connection Fail")
    }
    
    func connectionDidClose(error: Error?) {
        print("connection Close")
    }
    
    func connectionDidReconnect() {
        print("connection reconnect")
    }
    
}

class ChatHubConnectionDelegate: HubConnectionDelegate {

    weak var controller: ViewController?

    init(controller: ViewController) {
        self.controller = controller
    }

    func connectionDidOpen(hubConnection: HubConnection) {
        controller?.connectionDidOpen(hubConnection: hubConnection)
    }

    func connectionDidFailToOpen(error: Error) {
        controller?.connectionDidFailToOpen(error: error)
    }

    func connectionDidClose(error: Error?) {
        controller?.connectionDidClose(error: error)
    }

    func connectionWillReconnect(error: Error) {
        controller?.connectionWillReconnect(error: error)
    }

    func connectionDidReconnect() {
        controller?.connectionDidReconnect()
    }
}
