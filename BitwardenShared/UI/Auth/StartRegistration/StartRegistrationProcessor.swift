import AuthenticationServices
import BitwardenSdk
import Combine
import Foundation
import OSLog

// MARK: - StartRegistrationError

/// A delegate of `StartRegistrationProcessor` that is notified when the user changes region.
///
protocol StartRegistrationDelegate: AnyObject {
    /// Called when the user changes regions.
    ///
    func didChangeRegion() async
}

// MARK: - StartRegistrationError

/// Enumeration of errors that may occur when creating an account.
///
enum StartRegistrationError: Error {
    /// The terms of service and privacy policy have not been acknowledged.
    case acceptPoliciesError

    /// The email field is empty.
    case emailEmpty

    /// The email is invalid.
    case invalidEmail

    /// The name field is empty.
    case nameEmpty
}

// MARK: - StartRegistrationProcessor

/// The processor used to manage state and handle actions for the create account screen.
///
class StartRegistrationProcessor: StateProcessor<
    StartRegistrationState,
    StartRegistrationAction,
    StartRegistrationEffect
> {
    // MARK: Types

    typealias Services = HasAccountAPIService
        & HasAuthRepository
        & HasCaptchaService
        & HasClientService
        & HasEnvironmentService
        & HasErrorReporter
        & HasStateService

    // MARK: Private Properties

    /// The coordinator that handles navigation.
    private let coordinator: AnyCoordinator<AuthRoute, AuthEvent>

    /// The services used by the processor.
    private let services: Services

    /// The delegate for the processor that is notified when the user closes the registration view.
    private weak var delegate: StartRegistrationDelegate?

    // MARK: Initialization

    /// Creates a new `StartRegistrationProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The coordinator that handles navigation.
    ///   - services: The services used by the processor.
    ///   - state: The initial state of the processor.
    ///
    init(
        coordinator: AnyCoordinator<AuthRoute, AuthEvent>,
        delegate: StartRegistrationDelegate?,
        services: Services,
        state: StartRegistrationState
    ) {
        self.coordinator = coordinator
        self.delegate = delegate
        self.services = services
        super.init(state: state)
    }

    // MARK: Methods

    override func perform(_ effect: StartRegistrationEffect) async {
        switch effect {
        case .appeared:
            await loadRegion()
        case .startRegistration:
            await startRegistration()
        }
    }

    override func receive(_ action: StartRegistrationAction) {
        switch action {
        case let .emailTextChanged(text):
            state.emailText = text
        case .dismiss:
            coordinator.navigate(to: .dismiss)
        case let .nameTextChanged(text):
            state.nameText = text
        case let .toggleTermsAndPrivacy(newValue):
            state.isTermsAndPrivacyToggleOn = newValue
        case .regionTapped:
            presentRegionSelectionAlert()
        case let .toastShown(toast):
            state.toast = toast
        }
    }

    // MARK: Private methods

    /// Creates the user's account with their provided credentials.
    ///
    /// - Parameter captchaToken: The token returned when the captcha flow has completed.
    ///
    private func startRegistration(captchaToken: String? = nil) async {
        // Hide the loading overlay when exiting this method, in case it hasn't been hidden yet.
        defer { coordinator.hideLoadingOverlay() }

        do {
            let email = state.emailText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            let name = state.nameText.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !email.isEmpty else {
                throw StartRegistrationError.emailEmpty
            }

            guard !name.isEmpty else {
                throw StartRegistrationError.nameEmpty
            }

            guard email.isValidEmail else {
                throw StartRegistrationError.invalidEmail
            }

            guard state.isTermsAndPrivacyToggleOn else {
                throw StartRegistrationError.acceptPoliciesError
            }

            coordinator.showLoadingOverlay(title: Localizations.creatingAccount)

            let result = try await services.accountAPIService.startRegistration(
                requestModel: StartRegistrationRequestModel(
                    captchaResponse: captchaToken,
                    email: email,
                    name: name
                )
            )

            if let token = result.emailVerificationToken {
                coordinator.navigate(to: .completeRegistration(
                    emailVerificationToken: token,
                    userEmail: state.emailText
                ))
            } else {
                coordinator.navigate(to: .checkEmail(email: state.emailText))
            }
        } catch let StartRegistrationRequestError.captchaRequired(hCaptchaSiteCode: siteCode) {
            launchCaptchaFlow(with: siteCode)
        } catch let error as StartRegistrationError {
            showStartRegistrationErrorAlert(error)
        } catch {
            coordinator.showAlert(.networkResponseError(error) {
                await self.startRegistration(captchaToken: captchaToken)
            })
        }
    }

    /// Generates the items needed and authenticates with the captcha flow.
    ///
    /// - Parameter siteKey: The site key that was returned with a captcha error. The token used to authenticate
    ///   with hCaptcha.
    ///
    private func launchCaptchaFlow(with siteKey: String) {
        do {
            let callbackUrlScheme = services.captchaService.callbackUrlScheme
            let url = try services.captchaService.generateCaptchaUrl(with: siteKey)
            coordinator.navigate(
                to: .captcha(
                    url: url,
                    callbackUrlScheme: callbackUrlScheme
                ),
                context: self
            )
        } catch {
            coordinator.showAlert(.networkResponseError(error))
            services.errorReporter.log(error: error)
        }
    }

    /// Sets the region to the last used region.
    ///
    private func loadRegion() async {
        guard let urls = await services.stateService.getPreAuthEnvironmentUrls() else {
            await setRegion(.unitedStates, urls: .defaultUS)
            return
        }

        if urls.base == EnvironmentUrlData.defaultUS.base {
            await setRegion(.unitedStates, urls: urls)
        } else if urls.base == EnvironmentUrlData.defaultEU.base {
            await setRegion(.europe, urls: urls)
        } else {
            await setRegion(.selfHosted, urls: urls)
        }
    }

    /// Builds an alert for region selection and navigates to the alert.
    ///
    private func presentRegionSelectionAlert() {
        let actions = RegionType.allCases.map { region in
            AlertAction(title: region.baseUrlDescription, style: .default) { [weak self] _ in
                if let urls = region.defaultURLs {
                    await self?.setRegion(region, urls: urls)
                } else {
                    self?.coordinator.navigate(
                        to: .selfHosted(currentRegion: self?.state.region ?? .unitedStates),
                        context: self
                    )
                }
            }
        }
        let cancelAction = AlertAction(title: Localizations.cancel, style: .cancel)
        let alert = Alert(
            title: Localizations.loggingInOn,
            message: nil,
            preferredStyle: .actionSheet,
            alertActions: actions + [cancelAction]
        )
        coordinator.showAlert(alert)
    }

    /// Shows a `StartRegistrationError` alert.
    ///
    /// - Parameter error: The error that occurred.
    ///
    private func showStartRegistrationErrorAlert(_ error: StartRegistrationError) {
        switch error {
        case .acceptPoliciesError:
            coordinator.showAlert(.acceptPoliciesAlert())
        case .emailEmpty:
            coordinator.showAlert(.validationFieldRequired(fieldName: Localizations.email))
        case .nameEmpty:
            coordinator.showAlert(.validationFieldRequired(fieldName: Localizations.name))
        case .invalidEmail:
            coordinator.showAlert(.invalidEmail)
        }
    }

    /// Sets the region and the URLs to use.
    ///
    /// - Parameters:
    ///   - region: The region to use.
    ///   - urls: The URLs that the app should use for the region.
    ///
    private func setRegion(_ region: RegionType, urls: EnvironmentUrlData) async {
        guard !urls.isEmpty else { return }
        await services.environmentService.setPreAuthURLs(urls: urls)
        state.region = region
        await delegate?.didChangeRegion()
    }
}

// MARK: - CaptchaFlowDelegate

extension StartRegistrationProcessor: CaptchaFlowDelegate {
    func captchaCompleted(token: String) {
        Task {
            await startRegistration(captchaToken: token)
        }
    }

    func captchaErrored(error: Error) {
        guard (error as NSError).code != ASWebAuthenticationSessionError.canceledLogin.rawValue else { return }

        services.errorReporter.log(error: error)

        // Show the alert after a delay to ensure it doesn't try to display over the
        // closing captcha view.
        DispatchQueue.main.asyncAfter(deadline: UI.after(0.6)) {
            self.coordinator.showAlert(.networkResponseError(error))
        }
    }
}

// MARK: - SelfHostedProcessorDelegate

extension StartRegistrationProcessor: SelfHostedProcessorDelegate {
    func didSaveEnvironment(urls: EnvironmentUrlData) async {
        await setRegion(.selfHosted, urls: urls)
        state.toast = Toast(text: Localizations.environmentSaved)
    }
}