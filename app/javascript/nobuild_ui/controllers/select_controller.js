import { Controller } from "@hotwired/stimulus"

// The choosing half of a select menu (ui_select_menu): an option clicked (or chosen with
// Enter) goes into the hidden input, which fires change, and its text into the trigger. The
// ui--popover controller beside it opens, places and closes the listbox; this makes it at
// least as wide as the trigger and puts focus on the chosen option when it opens.
//
//   <div class="ui-select-menu" data-controller="ui--popover ui--select">
//     <input type="hidden" name="fruit" data-ui--select-target="input">
//     <button class="ui-select__trigger" popovertarget="fruits">
//       <span class="ui-select__value" data-ui--select-target="value">Pick a fruit</span>…
//     </button>
//     <div id="fruits" popover role="listbox" class="ui-menu ui-select__content"
//          data-ui--popover-target="popover" data-ui--select-target="listbox">
//       <button type="button" role="option" class="ui-menu__item ui-select__item" data-value="apple">Apple</button>
//     </div>
//   </div>
export default class extends Controller {
  static targets = [ "input", "value", "listbox" ]

  listboxTargetConnected(listbox) {
    listbox.addEventListener("beforetoggle", this.#beforeToggle)
    listbox.addEventListener("toggle", this.#toggled)
    listbox.addEventListener("click", this.#clicked)
  }

  listboxTargetDisconnected(listbox) {
    listbox.removeEventListener("beforetoggle", this.#beforeToggle)
    listbox.removeEventListener("toggle", this.#toggled)
    listbox.removeEventListener("click", this.#clicked)
  }

  get #trigger() {
    return this.element.querySelector(`[popovertarget="${this.listboxTarget.id}"]`)
  }

  get #options() {
    return [ ...this.listboxTarget.querySelectorAll("[role=option]") ]
  }

  #beforeToggle = (event) => {
    if (event.newState === "open" && this.#trigger) {
      this.listboxTarget.style.minWidth = `${this.#trigger.getBoundingClientRect().width}px`
    }
  }

  #toggled = (event) => {
    if (event.newState !== "open") return

    const chosen = this.#options.find(option => option.getAttribute("aria-selected") === "true")
    if (chosen) requestAnimationFrame(() => chosen.focus({ preventScroll: false }))
  }

  #clicked = (event) => {
    const option = event.target.closest("[role=option]")
    if (!option || option.disabled || option.getAttribute("aria-disabled") === "true") return

    this.#options.forEach(each => each.setAttribute("aria-selected", each === option))
    this.#trigger?.removeAttribute("data-placeholder")
    if (this.hasValueTarget) this.valueTarget.textContent = option.dataset.label ?? option.textContent.trim()

    if (this.hasInputTarget && this.inputTarget.value !== option.dataset.value) {
      this.inputTarget.value = option.dataset.value ?? ""
      this.inputTarget.dispatchEvent(new Event("input", { bubbles: true }))
      this.inputTarget.dispatchEvent(new Event("change", { bubbles: true }))
    }

    requestAnimationFrame(() => this.#trigger?.focus())
  }
}
