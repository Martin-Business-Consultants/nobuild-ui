import { Controller } from "@hotwired/stimulus"

// Places a native popover (ui-menu, ui-popover, ui-hover-card, a navigation menu's content)
// beside what opens it, and gives a menu shadcn's keyboard: arrows and Home/End move between
// items, a letter jumps to the next item starting with it, ArrowRight / ArrowLeft open and
// close a sub-menu, choosing an item closes the menu. The popover attribute does the rest
// (opening, light dismiss, Escape, the top layer).
//
//   <div data-controller="ui--popover" data-ui--popover-align-value="end">
//     <button popovertarget="menu-1" class="ui-button ui-button--outline">Open</button>
//     <div id="menu-1" popover class="ui-menu" data-ui--popover-target="popover">…</div>
//   </div>
//
// side: bottom (default), top, right or left; align: start (default), center or end;
// offset: the gap to the trigger (4px); align-offset: a shift along it.
//
// Sub-menus need nothing more: a .ui-menu__sub-trigger with popovertarget naming a
// .ui-menu--sub popover inside the menu opens on hover, click or ArrowRight, to the right.
//
// hover: true opens on hover and focus (a hover card, a navigation menu) after open-delay
// (600ms) and closes after close-delay (300ms); the trigger is the popovertarget button or
// any element marked data-ui--popover-target="trigger".
//
// A context menu opens at the pointer: data-action="contextmenu->ui--popover#openAt" on the
// area (ui-context-menu).
export default class extends Controller {
  static targets = [ "popover", "trigger" ]
  static values = {
    side: { type: String, default: "bottom" },
    align: { type: String, default: "start" },
    offset: { type: Number, default: 4 },
    alignOffset: { type: Number, default: 0 },
    hover: { type: Boolean, default: false },
    openDelay: { type: Number, default: 600 },
    closeDelay: { type: Number, default: 300 }
  }

  #point = null
  #openTimer = null
  #closeTimer = null
  #subTimer = null
  #hoverOpened = false
  #subByHover = false

  connect() {
    if (this.hoverValue) {
      this.element.addEventListener("pointerenter", this.#hoverIn)
      this.element.addEventListener("pointerleave", this.#hoverOut)
      this.element.addEventListener("focusin", this.#hoverIn)
      this.element.addEventListener("focusout", this.#hoverOut)
      this.element.addEventListener("click", this.#pin, true)
    }
  }

  disconnect() {
    this.element.removeEventListener("pointerenter", this.#hoverIn)
    this.element.removeEventListener("pointerleave", this.#hoverOut)
    this.element.removeEventListener("focusin", this.#hoverIn)
    this.element.removeEventListener("focusout", this.#hoverOut)
    this.element.removeEventListener("click", this.#pin, true)
    this.#clearTimers()
  }

  popoverTargetConnected(popover) {
    // Capture, so a sub-menu's toggle (which doesn't bubble) reaches it too.
    popover.addEventListener("toggle", this.#toggled, true)
    popover.addEventListener("keydown", this.#keydown)
    popover.addEventListener("click", this.#clicked)
    popover.addEventListener("pointerover", this.#pointerOver)
  }

  popoverTargetDisconnected(popover) {
    popover.removeEventListener("toggle", this.#toggled, true)
    popover.removeEventListener("keydown", this.#keydown)
    popover.removeEventListener("click", this.#clicked)
    popover.removeEventListener("pointerover", this.#pointerOver)
    window.removeEventListener("resize", this.#reposition)
    window.removeEventListener("scroll", this.#reposition, true)
  }

  open() {
    if (this.hasPopoverTarget && !this.popoverTarget.matches(":popover-open")) this.popoverTarget.showPopover()
  }

  close() {
    if (this.hasPopoverTarget && this.popoverTarget.matches(":popover-open")) this.popoverTarget.hidePopover()
  }

  // A context menu: opens where the pointer is (or under the focused area's corner from the
  // keyboard's context-menu key).
  openAt(event) {
    if (this.popoverTarget.contains(event.target)) return
    event.preventDefault()
    const area = event.currentTarget.getBoundingClientRect()
    this.#point = event.clientX || event.clientY ? { x: event.clientX, y: event.clientY } : { x: area.left, y: area.bottom }
    if (this.popoverTarget.matches(":popover-open")) {
      this.#place()
    } else {
      this.popoverTarget.showPopover()
    }
  }

  get #trigger() {
    if (this.hasTriggerTarget) return this.triggerTarget
    return this.element.querySelector(`[popovertarget="${this.popoverTarget.id}"]`)
  }

  #isMenu(element) {
    return element.classList.contains("ui-menu")
  }

  // The items of one menu: a sub-menu's items belong to it, not to the menu around it.
  #itemsOf(menu) {
    return [ ...menu.querySelectorAll(".ui-menu__item:not([aria-disabled=true]):not(:disabled)") ]
      .filter(item => item.closest(".ui-menu") === menu && item.offsetParent !== null)
  }

  #subTriggerFor(sub) {
    return this.popoverTarget.querySelector(`[popovertarget="${sub.id}"]`)
  }

  #subOf(trigger) {
    const id = trigger?.getAttribute("popovertarget")
    return id ? document.getElementById(id) : null
  }

  #toggled = (event) => {
    const popover = event.target
    const open = event.newState === "open"

    if (popover !== this.popoverTarget) return this.#subToggled(popover, open)

    this.#trigger?.setAttribute("aria-expanded", open)

    if (open) {
      this.#place()
      window.addEventListener("resize", this.#reposition)
      window.addEventListener("scroll", this.#reposition, true)
      if (this.#isMenu(popover) && !this.#hoverOpened) this.#itemsOf(popover)[0]?.focus({ preventScroll: true })
    } else {
      this.#point = null
      this.#hoverOpened = false
      window.removeEventListener("resize", this.#reposition)
      window.removeEventListener("scroll", this.#reposition, true)
    }
  }

  #subToggled(sub, open) {
    const trigger = this.#subTriggerFor(sub)
    if (!trigger) return

    trigger.setAttribute("aria-expanded", open)
    if (open) {
      this.#placeSub(sub, trigger)
      if (!this.#subByHover) this.#itemsOf(sub)[0]?.focus({ preventScroll: true })
    } else if (sub.contains(document.activeElement)) {
      trigger.focus({ preventScroll: true })
    }
    this.#subByHover = false
  }

  #reposition = () => {
    this.#place()
    this.popoverTarget.querySelectorAll(".ui-menu--sub:popover-open").forEach(sub => {
      const trigger = this.#subTriggerFor(sub)
      if (trigger) this.#placeSub(sub, trigger)
    })
  }

  #place() {
    const popover = this.popoverTarget
    let anchor

    if (this.#point) {
      anchor = new DOMRect(this.#point.x, this.#point.y, 0, 0)
    } else {
      const trigger = this.#trigger
      if (!trigger) return
      anchor = trigger.getBoundingClientRect()
      // A menu is at least as wide as its trigger (DropdownMenuContent's w-(--anchor-width)).
      popover.style.setProperty("--ui-anchor-width", `${anchor.width}px`)
    }

    const side = this.#point ? "right" : this.sideValue
    this.#position(popover, anchor, side, this.alignValue, this.#point ? 0 : this.offsetValue, this.alignOffsetValue)
  }

  // DropdownMenuSubContent: to the right, its top 3px above the trigger's.
  #placeSub(sub, trigger) {
    this.#position(sub, trigger.getBoundingClientRect(), "right", "start", 0, -3)
  }

  // Puts the popover on a side of the anchor, flipping to the other side when it doesn't fit,
  // and marks the side it took (data-side) for the slide it comes in with.
  #position(popover, anchor, side, align, offset, alignOffset) {
    const box = popover.getBoundingClientRect()
    const margin = 8
    const vertical = side === "top" || side === "bottom"
    let top, left

    if (vertical) {
      const below = anchor.bottom + offset
      const above = anchor.top - box.height - offset
      if (side === "bottom") {
        top = below + box.height > window.innerHeight - margin && above > margin ? above : below
      } else {
        top = above < margin && below + box.height < window.innerHeight - margin ? below : above
      }
      side = top === below ? "bottom" : "top"

      left = anchor.left + alignOffset
      if (align === "end") left = anchor.right - box.width - alignOffset
      if (align === "center") left = anchor.left + (anchor.width - box.width) / 2
    } else {
      const right = anchor.right + offset
      const leftSide = anchor.left - box.width - offset
      if (side === "right") {
        left = right + box.width > window.innerWidth - margin && leftSide > margin ? leftSide : right
      } else {
        left = leftSide < margin && right + box.width < window.innerWidth - margin ? right : leftSide
      }
      side = left === right ? "right" : "left"

      top = anchor.top + alignOffset
      if (align === "end") top = anchor.bottom - box.height - alignOffset
      if (align === "center") top = anchor.top + (anchor.height - box.height) / 2
    }

    left = Math.max(margin, Math.min(left, window.innerWidth - box.width - margin))
    top = Math.max(margin, Math.min(top, window.innerHeight - box.height - margin))

    popover.style.top = `${top}px`
    popover.style.left = `${left}px`
    popover.dataset.side = side
    popover.dataset.placed = ""
  }

  #clicked = (event) => {
    const item = event.target.closest(".ui-menu__item")
    if (!item) return
    if (item.classList.contains("ui-menu__sub-trigger")) {
      // Hover opened it already: the click keeps it open rather than toggling it shut.
      if (this.#subOf(item)?.matches(":popover-open")) event.preventDefault()
      return
    }
    // A checkable item stays open, as shadcn's checkbox items do.
    if (!item.querySelector("input[type=checkbox]")) requestAnimationFrame(() => this.close())
  }

  // Hovering a sub-trigger opens its sub-menu; hovering another item of the same menu closes it.
  #pointerOver = (event) => {
    if (event.pointerType === "touch") return

    const item = event.target.closest(".ui-menu__item")
    if (!item) return
    const menu = item.closest(".ui-menu")

    clearTimeout(this.#subTimer)
    this.#subTimer = setTimeout(() => {
      menu.querySelectorAll(".ui-menu--sub:popover-open").forEach(sub => {
        if (sub.parentElement.closest(".ui-menu") === menu && this.#subTriggerFor(sub) !== item) sub.hidePopover()
      })

      const sub = item.classList.contains("ui-menu__sub-trigger") && this.#subOf(item)
      if (sub && !sub.matches(":popover-open")) {
        this.#subByHover = true
        sub.showPopover()
      }
    }, 100)
  }

  #keydown = (event) => {
    const menu = event.target.closest(".ui-menu")
    if (!menu || !this.popoverTarget.contains(menu)) return

    const items = this.#itemsOf(menu)
    const index = items.indexOf(document.activeElement)
    const current = items[index]
    let next

    switch (event.key) {
      case "ArrowDown": next = items[(index + 1) % items.length]; break
      case "ArrowUp": next = items[(index - 1 + items.length) % items.length]; break
      case "Home": next = items[0]; break
      case "End": next = items.at(-1); break
      case "ArrowRight": {
        const sub = current?.classList.contains("ui-menu__sub-trigger") && this.#subOf(current)
        if (!sub) return
        event.preventDefault()
        event.stopPropagation()
        if (sub.matches(":popover-open")) this.#itemsOf(sub)[0]?.focus()
        else sub.showPopover()
        return
      }
      case "ArrowLeft":
        if (!menu.classList.contains("ui-menu--sub")) return
        event.preventDefault()
        event.stopPropagation()
        menu.hidePopover()
        return
      case "Tab": this.close(); return
      default:
        if (event.key.length === 1 && /\S/.test(event.key)) {
          const letter = event.key.toLowerCase()
          const after = [ ...items.slice(index + 1), ...items.slice(0, index + 1) ]
          next = after.find(item => item.textContent.trim().toLowerCase().startsWith(letter))
        }
    }

    if (next) {
      event.preventDefault()
      event.stopPropagation()
      next.focus()
    }
  }

  // Hover cards and navigation menus

  #hoverIn = (event) => {
    if (event.type === "focusin" && !event.target.matches(":focus-visible")) return
    clearTimeout(this.#closeTimer)
    if (this.popoverTarget.matches(":popover-open")) return

    clearTimeout(this.#openTimer)
    this.#openTimer = setTimeout(() => {
      if (this.popoverTarget.matches(":popover-open")) return
      this.#hoverOpened = true
      this.open()
    }, this.openDelayValue)
  }

  #hoverOut = (event) => {
    if (event.type === "focusout" && this.element.contains(event.relatedTarget)) return
    clearTimeout(this.#openTimer)
    if (!this.#hoverOpened) return

    clearTimeout(this.#closeTimer)
    this.#closeTimer = setTimeout(() => this.close(), this.closeDelayValue)
  }

  // A click on the trigger of a popover hover opened keeps it open rather than toggling it shut.
  #pin = (event) => {
    if (!this.#hoverOpened || !event.target.closest("[popovertarget]")) return
    if (this.#trigger?.contains(event.target)) {
      event.preventDefault()
      this.#hoverOpened = false
      clearTimeout(this.#closeTimer)
    }
  }

  #clearTimers() {
    clearTimeout(this.#openTimer)
    clearTimeout(this.#closeTimer)
    clearTimeout(this.#subTimer)
  }
}
