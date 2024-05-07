//
//  API.swift
//  intercomdemo
//
//  Created by Luke Suter on 02/05/2024.
//

import Foundation

public class VIntercomAPI {
    
    public func registerUser(email: String, password: String, firstName: String, lastName: String, userName: String, completion: @escaping (String) -> Void){
        let url = "https://video-chat-api.oski.site/api/auth/register"
        
        let parameters: [String: Any] = [
            "email": email,
            "password": password,
            "firstname": firstName,
            "lastname": lastName,
            "userName": userName
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: parameters) else {
            completion("Invalid JSON data")
            return
        }
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: parameters) else {
            completion("Invalid JSON data")
            return
        }
        
        var request = URLRequest(url: URL(string: url)!)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("text/plain", forHTTPHeaderField: "accept")
        request.httpBody = jsonData
        
        let session = URLSession.shared
        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                completion("Error making request: \(error)")
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion("Invalid response received from the server")
                return
            }
            
            switch httpResponse.statusCode {
            case 201:
                completion("User successfully registered.")
            case 400:
                guard let data = data else {
                    completion("Error: No data in response")
                    return
                }
                
                do {
                    let errorResponse = try JSONDecoder().decode(VIntercomAPIError.self, from: data)
                                   completion("Failed to register user: \(errorResponse.errors.first?.message ?? "Unknown error")")
                } catch {
                    completion("\(error)")
                }
            default:
                completion("Unhandled HTTP response status code: \(httpResponse.statusCode)")
            }
        }
        
        task.resume()
    }

    func loginUser(
        login: String, password: String, remember: Bool,
        onSuccess: @escaping (LoginResponse) -> Void,
        onFailure: @escaping (String) -> Void
    ) {
        let url = "https://video-chat-api.oski.site/api/auth/login"
        
        let parameters: [String: Any] = [
            "login": login,
            "password": password,
            "remember": remember
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: parameters) else {
            onFailure("Invalid JSON data")
            return
        }
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: parameters) else {
            onFailure("Invalid JSON data")
            return
        }
        
        var request = URLRequest(url: URL(string: url)!)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("text/plain", forHTTPHeaderField: "accept")
        request.httpBody = jsonData
        
        let session = URLSession.shared
        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                onFailure("Error making request: \(error)")
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse, let data = data else {
                onFailure("Invalid response received from the server")
                return
            }
            
            if httpResponse.statusCode == 200 {
                do {
                    let decoder = JSONDecoder()
                        // Custom date decoding strategy
                        let dateFormatter = DateFormatter()
                            dateFormatter.dateFormat="yyyy-MM-dd'T'HH:mm:ss.SSSZ"
                                decoder.dateDecodingStrategy = .formatted(dateFormatter)
                                    
                        let loginResponse = try decoder.decode(LoginResponse.self, from: data)
                                    
                        onSuccess(loginResponse)
                                    
                } catch {
                    onFailure("Error decoding response: \(error)")
                }
            } else if httpResponse.statusCode == 400 {
                do {
                    let errorResponse = try JSONDecoder().decode(VIntercomAPIError.self, from: data)
                    onFailure("Failed to authenticate user: \(errorResponse.errors.first?.message ?? "Unknown error")")
                } catch {
                    onFailure("Error decoding error response: \(error)")
                }
            } else {
                onFailure("Unhandled HTTP response status code: \(httpResponse.statusCode)")
            }
        }
        
        task.resume()
    }
}
