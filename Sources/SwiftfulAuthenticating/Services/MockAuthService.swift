//
//  MockAuthService.swift
//  SwiftfulAuthenticating
//
//  Created by Nick Sarno on 9/28/24.
//
import SwiftUI

@MainActor
public class MockAuthService: AuthService {
    @Published private(set) var currentUser: UserAuthInfo?

    public init(user: UserAuthInfo? = nil) {
        self.currentUser = user
    }

    public func getAuthenticatedUser() -> UserAuthInfo? {
        currentUser
    }

    public func addAuthenticatedUserListener() -> AsyncStream<UserAuthInfo?> {
        AsyncStream { continuation in
            Task {
                for await value in $currentUser.values {
                    continuation.yield(value)
                }
            }
        }
    }
    
    public func removeAuthenticatedUserListener() {
        
    }

    public func signOut() throws {
        currentUser = nil
    }

    public func signIn(option: SignInOption) async throws -> (user: UserAuthInfo, isNewUser: Bool) {
        switch option {
        case .apple, .google, .anonymous, .email:
            let user = UserAuthInfo.mock(isAnonymous: false)
            currentUser = user
            return (user, false)
        }
    }

    public func deleteAccount() async throws {
        currentUser = nil
    }

    // New methods
    public func createUserWithEmail(email: String, password: String) async throws -> (user: UserAuthInfo, isNewUser: Bool) {
        guard email.contains("@") else { throw MockError.invalidEmail }
        let user = UserAuthInfo(
            uid: UUID().uuidString,
            email: email,
            authProviders: [.email],
            creationDate: .now,
            lastSignInDate: .now
        )
        currentUser = user
        return (user, true)
    }

    
    public func signInWithEmail(email: String, password: String) async throws -> (user: UserAuthInfo, isNewUser: Bool) {
            // Simulating email sign-in logic
            guard let currentUser = currentUser, currentUser.email == email else {
                throw MockError.invalidCredentials
            }
            
            // You might want to add password validation logic here
            return (currentUser, false)
        }
    
    
    public func sendPasswordReset(email: String) async throws {
        guard currentUser?.email == email else {
            throw MockError.userNotFound
        }
        // Simulate a password reset success.
    }

    public func updatePassword(for userId: String, newPassword: String) async throws {
        guard currentUser?.uid == userId else {
            throw MockError.userNotFound
        }
        // Simulate password update success.
    }

    public func updateEmail(for userId: String, newEmail: String) async throws {
        guard currentUser?.uid == userId else {
            throw MockError.userNotFound
        }
        currentUser = UserAuthInfo(
            uid: currentUser!.uid,
            email: newEmail,
            authProviders: currentUser!.authProviders,
            creationDate: currentUser!.creationDate,
            lastSignInDate: currentUser!.lastSignInDate
        )
    }

}






// Helper for mock-specific errors
enum MockError: Error {
    case invalidEmail
    case invalidCredentials
    case userNotFound
    case notImplemented
}



