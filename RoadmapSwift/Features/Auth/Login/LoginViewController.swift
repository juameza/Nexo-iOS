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
        print("🟢 viewDidLoad")
        configureUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("🔵 viewWillAppear")
    }
    
    override func viewIsAppearing(_ animated: Bool) {
        super.viewIsAppearing(animated)
        print("🟡 viewIsAppearing")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("🟣 viewDidAppear")
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
            // Dia 5: navegar al Feed
        }
        
        
    }
    
    @IBAction private func createAccountTapped(_ sender: UIButton){
        // ⚠️ TEMPORAL (Día 2): solo para ver el feed en consola. Lo quitamos en el Día 3.
        do {
            let posts = try MockFeedLoader().load()
            for post in posts {
                // 🟢 Swift 5.9+: switch como expresión, asignado directo a una constante
                let summary: String = switch post.content {
                case .text(let text): "📝 \(text)"
                case .image(_, let caption): "🖼️ \(caption ?? "(sin descripción)")"
                case .video(_, let duration): "🎬 video de \(Int(duration))"
                case .unsupported(let type): " ? tipo no soportado: \(type)"
                }
                let verified = post.author.isVerified ? "✅" : "🚫"
                print("\(post.author.handle)\(verified) - \(post.relativeCreatedAt) - ♥️ \(post.likeCount)\n \(summary)")
            }
        } catch {
            print("❌ \(error)")
        }
    }
    
    // MARK: - Helpers
    private func showError(_ message: String){
        errorLabel.text = message
        errorLabel.isHidden = false
    }
    
    private func hideError(){
        errorLabel.text = nil
        errorLabel.isHidden = true
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
