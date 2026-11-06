import { Controller } from "@hotwired/stimulus"

// A combobox (ui_combobox): typing in the input opens the list under it and filters it;
// the arrow keys move the highlight, Enter or a click chooses, Escape or a click elsewhere
// closes. The chosen option's text goes into the input and its data-value into the hidden
// input, which fires change. Focus stays in the input throughout (aria-activedescendant).
//
//   <div class="ui-combobox" data-controller="ui--combobox">
//     <input type="hidden" name="framework" data-ui--combobox-target="hidden">
//     <div class="ui-input-group">
//       <input class="ui-input" role="combobox" data-ui--combobox-target="input">…
//     </div>
//     <div popover="manual" class="ui-combobox__content" data-ui--combobox-target="content">
//       <div class="ui-combobox__empty">No items found.</div>
//       <div class="ui-combobox__list" role="listbox">
//         <div class="ui-combobox__item" role="option" id="fw-next" data-value="next">Next.js</div>
//       </div>
//     </div>
//   </div>
export default class extends Controller {
  static targets = [ "input", "hidden", "content" ]
  static values = { offset: { type: Number, default: 6 } }

  connect() {
    this.inputTarget.addEventListener("input", this.#typed)
    this.inputTarget.addEventListener("keydown", this.#keydown)
    this.inputTarget.addEventListener("click", this.open)
    this.contentTarget.addEventListener("mousedown", this.#keepFocus)
    this.contentTarget.addEventListener("click", this.#clicked)
    this.contentTarget.addEventListener("mousemove", this.#hovered)
    this.contentTarget.addEventListener("toggle", this.#toggled)
    document.addEventListener("pointerdown", this.#pointerdown, true)
  }

  disconnect() {
    this.inputTarget.removeEventListener("input", this.#typed)
    this.inputTarget.removeEventListener("keydown", this.#keydown)
    this.inputTarget.removeEventListener("click", this.open)
    this.contentTarget.removeEventListener("mousedown", this.#keepFocus)
    this.contentTarget.removeEventListener("click", this.#clicked)
    this.contentTarget.removeEventListener("mousemove", this.#hovered)
    this.contentTarget.removeEventListener("toggle", this.#toggled)
    document.removeEventListener("pointerdown", this.#pointerdown, true)
    this.#unwatch()
  }

  open = () => {
    if (this.#isOpen || this.inputTarget.disabled) return
    this.contentTarget.showPopover()
    this.#place()
  }

  close() {
    if (this.#isOpen) this.contentTarget.hidePopover()
  }

  toggle() {
    if (this.#isOpen) {
      this.close()
    } else {
      this.#filter("")
      this.open()
    }
    this.inputTarget.focus()
  }

  get #isOpen() {
    return this.contentTarget.matches(":popover-open")
  }

  get #options() {
    return [ ...this.contentTarget.querySelectorAll("[role=option]") ]
  }

  get #visible() {
    return this.#options.filter(option => !option.hidden && option.getAttribute("aria-disabled") !== "true")
  }

  get #highlighted() {
    return this.contentTarget.querySelector("[role=option][data-highlighted]")
  }

  #typed = () => {
    this.#filter(this.inputTarget.value)
    this.open()
    this.#highlight(this.#visible[0])
  }

  #filter(text) {
    const query = text.trim().toLowerCase()
    this.#options.forEach(option => {
      const label = (option.dataset.label ?? option.textContent).trim().toLowerCase()
      option.hidden = query !== "" && !label.includes(query)
    })
    this.contentTarget.querySelectorAll(".ui-combobox__group").forEach(group => {
      group.hidden = !group.querySelector("[role=option]:not([hidden])")
    })
    this.contentTarget.toggleAttribute("data-empty", this.#visible.length === 0)
  }

  #highlight(option) {
    this.#highlighted?.removeAttribute("data-highlighted")
    if (option) {
      option.setAttribute("data-highlighted", "")
      option.scrollIntoView({ block: "nearest" })
      if (option.id) this.inputTarget.setAttribute("aria-activedescendant", option.id)
    } else {
      this.inputTarget.removeAttribute("aria-activedescendant")
    }
  }

  #choose(option) {
    this.#options.forEach(each => each.setAttribute("aria-selected", each === option))
    this.inputTarget.value = option.dataset.label ?? option.textContent.trim()

    if (this.hasHiddenTarget && this.hiddenTarget.value !== option.dataset.value) {
      this.hiddenTarget.value = option.dataset.value ?? ""
      this.hiddenTarget.dispatchEvent(new Event("input", { bubbles: true }))
      this.hiddenTarget.dispatchEvent(new Event("change", { bubbles: true }))
    }
    this.close()
  }

  #keydown = (event) => {
    const options = this.#visible
    const index = options.indexOf(this.#highlighted)

    switch (event.key) {
      case "ArrowDown":
      case "ArrowUp":
        event.preventDefault()
        if (!this.#isOpen) { this.#filter(""); this.open() }
        this.#highlight(event.key === "ArrowDown" ? options[(index + 1) % options.length] : options.at(index <= 0 ? -1 : index - 1))
        break
      case "Enter":
        if (this.#isOpen && this.#highlighted) {
          event.preventDefault()
          this.#choose(this.#highlighted)
        }
        break
      case "Escape":
        if (this.#isOpen) {
          event.preventDefault()
          event.stopPropagation()
          this.close()
        }
        break
      case "Tab":
        this.close()
    }
  }

  #keepFocus = (event) => event.preventDefault()

  #clicked = (event) => {
    const option = event.target.closest("[role=option]")
    if (option && option.getAttribute("aria-disabled") !== "true") this.#choose(option)
  }

  #hovered = (event) => {
    const option = event.target.closest("[role=option]")
    if (option && option !== this.#highlighted && option.getAttribute("aria-disabled") !== "true") this.#highlight(option)
  }

  #pointerdown = (event) => {
    if (this.#isOpen && !this.element.contains(event.target) && !this.contentTarget.contains(event.target)) this.close()
  }

  #toggled = (event) => {
    const open = event.newState === "open"
    this.inputTarget.setAttribute("aria-expanded", open)

    if (open) {
      this.#place()
      this.#highlight(this.#highlighted ?? this.#options.find(option => option.getAttribute("aria-selected") === "true" && !option.hidden) ?? this.#visible[0])
      window.addEventListener("resize", this.#place)
      window.addEventListener("scroll", this.#place, true)
    } else {
      this.#highlight(null)
      this.#unwatch()
    }
  }

  #unwatch() {
    window.removeEventListener("resize", this.#place)
    window.removeEventListener("scroll", this.#place, true)
  }

  // Under the input group, start-aligned, at least its width plus 1.75rem; above it when
  // there's no room below.
  #place = () => {
    const anchor = (this.inputTarget.closest(".ui-input-group") ?? this.inputTarget).getBoundingClientRect()
    const content = this.contentTarget
    const rem = parseFloat(getComputedStyle(document.documentElement).fontSize)
    content.style.minWidth = `${anchor.width + 1.75 * rem}px`

    const box = content.getBoundingClientRect()
    const margin = 8
    let top = anchor.bottom + this.offsetValue
    if (top + box.height > window.innerHeight - margin && anchor.top - box.height - this.offsetValue > margin) {
      top = anchor.top - box.height - this.offsetValue
    }
    const left = Math.max(margin, Math.min(anchor.left, window.innerWidth - box.width - margin))

    content.style.top = `${Math.max(margin, top)}px`
    content.style.left = `${left}px`
  }
}
