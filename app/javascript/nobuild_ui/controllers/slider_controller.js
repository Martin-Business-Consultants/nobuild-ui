import { Controller } from "@hotwired/stimulus"

// Fills a ui-slider's track up to its thumb: keeps --ui-slider-value (0 to 1) in step with
// the range input's value. Firefox fills the track on its own; Chrome and Safari need this.
//
//   <input type="range" class="ui-slider" data-controller="ui--slider" min="0" max="100" value="50">
export default class extends Controller {
  connect() {
    this.element.addEventListener("input", this.update)
    this.update()
  }

  disconnect() {
    this.element.removeEventListener("input", this.update)
  }

  update = () => {
    const input = this.element
    const min = input.min === "" ? 0 : Number(input.min)
    const max = input.max === "" ? 100 : Number(input.max)
    const value = max > min ? (Number(input.value) - min) / (max - min) : 0
    input.style.setProperty("--ui-slider-value", Math.min(1, Math.max(0, value)))
  }
}
