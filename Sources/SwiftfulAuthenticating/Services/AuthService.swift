import SwiftUI

@MainActor
public protocol AuthService: Sendable {
    func getAuthenticatedUser() -> UserAuthInfo?
    func addAuthenticatedUserListener() -> AsyncStream<UserAuthInfo?>
    func signIn(option: SignInOption) async throws -> (user: UserAuthInfo, isNewUser: Bool)
    func signOut() throws
    func deleteAccount() async throws
    
    func createUserWithEmail(email: String, password: String) async throws -> (user: UserAuthInfo, isNewUser: Bool)
//    func signInWithEmail(email: String, password: String) async throws -> (user: UserAuthInfo, isNewUser: Bool)
    func sendPasswordReset(email: String) async throws
    func updatePassword(for userId: String, newPassword: String) async throws
    func updateEmail(for userId: String, newEmail: String) async throws
}

extension AuthService {
    func updatePassword(for userId: String, newPassword: String) async throws {
        throw MockError.notImplemented
    }
}
