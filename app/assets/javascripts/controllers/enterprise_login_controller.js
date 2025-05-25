import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "emailInput", "submitButton", "errorMessage", "ssoNotice", "passwordSection", "ssoButton" ]

  connect() {
    if (this.hasSubmitButtonTarget) {
      this.originalButtonText = this.submitButtonTarget.value
    }
  }

  checkDomain() {
    const email = this.emailInputTarget.value
    const domain = this.extractDomain(email)

    if (domain) {
      fetch(`/enterprise_configurations/check_domain?email=${encodeURIComponent(email)}`)
        .then(response => response.json())
        .then(data => {
          if (data.configured) {
            this.showSSOOption(data.idp_name, email)
            this.clearError()
          } else {
            this.showPasswordOption()
            this.clearError()
          }
        })
        .catch(error => {
          console.error("Error checking domain:", error)
          this.showPasswordOption()
          this.clearError()
        })
    } else {
      this.showPasswordOption()
      // If email is not empty and contains "@" but domain is still invalid, show format error
      if (email.trim() !== "" && email.includes("@")) {
        this.showError("Invalid email format. Please enter a valid email.")
      } else if (email.trim() === "") {
        // If email input is completely empty, clear any errors
        this.clearError()
      }
    }
  }

  showSSOOption(idpName, email) {
    // Hide password section and show SSO notice
    if (this.hasPasswordSectionTarget) {
      this.passwordSectionTarget.classList.add("hidden")
    }
    if (this.hasSsoNoticeTarget) {
      this.ssoNoticeTarget.classList.remove("hidden")
    }
    
    // Update SSO button to include email parameter
    if (this.hasSsoButtonTarget) {
      const baseUrl = this.ssoButtonTarget.getAttribute("href").split("?")[0]
      this.ssoButtonTarget.setAttribute("href", `${baseUrl}?email=${encodeURIComponent(email)}`)
    }
    
    // Update submit button text if it exists
    if (this.hasSubmitButtonTarget) {
      this.submitButtonTarget.value = `Login with ${idpName}`
      this.submitButtonTarget.classList.add("hidden")
    }
  }

  showPasswordOption() {
    // Show password section and hide SSO notice
    if (this.hasPasswordSectionTarget) {
      this.passwordSectionTarget.classList.remove("hidden")
    }
    if (this.hasSsoNoticeTarget) {
      this.ssoNoticeTarget.classList.add("hidden")
    }
    
    // Reset submit button
    if (this.hasSubmitButtonTarget) {
      this.submitButtonTarget.value = this.originalButtonText
      this.submitButtonTarget.classList.remove("hidden")
    }
  }

  extractDomain(email) {
    if (email && email.includes("@")) {
      const parts = email.split("@")
      if (parts.length === 2 && parts[1].includes(".")) {
        return parts[1]
      }
    }
    return null
  }

  showError(message) {
    if (this.hasErrorMessageTarget) {
      this.errorMessageTarget.textContent = message
      this.errorMessageTarget.classList.remove("hidden")
    }
    this.emailInputTarget.classList.add("input-error") // DaisyUI error class
  }

  clearError() {
    if (this.hasErrorMessageTarget) {
      this.errorMessageTarget.textContent = ""
      this.errorMessageTarget.classList.add("hidden")
    }
    this.emailInputTarget.classList.remove("input-error")
  }

  resetButton() {
    if (this.hasSubmitButtonTarget) {
      this.submitButtonTarget.value = this.originalButtonText
    }
  }
}