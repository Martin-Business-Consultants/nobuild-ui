module NobuildUi
  module Helpers
    # Builders for the overlays components (overlays.css, command.css). See the files' header
    # comments for the markup. Dialogs, sheets and drawers are native <dialog>s that open
    # with no JavaScript from ui_dialog_trigger (the command="show-modal" invoker), or from an
    # app's own dialog controller; popups are native popovers placed by ui--popover.
    module Overlays
      DIALOG_SIZES = %i[default sm md lg].freeze
      SHEET_SIDES = %i[right left top bottom].freeze
      DRAWER_SIDES = %i[bottom top left right].freeze
      TOOLTIP_SIDES = %i[top bottom left right].freeze
      # lucide's x, as shadcn's close buttons draw it.
      CLOSE_ICON = '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" ' \
        'stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">' \
        '<path d="M18 6 6 18"/><path d="m6 6 12 12"/></svg>'

      # A dialog (DialogContent): the header from title: and description:, the block as its
      # body, and a ✕ unless close_button: false. Put ui_dialog_footer last in the block.
      #
      #   <%= ui_dialog id: "edit-profile", title: "Edit profile", description: "…" do %>
      #     …fields…
      #     <%= ui_dialog_footer { ui_dialog_close("Cancel", target: "edit-profile") + ui_button("Save", type: "submit") } %>
      #   <% end %>
      def ui_dialog(id:, title: nil, description: nil, size: :default, close_button: true, closedby: "any", **options, &block)
        size = size.to_sym
        raise ArgumentError, "unknown dialog size #{size}" unless DIALOG_SIZES.include?(size)

        options[:class] = class_names("ui-dialog", "ui-dialog--#{size}" => size != :default, options[:class] => options[:class].present?)
        ui_modal(:dialog, id, title, description, close_button, closedby, options, &block)
      end

      # A button that opens the dialog, sheet or drawer with this id, with no JavaScript.
      def ui_dialog_trigger(text = nil, target:, variant: :outline, size: :default, icon: nil, **options, &block)
        ui_button(text, variant: variant, size: size, icon: icon, command: "show-modal", commandfor: target, aria: { haspopup: "dialog" }, **options, &block)
      end

      # A button that closes the dialog with this id, as DialogClose does.
      def ui_dialog_close(text = "Cancel", target:, variant: :outline, size: :default, **options, &block)
        ui_button(text, variant: variant, size: size, command: "close", commandfor: target, **options, &block)
      end

      def ui_dialog_footer(**options, &block)
        tag.footer(**options, class: class_names("ui-dialog__footer", options[:class]), &block)
      end

      # An alert dialog: a question that needs an answer, with no ✕ and no click-away. The
      # block is the footer's buttons; media: is an icon (or any markup) above the title.
      #
      #   <%= ui_alert_dialog id: "delete", title: "Delete this client?", description: "…" do %>
      #     <%= ui_dialog_close "Cancel", target: "delete" %>
      #     <%= ui_button "Delete", variant: :destructive %>
      #   <% end %>
      def ui_alert_dialog(id:, title:, description: nil, media: nil, size: :default, **options, &block)
        options[:class] = class_names("ui-alert-dialog", "ui-alert-dialog--sm" => size.to_sym == :sm, options[:class] => options[:class].present?)
        options[:role] ||= "alertdialog"
        tag.dialog(id: id, aria: { labelledby: "#{id}-title", describedby: ("#{id}-description" if description) }, **options) do
          header = tag.header(class: "ui-alert-dialog__header") do
            safe_join([
              (tag.span(media, class: "ui-alert-dialog__media") if media),
              tag.h2(title, id: "#{id}-title", class: "ui-alert-dialog__title"),
              (tag.p(description, id: "#{id}-description", class: "ui-alert-dialog__description") if description)
            ].compact)
          end
          footer = tag.footer(class: "ui-alert-dialog__footer") { capture(&block) } if block
          safe_join([ header, footer ].compact)
        end
      end

      # A sheet (SheetContent) from side: :right (default), :left, :top or :bottom. footer: is
      # markup for SheetFooter, pinned to the end.
      def ui_sheet(id:, title: nil, description: nil, side: :right, footer: nil, close_button: true, closedby: "any", **options, &block)
        side = side.to_sym
        raise ArgumentError, "unknown sheet side #{side}" unless SHEET_SIDES.include?(side)

        options[:class] = class_names("ui-sheet", "ui-sheet--#{side}" => side != :right, options[:class] => options[:class].present?)
        ui_modal(:sheet, id, title, description, close_button, closedby, options, footer: footer, &block)
      end

      # A drawer (DrawerContent): a sheet from the bottom (or side:) with a handle. The body
      # sets its own padding, as shadcn's examples do.
      def ui_drawer(id:, title: nil, description: nil, side: :bottom, footer: nil, closedby: "any", **options, &block)
        side = side.to_sym
        raise ArgumentError, "unknown drawer side #{side}" unless DRAWER_SIDES.include?(side)

        options[:class] = class_names("ui-drawer", "ui-drawer--#{side}" => side != :bottom, options[:class] => options[:class].present?)
        ui_modal(:drawer, id, title, description, false, closedby, options, footer: footer, handle: true, &block)
      end

      # A popover (PopoverContent) under its trigger button. title: and description: make its
      # header; the block is the rest.
      #
      #   <%= ui_popover "Open popover", id: "dimensions", title: "Dimensions" do %>…<% end %>
      def ui_popover(text = nil, id:, title: nil, description: nil, variant: :outline, size: :default, icon: nil,
                     align: :center, side: :bottom, trigger_content: nil, trigger_class: nil, popover_class: nil, **options, &block)
        ui_popup_wrapper(options, align: align, side: side) do
          trigger = tag.button(type: "button", popovertarget: id, aria: { haspopup: "dialog", expanded: false },
                               class: ui_button_classes(variant, size: size, class: trigger_class)) do
            trigger_content || ui_icon_and_content(text, icon)
          end
          popover = tag.div(id: id, popover: "auto", role: "dialog", class: class_names("ui-popover", popover_class),
                            aria: { labelledby: ("#{id}-title" if title) }, data: { "ui--popover-target": "popover" }) do
            header = if title || description
              tag.div(class: "ui-popover__header") do
                safe_join([
                  (tag.h4(title, id: "#{id}-title", class: "ui-popover__title") if title),
                  (tag.p(description, class: "ui-popover__description") if description)
                ].compact)
              end
            end
            safe_join([ header, (capture(&block) if block) ].compact)
          end
          safe_join([ trigger, popover ])
        end
      end

      # A hover card: trigger: is the markup hovered (a link, an avatar), the block the card.
      #
      #   <%= ui_hover_card id: "hc-nextjs", trigger: link_to("@nextjs", url) do %>…<% end %>
      def ui_hover_card(id:, trigger:, align: :center, side: :bottom, open_delay: 600, close_delay: 300, card_class: nil, **options, &block)
        options[:data] = { "ui--popover-hover-value": true, "ui--popover-open-delay-value": open_delay,
                           "ui--popover-close-delay-value": close_delay }.merge(options[:data] || {})
        ui_popup_wrapper(options, tag_name: :span, align: align, side: side) do
          safe_join([
            tag.span(trigger, class: "ui-hover-card__trigger", aria: { describedby: id }, data: { "ui--popover-target": "trigger" }),
            tag.div(id: id, popover: "manual", class: class_names("ui-hover-card", card_class), data: { "ui--popover-target": "popover" }, &block)
          ])
        end
      end

      # A tooltip around the block (the trigger): ui_tooltip("Add to library") { ui_button … }.
      def ui_tooltip(text, side: :top, **options, &block)
        side = side.to_sym
        raise ArgumentError, "unknown tooltip side #{side}" unless TOOLTIP_SIDES.include?(side)

        options[:class] = class_names("ui-tooltip", "ui-tooltip--#{side}" => side != :top, options[:class] => options[:class].present?)
        tag.span(**options) do
          safe_join([ capture(&block), tag.span(text, role: "tooltip", class: "ui-tooltip__content") ])
        end
      end

      # Items for ui_dropdown, ui_context_menu and ui_menubar_menu menus beside ui_menu_item.

      # A group of items (DropdownMenuGroup), optionally under a label.
      def ui_menu_group(label = nil, **options, &block)
        tag.div(role: "group", **options, class: class_names("ui-menu__group", options[:class])) do
          safe_join([ (ui_menu_label(label) if label), capture(&block) ].compact)
        end
      end

      # A sub-menu (DropdownMenuSub): an item that opens the block's items to the side.
      def ui_menu_sub(text, id:, icon: nil, inset: false, **options, &block)
        tag.div(class: "ui-menu__sub") do
          trigger = tag.button(type: "button", popovertarget: id, role: "menuitem", aria: { haspopup: "menu", expanded: false },
                               class: class_names("ui-menu__item ui-menu__sub-trigger", "ui-menu__item--inset" => inset)) do
            ui_icon_and_content(text, icon)
          end
          menu = tag.div(id: id, popover: "auto", role: "menu", **options, class: class_names("ui-menu ui-menu--sub", options[:class]), &block)
          safe_join([ trigger, menu ])
        end
      end

      # A checkbox item (DropdownMenuCheckboxItem): a real checkbox, so it submits in a form;
      # the menu stays open while it's toggled.
      def ui_menu_checkbox_item(text, name: nil, value: "1", checked: false, inset: false, **options)
        tag.label(class: class_names("ui-menu__item", "ui-menu__item--inset" => inset, options.delete(:class) => true)) do
          safe_join([ tag.input(type: "checkbox", name: name, value: value, checked: checked, tabindex: -1, **options), text ])
        end
      end

      # A radio item (DropdownMenuRadioItem); items sharing a name: are one radio group.
      def ui_menu_radio_item(text, name:, value:, checked: false, inset: false, **options)
        tag.label(class: class_names("ui-menu__item", "ui-menu__item--inset" => inset, options.delete(:class) => true)) do
          safe_join([ tag.input(type: "radio", name: name, value: value, checked: checked, tabindex: -1, **options), text ])
        end
      end

      # A context menu: area: is what's right-clicked (text or markup), the block the items.
      #
      #   <%= ui_context_menu id: "row-menu", area: "Right click here" do %>
      #     <%= ui_menu_item "Back", shortcut: "⌘[" %>
      #   <% end %>
      def ui_context_menu(id:, area:, menu_class: nil, **options, &block)
        options[:class] = class_names("ui-context-menu", options[:class])
        options[:data] = { controller: "ui--popover", action: "contextmenu->ui--popover#openAt" }.merge(options[:data] || {})
        tag.div(**options) do
          safe_join([
            area,
            tag.div(id: id, popover: "auto", role: "menu", class: class_names("ui-menu ui-menu--context", menu_class),
                    data: { "ui--popover-target": "popover" }, &block)
          ])
        end
      end

      # A menubar of ui_menubar_menu's.
      def ui_menubar(**options, &block)
        options[:data] = { controller: "ui--menubar" }.merge(options[:data] || {})
        tag.div(role: "menubar", **options, class: class_names("ui-menubar", options[:class]), &block)
      end

      def ui_menubar_menu(text, id:, menu_class: nil, &block)
        tag.div(data: { controller: "ui--popover", "ui--popover-offset-value": 8, "ui--popover-align-offset-value": -4 }) do
          safe_join([
            tag.button(text, type: "button", role: "menuitem", popovertarget: id, class: "ui-menubar__trigger",
                       aria: { haspopup: "menu", expanded: false }),
            tag.div(id: id, popover: "auto", role: "menu", class: class_names("ui-menu ui-menu--menubar", menu_class),
                    data: { "ui--popover-target": "popover" }, &block)
          ])
        end
      end

      # A navigation menu of ui_navigation_menu_item's (and plain links:
      # tag.li(link_to("Docs", path, class: "ui-navigation-menu__trigger"), class: "ui-navigation-menu__item")).
      def ui_navigation_menu(**options, &block)
        tag.nav(**options, class: class_names("ui-navigation-menu", options[:class])) do
          tag.ul(class: "ui-navigation-menu__list", &block)
        end
      end

      # An item whose content opens on hover or click under its trigger.
      def ui_navigation_menu_item(text, id:, content_class: nil, &block)
        data = { controller: "ui--popover", "ui--popover-hover-value": true, "ui--popover-open-delay-value": 50,
                 "ui--popover-close-delay-value": 200, "ui--popover-offset-value": 8 }
        tag.li(class: "ui-navigation-menu__item", data: data) do
          safe_join([
            tag.button(type: "button", popovertarget: id, class: "ui-navigation-menu__trigger", aria: { expanded: false }) do
              safe_join([ text, tag.span(class: "ui-navigation-menu__chevron", aria: { hidden: true }) ])
            end,
            tag.div(id: id, popover: "auto", class: class_names("ui-navigation-menu__content", content_class),
                    data: { "ui--popover-target": "popover" }, &block)
          ])
        end
      end

      # A link in a navigation menu's content: a title over a description, or just text.
      def ui_navigation_menu_link(text, url, description: nil, current: false, icon: nil, **options)
        options[:class] = class_names("ui-navigation-menu__link", options[:class])
        options[:aria] = { current: ("page" if current) }.merge(options[:aria] || {})
        link_to(url, **options) do
          if description
            safe_join([ tag.span(text, class: "ui-navigation-menu__link-title"),
                        tag.span(description, class: "ui-navigation-menu__link-description") ])
          else
            ui_icon_and_content(text, icon)
          end
        end
      end

      # A toast (sonner) for a .ui-toaster: ui_toast("Event created", description: "Sunday…").
      def ui_toast(title, description: nil, icon: nil, action: nil, variant: nil, **options)
        options[:class] = class_names("ui-toast", "ui-toast--#{variant}" => variant, options[:class] => options[:class].present?)
        options[:role] ||= variant.to_s == "error" ? "alert" : "status"
        tag.div(**options) do
          safe_join([
            (icon_tag(icon) if icon && respond_to?(:icon_tag)),
            tag.div(class: "ui-toast__content") do
              safe_join([ tag.div(title, class: "ui-toast__title"),
                          (tag.div(description, class: "ui-toast__description") if description) ].compact)
            end,
            action
          ].compact)
        end
      end

      private
        def ui_modal(kind, id, title, description, close_button, closedby, options, footer: nil, handle: false, &block)
          options[:aria] = { labelledby: ("#{id}-title" if title), describedby: ("#{id}-description" if description) }.merge(options[:aria] || {})
          options[:closedby] = closedby if closedby
          tag.dialog(id: id, **options) do
            close = if close_button
              tag.button(type: "button", command: "close", commandfor: id, aria: { label: "Close" },
                         class: ui_button_classes(:ghost, size: :icon_sm, class: "ui-#{kind == :dialog ? "dialog" : kind}__close")) do
                CLOSE_ICON.html_safe
              end
            end
            header = if title || description
              tag.header(class: "ui-#{kind}__header") do
                safe_join([
                  (tag.h2(title, id: "#{id}-title", class: "ui-#{kind}__title") if title),
                  (tag.p(description, id: "#{id}-description", class: "ui-#{kind}__description") if description)
                ].compact)
              end
            end
            foot = tag.footer(footer, class: "ui-#{kind}__footer") if footer
            safe_join([ (tag.div(class: "ui-drawer__handle", aria: { hidden: true }) if handle), close, header,
                        (capture(&block) if block), foot ].compact)
          end
        end

        def ui_popup_wrapper(options, align:, side:, tag_name: :div, &block)
          options[:data] = { controller: "ui--popover", "ui--popover-align-value": align, "ui--popover-side-value": side }.merge(options[:data] || {})
          tag.public_send(tag_name, **options, &block)
        end
    end
  end
end
