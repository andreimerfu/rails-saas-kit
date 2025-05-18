import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="dismissable"
export default class extends Controller {
  static targets = ["elementToDismiss"] // Optional target

  connect() {
    // console.log("Dismissable controller connected", this.element);
  }

  dismiss(event) {
    event.preventDefault()

    let targetElement = this.element // By default, dismiss the controller's element itself

    // If an "elementToDismiss" target is specified, dismiss that instead.
    // This allows the button to be outside the element it dismisses.
    if (this.hasElementToDismissTarget) {
      targetElement = this.elementToDismissTarget
    } else {
      // If no specific target, try to find the closest common DaisyUI alert or modal parent
      const alertParent = this.element.closest('.alert')
      const modalParent = this.element.closest('.modal') // Or data-modal-id or similar
      // You might need more specific selectors if your structure is complex

      if (alertParent) {
        targetElement = alertParent
      } else if (modalParent) {
        // For modals, you might want to close it via its specific mechanism
        // e.g., if it's a <dialog>, targetElement.close()
        // For DaisyUI modals often controlled by a checkbox:
        const modalCheckboxId = modalParent.dataset.modalCheckboxId; // Assuming you add data-modal-checkbox-id to your modal trigger
        if (modalCheckboxId) {
          const modalCheckbox = document.getElementById(modalCheckboxId);
          if (modalCheckbox) {
            modalCheckbox.checked = false;
            return; // Exit after handling modal
          }
        }
        targetElement = modalParent;
      }
      // If still no specific target, it defaults to this.element (the button itself, which is not usually what you want)
      // So, it's better to ensure the button is inside the alert or provide a target.
      // For the current alert, it will find the parent .alert
    }


    if (targetElement) {
      // You can add a transition effect here if you like
      // For example, add a class that fades it out
      targetElement.classList.add("hidden") // Simple hide, or use a transition class
      // Or targetElement.remove() to remove from DOM entirely
    }
  }
}