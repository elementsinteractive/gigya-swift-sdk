//
//  SignInEmailViewModel.swift
//  BitsBytes
//
//  Created by Sagi Shmuel on 06/03/2024.
//

import Foundation
import Gigya

final class SignInEmailViewModel: BaseViewModel {
    var currentCordinator: ProfileCoordinator?

    @Published var formIsSubmitState: Bool = false
    @Published var email: String = ""
    @Published var pass: String = ""
    @Published var error: String = ""
    
    func submit(closure: @escaping ()-> Void) {
        formIsSubmitState = true
        toggelLoader()
        
        if (!email.isEmpty && !pass.isEmpty) {
            guard let gigya = gigya else {
                self.error = "Genral error"
                return
            }
            
            gigya.shared.login(loginId: email, password: pass) { [ weak self] result in
                guard let self = self else { return }
                
                toggelLoader()
                
                switch result {
                case .success(data: _):
                    closure()
                case .failure(let error):
                    switch error.error {
                    case .gigyaError(let data):
                        self.error = data.errorMessage ?? "Genral Error"
                    default:
                        self.error = "Genral Error"
                    }
                }
            }
        }
    }
    
    func showPass() {
        currentCordinator?.routing.push(.resetPassword)
    }
}
