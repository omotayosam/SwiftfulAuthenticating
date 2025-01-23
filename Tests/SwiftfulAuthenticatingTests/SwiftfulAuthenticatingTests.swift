import Testing
import SwiftUI
import Foundation
@testable import SwiftfulAuthenticating

@MainActor
struct AuthManagerTests {

    @Test("AuthManager initializes with the provided authenticated user")
    func testInitializationWithAuthenticatedUser() async throws {
        // Given
        let uid = UUID().uuidString
        let name = UUID().uuidString
        let email = "\(UUID().uuidString)@example.com"
        
        let mockUser = UserAuthInfo(uid: uid, email: email, displayName: name)
        let authService = MockAuthService(user: mockUser)

        // When
        let authManager = AuthManager(service: authService)

        // Then
        #expect(authManager.auth?.uid == uid)
    }

    @Test("AuthManager initializes with nil auth if no user is authenticated")
    func testInitializationWithNoAuthenticatedUser() async throws {
        // Given
        let authService = MockAuthService()

        // When
        let authManager = AuthManager(service: authService)

        // Then
        #expect(authManager.auth == nil)
    }

//    @Test("AuthManager signs in successfully and logs events")
//    func testSignInSuccess() async throws {
//        // Given
//        
//        let authService = MockAuthService()
//        let authManager = AuthManager(service: authService)
//
//        // When
//        let result = try await authManager.signIn(option: .anonymous)
//
//        // Then
//        #expect(result.user.uid != nil)
//    }

    @Test("AuthManager handles sign-in failure and logs the error")
    func testSignInFailure() async throws {
        // Fixme: mock isn't testable?
    }

    @Test("AuthManager signs out successfully and logs events")
    func testSignOut() async throws {
        // Given
        let authService = MockAuthService(user: UserAuthInfo.mock())
        let authManager = AuthManager(service: authService)

        // When
        try authManager.signOut()

        // Then
        #expect(authManager.auth == nil)
    }

    @Test("AuthManager deletes account successfully and logs events")
    func testDeleteAccount() async throws {
        // Given
        let authService = MockAuthService(user: UserAuthInfo.mock())
        let authManager = AuthManager(service: authService)

        // When
        try await authManager.deleteAccount()

        // Then
        #expect(authManager.auth == nil)
    }

    @Test("AuthManager creates user with email successfully")
    func testCreateUserWithEmailSuccess() async throws {
        // Given
        let authService = MockAuthService()
        let authManager = AuthManager(service: authService)
        let testEmail = "test@example.com"
        let testPassword = "password123"

        // When
        let result = try await authManager.createUserWithEmail(email: testEmail, password: testPassword)

        // Then
        #expect(result.isNewUser == true)
        #expect(result.user.email == testEmail)
        #expect(authManager.auth?.email == testEmail)
        #expect(result.user.authProviders.contains(.email))
    }

    @Test("AuthManager throws error when creating user with invalid email")
    func testCreateUserWithInvalidEmail() async {
        // Given
        let authService = MockAuthService()
        let authManager = AuthManager(service: authService)
        let invalidEmail = "invalid-email"
        let testPassword = "password123"

        // When/Then
        do {
            _ = try await authManager.createUserWithEmail(
                email: invalidEmail,
                password: testPassword
            )
            #expect(Bool(false), "Expected to throw MockError.invalidEmail")
        } catch {
            #expect(error as? MockError == MockError.invalidEmail)
            #expect(authManager.auth == nil)
        }
    }

    @Test("AuthManager sends password reset successfully")
    func testSendPasswordResetSuccess() async throws {
        // Given
        let testEmail = "test@example.com"
        let user = UserAuthInfo(
            uid: UUID().uuidString,
            email: testEmail,
            authProviders: [.email],
            creationDate: .now,
            lastSignInDate: .now
        )
        let authService = MockAuthService(user: user)
        let authManager = AuthManager(service: authService)

        // When/Then
        try await authManager.resetPassword(email: testEmail)
        // Test passes if no error is thrown
    }

    @Test("AuthManager throws error when resetting password for non-existent user")
    func testSendPasswordResetForNonExistentUser() async {
        // Given
        let authService = MockAuthService()
        let authManager = AuthManager(service: authService)
        let testEmail = "nonexistent@example.com"

        // When/Then
        do {
            try await authManager.resetPassword(email: testEmail)
            #expect(Bool(false), "Expected to throw MockError.userNotFound")
        } catch {
            #expect(error as? MockError == MockError.userNotFound)
            #expect(authManager.auth == nil)
        }
    }

    @Test("AuthManager updates password successfully")
    func testUpdatePasswordSuccess() async throws {
        // Given
        let user = UserAuthInfo.mock()
        let authService = MockAuthService(user: user)
        let authManager = AuthManager(service: authService)
        let newPassword = "newPassword123"

        // When/Then
        try await authManager.updatePassword(newPassword: newPassword)
        // Test passes if no error is thrown
    }

    @Test("AuthManager throws error when updating password without being signed in")
    func testUpdatePasswordWithoutAuth() async {
        // Given
        let authService = MockAuthService()
        let authManager = AuthManager(service: authService)
        let newPassword = "newPassword123"

        // When/Then
        do {
            try await authManager.updatePassword(newPassword: newPassword)
            #expect(Bool(false), "Expected to throw AuthManager.AuthError.notSignedIn")
        } catch {
            #expect(error as? AuthManager.AuthError == AuthManager.AuthError.notSignedIn)
            #expect(authManager.auth == nil)
        }
    }

    @Test("AuthManager updates email successfully")
    func testUpdateEmailSuccess() async throws {
        // Given
        let originalEmail = "hello@gmail.com"
        let user = UserAuthInfo(
            uid: UUID().uuidString,
            email: originalEmail,
            authProviders: [.email],
            creationDate: .now,
            lastSignInDate: .now
        )
        let authService = MockAuthService(user: user)
        let authManager = AuthManager(service: authService)
        let newEmail = "newemail@example.com"

        // Verify initial state
        #expect(authManager.auth?.email == originalEmail)

        // When
        try await authManager.updateEmail(newEmail: newEmail)
        
        // Wait a 0.1sec for the auth listener to process the change
        try await Task.sleep(nanoseconds: 100_000_000)

        // Then
        #expect(authManager.auth?.email == newEmail)
    }

    @Test("AuthManager throws error when updating email without being signed in")
    func testUpdateEmailWithoutAuth() async {
        // Given
        let authService = MockAuthService()
        let authManager = AuthManager(service: authService)
        let newEmail = "newemail@example.com"

        // When/Then
        do {
            try await authManager.updateEmail(newEmail: newEmail)
            #expect(Bool(false), "Expected to throw AuthManager.AuthError.notSignedIn")
        } catch {
            #expect(error as? AuthManager.AuthError == AuthManager.AuthError.notSignedIn)
            #expect(authManager.auth == nil)
        }
    }
    
    
    
    @Test("AuthManager signs in with email successfully")
    func testSignInWithEmailSuccess() async throws {
        // Given
        let email = "test@example.com"
        let password = "password123"
        let user = UserAuthInfo(
            uid: UUID().uuidString,
            email: email,
            authProviders: [.email],
            creationDate: .now,
            lastSignInDate: .now
        )
        let authService = MockAuthService(user: user)
        let authManager = AuthManager(service: authService)

        // When
        let result = try await authManager.signInWithEmail(email: email, password: password)

        // Then
        #expect(result.user.email == email)
        #expect(authManager.auth?.email == email)
        #expect(result.isNewUser == false)
    }

    @Test("AuthManager throws error when signing in with invalid credentials")
    func testSignInWithEmailInvalidCredentials() async {
        // Given
        let authService = MockAuthService()
        let authManager = AuthManager(service: authService)
        let email = "test@example.com"
        let password = "wrongpassword"

        // When/Then
        do {
            _ = try await authManager.signInWithEmail(email: email, password: password)
            #expect(Bool(false), "Expected to throw MockError.invalidCredentials")
        } catch {
            #expect(error as? MockError == MockError.invalidCredentials)
            #expect(authManager.auth == nil)
        }
    }

    @Test("AuthManager throws error when user does not exist")
    func testSignInWithEmailNonExistentUser() async {
        // Given
        let authService = MockAuthService()
        let authManager = AuthManager(service: authService)
        let email = "nonexistent@example.com"
        let password = "anypassword"

        // When/Then
        do {
            _ = try await authManager.signInWithEmail(email: email, password: password)
            #expect(Bool(false), "Expected to throw MockError.invalidCredentials")
        } catch {
            #expect(error as? MockError == MockError.invalidCredentials)
            #expect(authManager.auth == nil)
        }
    }
}

