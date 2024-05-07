//
//  API Models.swift
//  intercomdemo
//
//  Created by Luke Suter on 02/05/2024.
//

import Foundation

//MARK: Login Response Models
struct LoginResponse: Codable {
    let authToken: TokenInfo
    let refreshToken: TokenInfo
}

struct TokenInfo: Codable {
    let policy: String
    let token: String
    let expires: Date
}

//MARK: Error Response Models
struct VIntercomAPIError: Codable {
    let errors: [ErrorDetail]
}

struct ErrorDetail: Codable {
    let message: String
}

