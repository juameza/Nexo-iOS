//
//  RegisterViewController.swift
//  RoadmapSwift
//
//  Created by MMJ on 01/10/26.
//

import Foundation
import UIKit

// Delegate PROPIO la pantall de Registro avisa "ya se creo la cuenta" sin saber quien la abrio
// AnyObject solo las clases pueden adoptarlo, y eso permite que la referencia sea weak
protocol RegisterViewControllerDelegate: AnyObject {
    func registerViewController(_ controller: RegisterViewController, didRegister account: NewAccount)
}


final class RegisterViewController: UIViewController {
    
    // MARK: - Outlets
    @IBOutlet private weak var nameTextField: UITextField!
    @IBOutlet private weak var emailTextField: UITextField!
    @IBOutlet private weak var passwordTextField: UITextField!
    @IBOutlet private weak var confirmPasswordTextField: UITextField!
    @IBOutlet private weak var rulesLabel: UILabel!
    @IBOutlet private weak var errorLabel: UILabel!
    @IBOutlet private weak var registerButton: UIButton!
    
    // MARK: - Entrada (la llena el login en prepare(for: sender:))
    // 🟤 Con segues el storyboard crear esta pantalla con init(coder:), asi que no podemos
    // pedir el email en un init propio: por eso es var y opcional
    var prefilledEmail: String?
    
    // weak: evita un retain cycle. Quien nos abrio (el login) ya tiene su propia vida.
    weak var delegate: RegisterViewControllerDelegate?
    
    // MARK: - Dependencias
    private let passwordValidator = PasswordValidator()
    
    // Orden de los campos para avanzar con la tecla Return
    private var orderedFields: [UITextField] {
        [nameTextField, emailTextField, passwordTextField, confirmPasswordTextField]
    }
    
    // MARK: - Ciclo de vida
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Crear cuenta"
        emailTextField.text = prefilledEmail
        errorLabel.isHidden = true
        orderedFields.forEach { $0.delegate = self }
        updateRules(for: "")
    }
    
    // MARK: - Acciones
    // Conectada al evento **Editing Changed** del campo de contraseña: se llama en cada tecla
    @IBAction private func passwordChanged(_ sender: UITextField) {
        updateRules(for: sender.text ?? "")
    }
    
    @IBAction private func registerButtonTapped(_ sender: UIButton) {
        view.endEditing(true)
        
        let form = RegistrationForm(
            displayName: nameTextField.text ?? "",
            email: emailTextField.text ?? "",
            password: passwordTextField.text ?? "",
            passwordConfirmation: confirmPasswordTextField.text ?? ""
        )
        
        switch form.validate() {
        case .failure(let error):
            errorLabel.text = error.message
            errorLabel.isHidden = false
        case .success(let account):
            errorLabel.isHidden = true
            // Avisamos y NADA mas: cerrar la pantalla le toca a quien la abrio
            delegate?.registerViewController(self, didRegister: account)
        }
    }
    
    // MARK: - Helpers
    private func updateRules(for password: String) {
        let failedRules = passwordValidator.failedRules(for: password)
        // map + joined: convierte cada regla en una linea de texto.
        rulesLabel.text = PasswordRule.allCases
            .map { rule in (failedRules.contains(rule) ? "O " : "✅ ") + rule.message }
            .joined(separator: "\n")
    }
        
        
}


// MARK: - UITextFieldDelegate
extension RegisterViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        let fields = orderedFields
        // === (identidad Dia 1): buscamos ESTE campo, no uno igual
        if let index = fields.firstIndex(where: { $0 === textField }), index + 1 < fields.count {
            fields[index + 1].becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
            registerButtonTapped(registerButton)
        }
        return true
    }
}
