import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="dismissable"
export default class extends Controller {
  static targets = ["elementToDismiss", "progressBar", "progressBarContainer"]
  static values = {
    autoDismiss: Boolean,
    delay: { type: Number, default: 10000 } // Default delay 10 seconds
  }

  connect() {
    // Open animation
    // Ensure initial state is rendered, then trigger animation
    requestAnimationFrame(() => {
      this.element.classList.remove("opacity-0", "translate-x-full");
      this.element.classList.add("opacity-100", "translate-x-0");
    });

    if (this.autoDismissValue) {
      this.totalDuration = this.delayValue;
      this.remainingTime = this.totalDuration;
      this.animationStartTime = Date.now();

      if (this.hasProgressBarTarget && this.totalDuration > 0) {
        this.progressBarTarget.style.width = "100%";
        this.progressBarTarget.classList.add("bg-primary"); // Temporary: Force a visible color
        // console.log("Progress bar initialized to 100% in connect, forced bg-primary");
      }

      this.startDismissTimer();
      this.startProgressBar(); // This will then adjust width if resuming or immediately animate
    }
    if (!this.hasProgressBarTarget || !this.hasProgressBarContainerTarget) {
      // console.warn("Dismissable controller is missing progressBar or progressBarContainer target for visual feedback.");
    }
  }

  disconnect() {
    this.clearTimersAndAnimation();
  }

  dismiss(event) {
    if (event) {
      event.preventDefault();
    }
    this.clearTimersAndAnimation();

    let targetElement = this.element;
    // In this component, the controller's element IS the alert.
    // So, no need to search for parent or use elementToDismissTarget unless that specific flexibility is required later.

    // Apply close animation classes
    targetElement.classList.remove("opacity-100", "translate-x-0");
    targetElement.classList.add("opacity-0", "translate-x-full"); // Animate out to the right

    // Wait for animation to complete before hiding/removing
    const animationDuration = 300; // Must match Tailwind's duration-300
    setTimeout(() => {
      if (targetElement) { // Check if still exists
        targetElement.classList.add("hidden");
        // Or targetElement.remove(); if you want to remove it from DOM entirely
        // If removing, ensure no other logic tries to access it.
      }
    }, animationDuration);
  }

  pause() {
    if (!this.autoDismissValue || !this.timeout) return;

    clearTimeout(this.timeout);
    this.timeout = null; // Explicitly nullify
    if (this.animationFrameId) {
      cancelAnimationFrame(this.animationFrameId);
      this.animationFrameId = null; // Explicitly nullify
    }
    // Calculate time elapsed during the current segment before pause
    const elapsedTimeThisSegment = Date.now() - this.animationStartTime;
    this.remainingTime -= elapsedTimeThisSegment;
    this.remainingTime = Math.max(0, this.remainingTime); // Ensure it doesn't go negative
  }

  resume() {
    if (!this.autoDismissValue || this.timeout || this.remainingTime <= 0) return; // Don't resume if already running or no time left

    this.animationStartTime = Date.now(); // Reset start time for the new animation/timeout segment
    this.startDismissTimer();
    this.startProgressBar();
  }

  startDismissTimer() {
    if (this.timeout) clearTimeout(this.timeout);
    this.timeout = setTimeout(() => {
      this.dismiss();
    }, this.remainingTime);
  }

  startProgressBar() {
    if (!this.hasProgressBarTarget) {
      // console.log("No progress bar target found");
      return;
    }

    // Ensure totalDuration is positive; otherwise, percentage calculation is problematic.
    if (this.totalDuration <= 0) {
      // console.log("Total duration is not positive, cannot animate progress bar.");
      this.progressBarTarget.style.width = "0%"; // Or 100% if remainingTime > 0, but 0% is safer.
      return;
    }
    
    // If remaining time is zero or less, set bar to 0% and don't animate.
    if (this.remainingTime <= 0) {
      this.progressBarTarget.style.width = "0%";
      // console.log("Remaining time is zero or less, setting bar to 0%.");
      return;
    }

    // Set initial width based on current remaining time before starting animation loop
    // This ensures the bar reflects the correct state if resuming.
    const initialWidthPercentage = Math.max(0, (this.remainingTime / this.totalDuration) * 100);
    this.progressBarTarget.style.width = `${initialWidthPercentage}%`;
    // console.log(`ProgressBar: Initial width set to ${initialWidthPercentage}%. Remaining: ${this.remainingTime}, Total: ${this.totalDuration}.`);


    if (this.animationFrameId) cancelAnimationFrame(this.animationFrameId);

    // this.animationStartTime is set in connect() or resume()
    const segmentDuration = this.remainingTime; // Duration for this current animation segment

    const animate = () => {
      const timeElapsedInContinuousPeriod = Date.now() - this.animationStartTime;
      
      // actualTotalTimeLeft is how much time is left from the original totalDuration
      const actualTotalTimeLeft = segmentDuration - timeElapsedInContinuousPeriod;
      const widthPercentage = Math.max(0, (actualTotalTimeLeft / this.totalDuration) * 100);
      
      this.progressBarTarget.style.width = `${widthPercentage}%`;
      // console.log(`Animating: Elapsed ${timeElapsedInContinuousPeriod}, SegmentDur ${segmentDuration}, ActualLeft ${actualTotalTimeLeft}, Width% ${widthPercentage}`);

      // Continue animation if there's time left in the current segment AND overall
      if (timeElapsedInContinuousPeriod < segmentDuration && actualTotalTimeLeft > 0) {
        this.animationFrameId = requestAnimationFrame(animate);
      } else {
        this.progressBarTarget.style.width = "0%"; // Ensure it ends at 0
        // console.log("Animation ended or actualTotalTimeLeft <= 0.");
      }
    };
    this.animationFrameId = requestAnimationFrame(animate);
  }

  clearTimersAndAnimation() {
    if (this.timeout) {
      clearTimeout(this.timeout);
      this.timeout = null;
    }
    if (this.animationFrameId) {
      cancelAnimationFrame(this.animationFrameId);
      this.animationFrameId = null;
    }
  }
}