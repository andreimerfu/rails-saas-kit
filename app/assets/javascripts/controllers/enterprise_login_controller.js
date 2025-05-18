import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "emailInput", "submitButton", "errorMessage" ]

  connect() {
    this.originalButtonText = this.submitButtonTarget.value
  }

  checkDomain() {
    const email = this.emailInputTarget.value
    const domain = this.extractDomain(email)

    if (domain) {
      fetch(`/enterprise_configurations/check_domain?email=${encodeURIComponent(email)}`)
        .then(response => response.json())
        .then(data => {
          if (data.configured) {
            this.submitButtonTarget.value = `Login with ${data.idp_name}`
            this.clearError()
          } else {
            this.resetButton()
            this.showError("Enterprise connection isn't configured for this email address.")
          }
        })
        .catch(error => {
          console.error("Error checking domain:", error)
          this.resetButton()
          this.showError("Could not verify email address. Please try again.")
        })
    } else {
      this.resetButton()
      // If email is not empty and contains "@" but domain is still invalid, show format error
      if (email.trim() !== "" && email.includes("@")) {
        this.showError("Invalid email format. Please enter a valid corporate email.")
      } else if (email.trim() === "") {
        // If email input is completely empty, clear any errors
        this.clearError()
      }
      // If user is typing before the "@" or the field is empty, errors are cleared or not shown.
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
    this.errorMessageTarget.textContent = message
    this.errorMessageTarget.classList.remove("hidden")
    this.emailInputTarget.classList.add("input-error") // DaisyUI error class
  }

  clearError() {
    this.errorMessageTarget.textContent = ""
    this.errorMessageTarget.classList.add("hidden")
    this.emailInputTarget.classList.remove("input-error")
  }

  resetButton() {
    this.submitButtonTarget.value = this.originalButtonText
  }
}