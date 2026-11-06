import { Controller } from "@hotwired/stimulus"

// A menubar (ui-menubar): each menu is a ui--popover of its own; this moves between them as
// shadcn's does. While one is open, hovering another trigger opens that one; ArrowLeft and
// ArrowRight in an open menu (outside a sub-menu) move to the menu beside it, and on a trigger
// to the trigger beside it.
//
//   <div class="ui-menubar" role="menubar" data-controller="ui--menubar">
//     <div data-controller="ui--popover" …>…trigger and menu…</div>
//     …
//   </div>
export default class extends Controller {
  connect() {
    this.element.addEventListener("pointerover", this.#pointerOver)
    this.element.addEventListener("keydown", this.#keydown)
  }

  disconnect() {
    this.element.removeEventListener("pointerover", this.#pointerOver)
    this.element.removeEventListener("keydown", this.#keydown)
  }

  get #triggers() {
    return [ ...this.element.querySelectorAll(".ui-menubar__trigger") ]
  }

  get #openTrigger() {
    return this.#triggers.find(trigger => this.#menuOf(trigger)?.matches(":popover-open"))
  }

  #menuOf(trigger) {
    return document.getElementById(trigger.getAttribute("popovertarget"))
  }

  #pointerOver = (event) => {
    const trigger = event.target.closest(".ui-menubar__trigger")
    const open = this.#openTrigger
    if (trigger && open && trigger !== open) this.#menuOf(trigger).showPopover()
  }

  #keydown = (event) => {
    if (event.key !== "ArrowLeft" && event.key !== "ArrowRight") return

    const triggers = this.#triggers
    const inMenu = event.target.closest(".ui-menu")
    const from = inMenu ? this.#openTrigger : event.target.closest(".ui-menubar__trigger")
    if (!from) return

    const step = event.key === "ArrowRight" ? 1 : -1
    const next = triggers[(triggers.indexOf(from) + step + triggers.length) % triggers.length]
    event.preventDefault()

    if (inMenu) {
      this.#menuOf(next).showPopover()
    } else {
      next.focus()
    }
  }
}
