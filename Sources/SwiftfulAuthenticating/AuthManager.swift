import Foundation

@MainActor
@Observable
public class AuthManager {
    private let logger: AuthLogger?
    private let service: AuthService

    public private(set) var auth: UserAuthInfo?
    private var taskListener: Task<Void, Error>?

    public init(service: AuthService, logger: AuthLogger? = nil) {
        self.service = service
        self.logger = logger
        self.auth = service.getAuthenticatedUser()
        self.addAuthListener()
    }

    public func getAuthId() throws -> String {
        guard let uid = auth?.uid else {
            throw AuthError.notSignedIn
        }

        return uid
    }

    private func addAuthListener() {        
        // Attach new listener
        taskListener?.cancel()
        taskListener = Task {
            for await value in service.addAuthenticatedUserListener() {
                setCurrentAuth(auth: value)
            }
        }
    }
    
    private func setCurrentAuth(auth value: UserAuthInfo?) {
        self.auth = value

        if let value {
            self.logger?.identifyUser(userId: value.uid, name: value.displayName, email: value.email)
            self.logger?.addUserProperties(dict: value.eventParameters, isHighPriority: true)
            self.logger?.trackEvent(event: Event.authListenerSuccess(user: value))
        } else {
            self.logger?.trackEvent(event: Event.authlistenerEmpty)
        }
    }
    
    @discardableResult
    public func signInAnonymously() async throws -> (user: UserAuthInfo, isNewUser: Bool) {
        let result = try await signIn(option: .anonymous)
        setCurrentAuth(auth: result.user)
        return result
    }
    
    @discardableResult
    public func signInApple() async throws -> (user: UserAuthInfo, isNewUser: Bool) {
        try await signIn(option: .apple)
    }
    
    @discardableResult
    public func signInGoogle(GIDClientID: String) async throws -> (user: UserAuthInfo, isNewUser: Bool) {
        try await signIn(option: .google(GIDClientID: GIDClientID))
    }

    private func signIn(option: SignInOption) async throws -> (user: UserAuthInfo, isNewUser: Bool) {
        self.logger?.trackEvent(event: Event.signInStart(option: option))
        
        defer {
            // After user's auth changes, re-attach auth listener.
            // This isn't usually necessary, but if the user is "linking" to an anonymous account,
            // The Firebase auth listener does not auto-publish new value (since it's the same UID).
            // Re-adding a new listener should catch any catch edge cases.
            addAuthListener()
        }

        do {
            let result = try await service.signIn(option: option)
            setCurrentAuth(auth: result.user)
            logger?.trackEvent(event: Event.signInSuccess(option: option, user: result.user, isNewUser: result.isNewUser))
            return result
        } catch {
            logger?.trackEvent(event: Event.signInFail(error: error))
            throw error
        }
    }

    public func signOut() throws {
        self.logger?.trackEvent(event: Event.signOutStart)

        do {
            try service.signOut()
            auth = nil
            logger?.trackEvent(event: Event.signOutSuccess)
        } catch {
            logger?.trackEvent(event: Event.signOutFail(error: error))
            throw error
        }
    }

    public func deleteAccount() async throws {
        self.logger?.trackEvent(event: Event.deleteAccountStart)

        do {
            try await service.deleteAccount()
            auth = nil
            logger?.trackEvent(event: Event.deleteAccountSuccess)
        } catch {
            logger?.trackEvent(event: Event.deleteAccountFail(error: error))
            throw error
        }
    }

    public enum AuthError: Error {
        case notSignedIn
    }


    // MARK: Email & Password Auth Operation
        
        @discardableResult
            public func createUserWithEmail(email: String, password: String) async throws -> (user: UserAuthInfo, isNewUser: Bool) {
                self.logger?.trackEvent(event: Event.createUserStart(email: email))
                do {
                    let result = try await service.createUserWithEmail(email: email, password: password)
                    setCurrentAuth(auth: result.user)
                    self.logger?.trackEvent(event: Event.createUserSuccess(email: email, user: result.user))
                    return result
                } catch {
                    self.logger?.trackEvent(event: Event.createUserFail(email: email, error: error))
                    throw error
                }
            }
    
            
            @discardableResult
            public func signInWithEmail(email: String, password: String) async throws -> (user: UserAuthInfo, isNewUser: Bool) {
                self.logger?.trackEvent(event: Event.signInStart(option: .email))
                
                do {
                    let result = try await service.signInWithEmail(email: email, password: password)
                    setCurrentAuth(auth: result.user)
                    logger?.trackEvent(event: Event.signInSuccess(
                        option: .email,
                        user: result.user,
                        isNewUser: result.isNewUser
                    ))
                    return result
                } catch {
                    logger?.trackEvent(event: Event.signInFail(error: error))
                    throw error
                }
            }

            public func resetPassword(email: String) async throws {
                self.logger?.trackEvent(event: Event.resetPasswordStart(email: email))
                do {
                    try await service.sendPasswordReset(email: email)
                    self.logger?.trackEvent(event: Event.resetPasswordSuccess(email: email))
                } catch {
                    self.logger?.trackEvent(event: Event.resetPasswordFail(email: email, error: error))
                    throw error
                }
            }

            public func updatePassword(newPassword: String) async throws {
                guard let userId = auth?.uid else {
                    throw AuthError.notSignedIn
                }
                self.logger?.trackEvent(event: Event.updatePasswordStart(userId: userId))
                do {
                    try await service.updatePassword(for: userId, newPassword: newPassword)
                    self.logger?.trackEvent(event: Event.updatePasswordSuccess(userId: userId))
                } catch {
                    self.logger?.trackEvent(event: Event.updatePasswordFail(userId: userId, error: error))
                    throw error
                }
            }

            public func updateEmail(newEmail: String) async throws {
                guard let userId = auth?.uid else {
                    throw AuthError.notSignedIn
                }
                self.logger?.trackEvent(event: Event.updateEmailStart(userId: userId, email: newEmail))
                do {
                    try await service.updateEmail(for: userId, newEmail: newEmail)
                    self.logger?.trackEvent(event: Event.updateEmailSuccess(userId: userId, email: newEmail))
                } catch {
                    self.logger?.trackEvent(event: Event.updateEmailFail(userId: userId, email: newEmail, error: error))
                    throw error
                }
            }

            

            

    }

    extension AuthManager {
        enum Event: AuthLogEvent {
            case authListenerSuccess(user: UserAuthInfo)
            case authlistenerEmpty
            case signInStart(option: SignInOption)
            case signInSuccess(option: SignInOption, user: UserAuthInfo, isNewUser: Bool)
            case signInFail(error: Error)
            case signOutStart
            case signOutSuccess
            case signOutFail(error: Error)
            case deleteAccountStart
            case deleteAccountSuccess
            case deleteAccountFail(error: Error)

            
            // New email/password cases
            case createUserStart(email: String)
            case createUserSuccess(email: String, user: UserAuthInfo)
            case createUserFail(email: String, error: Error)
            case resetPasswordStart(email: String)
            case resetPasswordSuccess(email: String)
            case resetPasswordFail(email: String, error: Error)
            case updatePasswordStart(userId: String)
            case updatePasswordSuccess(userId: String)
            case updatePasswordFail(userId: String, error: Error)
            case updateEmailStart(userId: String, email: String)
            case updateEmailSuccess(userId: String, email: String)
            case updateEmailFail(userId: String, email: String, error: Error)
            
            var eventName: String {
                switch self {
                case .authListenerSuccess: return         "Auth_Listener_Success"
                case .authlistenerEmpty: return           "Auth_Listener_Empty"
                case .signInStart: return                 "Auth_SignIn_Start"
                case .signInSuccess: return               "Auth_SignIn_Success"
                case .signInFail: return                  "Auth_SignIn_Fail"
                case .signOutStart: return                "Auth_SignOut_Start"
                case .signOutSuccess: return              "Auth_SignOut_Success"
                case .signOutFail: return                 "Auth_SignOut_Fail"
                case .deleteAccountStart: return          "Auth_DeleteAccount_Start"
                case .deleteAccountSuccess: return        "Auth_DeleteAccount_Success"
                case .deleteAccountFail: return           "Auth_DeleteAccount_Fail"
                case .createUserStart: return             "Auth_CreateUser_Start"
                case .createUserSuccess: return           "Auth_CreateUser_Success"
                case .createUserFail: return              "Auth_CreateUser_Fail"
                case .resetPasswordStart: return          "Auth_ResetPassword_Start"
                case .resetPasswordSuccess: return        "Auth_ResetPassword_Success"
                case .resetPasswordFail: return           "Auth_ResetPassword_Fail"
                case .updatePasswordStart: return         "Auth_UpdatePassword_Start"
                case .updatePasswordSuccess: return       "Auth_UpdatePassword_Success"
                case .updatePasswordFail: return          "Auth_UpdatePassword_Fail"
                case .updateEmailStart: return            "Auth_UpdateEmail_Start"
                case .updateEmailSuccess: return          "Auth_UpdateEmail_Success"
                case .updateEmailFail: return             "Auth_UpdateEmail_Fail"
                }
            }

            var parameters: [String: Any]? {
                switch self {
                case .authListenerSuccess(user: let user):
                    return user.eventParameters
                case .signInStart(option: let option):
                    return option.eventParameters
                case .signInSuccess(option: let option, user: let user, isNewUser: let isNewUser):
                    var dict = user.eventParameters
                    dict.merge(option.eventParameters)
                    dict["is_new_user"] = isNewUser
                    return dict
                case .signInFail(error: let error), .signOutFail(error: let error), .deleteAccountFail(error: let error):
                    return error.eventParameters
                    
                
                case .createUserStart(let email), .resetPasswordStart(let email):
                    return ["email": email]
                case .createUserSuccess(let email, let user):
                    var params = user.eventParameters
                                params["email"] = email
                                return params
                case .createUserFail(let email, let error):
                    return ["email": email, "error_message": error.eventParameters]
                case .resetPasswordSuccess(let email):
                    return ["email": email]
                case .resetPasswordFail(let email, let error):
                    return ["email": email, "error_message": error.eventParameters]
                case .updatePasswordStart(let userId),.updatePasswordSuccess(let userId):
                    return ["user_id": userId]
                case .updatePasswordFail(let userId, let error):
                    return ["user_id": userId, "error_message": error.eventParameters]
                case .updateEmailStart(let userId, let email),.updateEmailSuccess(let userId, let email):
                    return ["user_id": userId, "new_email": email]
                case .updateEmailFail(let userId, let email, let error):
                    return ["user_id": userId, "new_email": email, "error_message": error.eventParameters]
                    
                default:
                    return nil
                }
            }

            var type: AuthLogType {
                switch self {
                case .signInFail, .signOutFail, .deleteAccountFail:
                    return .severe
                case .authlistenerEmpty:
                    return .warning
                default:
                    return .info
                }
            }
        }
    }
