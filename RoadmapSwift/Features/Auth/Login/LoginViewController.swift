//
//  LoginViewController.swift
//  RoadmapSwift
//
//  Created by MMJ on 26/09/26.
//

import UIKit

final class LoginViewController: UIViewController {
    
    // MARK: - Outlets
    // 'weak' porque la vista ya los retiene; '!' por que existen despues de la viewDidLoad.
    @IBOutlet private weak var emailTextField: UITextField!
    @IBOutlet private weak var passwordTextField: UITextField!
    @IBOutlet private weak var errorLabel: UILabel!
    @IBOutlet private weak var loginButton: UIButton!
    
    // MARK: - Dependencias
    private let emailValidator =  EmailValidator()

    // MARK: - Ciclo de vida
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        configureUI()
    }
    
    
    
    // MARK: - Configuración
    private func configureUI(){
        title = "Iniciar sesión"
        navigationController?.navigationBar.prefersLargeTitles = false
        
        hideError()
        
        // Patron DELEGATE: el text field le delega a es VC decidir que pasa al persionar Return
        emailTextField.delegate = self
        passwordTextField.delegate = self
    }
    
    
    // MARK: - Acciones (patron TARGET-ACTION)
    @IBAction private func loginButtonTapped(_ sender: UIButton) {
        view.endEditing(true) // Oculta el teclado
        
        //'text' es String? (Optional), guard let lo desenvuelve o sale.
        guard let email = emailTextField.text, let password = passwordTextField.text else { return }
        
        switch emailValidator.validate(email) {
        case .failure(let error):
            showError(error.message)
            
        case .success(let validEmail):
            guard !password.isEmpty else {
                showError("La contraseña es obligatoria")
                return
            }
            hideError()
            print("✅ Login valido con \(validEmail)")
            showFeed()
        }
        
        
        
        
    }
    
    
    // MARK: - Navegación (🟤 Segues)
    // Los identificadores en un solo lugar: un typo en un String no lo detecta el compilador
    private enum SegueID {
        static let showRegister = "showRegister"
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        guard segue.identifier == SegueID.showRegister, let register = segue.destination as? RegisterViewController else { return }
        register.prefilledEmail = emailTextField.text
        register.delegate = self // avisame a MI cuando se cree la cuenta
    }
    
    private func showFeed() {
        let storyboard = UIStoryboard(name: "Feed", bundle: nil)
        guard let feed = storyboard.instantiateInitialViewController(creator: { coder in
            FeedViewController(coder: coder, loader: MockFeedLoader())
        }) else {
            // Solo truena en Debug: te avisa que olvidaste "Is Initiañ ViewContoller"
            assertionFailure("Feed.storyboard no tiene Initial View Controller")
            return
        }
        navigationController?.pushViewController(feed, animated: true)
        
    }
 
    
    // MARK: - Helpers
    private func showError(_ message: String){
        errorLabel.text = message
        errorLabel.textColor = .systemRed
        errorLabel.isHidden = false
    }
    
    private func hideError(){
        errorLabel.text = nil
        errorLabel.isHidden = true
    }

    
    private func showSuccess(_ message: String){
        errorLabel.text = message
        errorLabel.textColor = .systemGreen
        errorLabel.isHidden =  false
    }

}

// MARK: - UITextFieldDelegate
// Separar cada conformnace en su propia extension es una convencion muy usada
extension LoginViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField === emailTextField {
            passwordTextField.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
            loginButtonTapped(loginButton)
        }
        return true
    }
}


// MARK: - RegisterViewControllerDelegate
extension LoginViewController: RegisterViewControllerDelegate {
    func registerViewController(_ controller: RegisterViewController, didRegister account: NewAccount) {
        emailTextField.text = account.email
        passwordTextField.text = nil
        showSuccess("¡Cuenta creada, \(account.displayName)! Ahora inicia sesión")
        // Quien abre la pantalla es quien la cierra
        navigationController?.popViewController(animated: true)
    }
}
