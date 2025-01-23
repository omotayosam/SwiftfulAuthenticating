//
//  SwiftUIView.swift
//  SwiftfulAuthenticating
//
//  Created by omotayo ayomide on 23/01/2025.
//


import SwiftUI
import AuthenticationServices

public struct SignInEmailButtonView: View {
    private var backgroundColor: Color
    private var foregroundColor: Color
    private var borderColor: Color
    private var buttonText: String
    private var cornerRadius: CGFloat
    private var action: () -> Void // New closure for tap action

    public init(
        type: ASAuthorizationAppleIDButton.ButtonType = .signIn,
        style: ASAuthorizationAppleIDButton.Style = .black,
        cornerRadius: CGFloat = 10,
        action: @escaping () -> Void = {} // Default empty action
    ) {
        self.cornerRadius = cornerRadius
        self.backgroundColor = style.backgroundColor
        self.foregroundColor = style.foregroundColor
        self.borderColor = style.borderColor
        self.buttonText = type.buttonText.removingWord(" with")
        self.action = action
    }
    
    public var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(borderColor)
            
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(backgroundColor)
                .padding(0.8)
            
            HStack(spacing: 8) {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)
                
                Text("\(buttonText) using Email")
                    .font(.system(size: 23))
                    .fontWeight(.medium)
            }
            .foregroundColor(foregroundColor)
        }
        .padding(.vertical, 1)
        .onTapGesture(perform: action)
        .disabled(false) // Remove the hard disable
    }
}
fileprivate extension String {
    func removingWord(_ word: String) -> String {
        let pattern = "\\b\(word)\\b"
        return self.replacingOccurrences(of: pattern, with: "", options: .regularExpression)
    }
}

#Preview("SignInAnonymousButtonView") {
    ScrollView {
        VStack(spacing: 24) {
            ForEach(ASAuthorizationAppleIDButton.Style.allCases, id: \.rawValue) { style in
                ForEach(ASAuthorizationAppleIDButton.ButtonType.allCases, id: \.rawValue) { type in
                    SignInEmailButtonView(type: type, style: style, cornerRadius: 10)
                        .frame(height: 60)
                }
                Divider()
            }
        }
        .padding()
    }
    .background(Color.gray.ignoresSafeArea())
}
