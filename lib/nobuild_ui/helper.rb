module NobuildUi
  # Builders for the kit's components. The CSS classes are the components; these only spell
  # them, the way shadcn's buttonVariants() and badgeVariants() do, so a view writes
  # ui_button("Save") or link_to(…, class: ui_button_classes(:outline)).
  #
  # Icons: pass icon: "name" and the helper calls the app's icon_tag(name) when it has one.
  # An app re-defines any of these in its own helper to change them (its helpers come later).
  module Helper
    BUTTON_VARIANTS = %i[default destructive outline secondary ghost link].freeze
    BUTTON_SIZES = %i[default sm lg icon icon_sm icon_lg].freeze
    BADGE_VARIANTS = %i[default secondary destructive outline positive warning info negative neutral count].freeze

    # Every stylesheet of the kit, tokens first, for the layout's <head> before the app's own:
    #   <%= nobuild_ui_stylesheet_tags %>   (font: false leaves Inter out)
    def nobuild_ui_stylesheet_tags(font: true, **options)
      names = NobuildUi::STYLESHEETS.dup
      names.insert(1, "font") if font
      safe_join(names.map { stylesheet_link_tag("nobuild_ui/#{it}", **options) }, "\n")
    end

    # Class names for a button: ui_button_classes(:outline, size: :sm, class: "x").
    def ui_button_classes(variant = :default, size: :default, full_width: false, **options)
      variant = variant.to_sym
      size = size.to_sym
      raise ArgumentError, "unknown button variant #{variant}" unless BUTTON_VARIANTS.include?(variant)
      raise ArgumentError, "unknown button size #{size}" unless BUTTON_SIZES.include?(size)

      class_names("ui-button",
        "ui-button--#{variant}" => variant != :default,
        "ui-button--#{size.to_s.dasherize}" => size != :default,
        "ui-button--block" => full_width,
        options[:class] => options[:class].present?)
    end

    # A <button>: ui_button("Save"), ui_button(variant: :outline) { … }, or with an icon:
    # ui_button("Add", icon: "add"). type defaults to "button"; pass type: "submit" in a form.
    def ui_button(text = nil, variant: :default, size: :default, icon: nil, full_width: false, **options, &block)
      options[:type] ||= "button"
      options[:class] = ui_button_classes(variant, size: size, full_width: full_width, class: options[:class])
      tag.button(**options) { ui_icon_and_content(text, icon, &block) }
    end

    # A link drawn as a button: ui_link_button("New client", new_client_path, variant: :outline).
    def ui_link_button(text, url, variant: :default, size: :default, icon: nil, full_width: false, **options)
      options[:class] = ui_button_classes(variant, size: size, full_width: full_width, class: options[:class])
      link_to(url, **options) { ui_icon_and_content(text, icon) }
    end

    # A badge: ui_badge("Active", :positive).
    def ui_badge(text, variant = :default, **options)
      variant = variant.to_sym
      raise ArgumentError, "unknown badge variant #{variant}" unless BADGE_VARIANTS.include?(variant)

      tag.span text, **options, class: class_names("ui-badge", "ui-badge--#{variant}" => variant != :default, options[:class] => options[:class].present?)
    end

    # ui_kbd("⌘", "K")
    def ui_kbd(*keys)
      return tag.kbd(keys.first, class: "ui-kbd") if keys.one?

      tag.span(safe_join(keys.map { tag.kbd(it, class: "ui-kbd") }), class: "ui-kbd-group")
    end

    # Initials in a circle, or the image when there is one: ui_avatar("Ted Martin", size: :sm).
    def ui_avatar(name, image: nil, size: nil, **options)
      classes = class_names("ui-avatar", "ui-avatar--#{size}" => size, options.delete(:class) => true)
      tag.span(class: classes, title: name, **options) do
        if image
          image_tag(image, alt: name)
        else
          name.to_s.split.first(2).map { it[0] }.join.upcase
        end
      end
    end

    # A dropdown menu (shadcn's DropdownMenu): a trigger button and a native popover menu the
    # ui--popover controller places under it, with arrow keys, type-ahead and light dismiss.
    #
    #   <%= ui_dropdown "Active (15)", label: "Show…", id: "status-filter" do %>
    #     <%= ui_menu_item "Active (15)", clients_path(status: "active"), checked: true %>
    #     <%= ui_menu_separator %>
    #     <%= ui_menu_item "Delete", path, method: :delete, destructive: true %>
    #   <% end %>
    #
    # trigger: :outline (a select-like button with a chevron, the default) or any button
    # variant; or pass trigger_content: to draw the trigger yourself. align: :start, :center
    # or :end; side: :bottom or :top.
    def ui_dropdown(text = nil, id:, label: nil, variant: :outline, size: :sm, align: :start, side: :bottom,
                    icon: nil, chevron: true, trigger_class: nil, menu_class: nil, trigger_content: nil, **options, &block)
      controller = { controller: "ui--popover", "ui--popover-align-value": align, "ui--popover-side-value": side }
      options[:data] = controller.merge(options[:data] || {})
      options[:class] = class_names("ui-dropdown", options[:class])

      tag.div(**options) do
        trigger = tag.button(type: "button", popovertarget: id, aria: { haspopup: "menu", expanded: false },
                             class: ui_button_classes(variant, size: size, class: class_names("ui-dropdown__trigger", trigger_class))) do
          trigger_content || safe_join([ ui_icon_and_content(text, icon), (tag.span(class: "ui-dropdown__chevron", aria: { hidden: true }) if chevron) ].compact)
        end
        menu = tag.div(id: id, popover: "auto", role: "menu", class: class_names("ui-menu", menu_class), data: { "ui--popover-target": "popover" }) do
          safe_join([ (ui_menu_label(label) if label), capture(&block) ].compact)
        end
        safe_join([ trigger, menu ])
      end
    end

    # One item of a menu: a link (url), a button_to (method:), or a plain button.
    # checked: true/false makes it checkable (a check on the right while true).
    def ui_menu_item(text = nil, url = nil, checked: nil, destructive: false, icon: nil, shortcut: nil, method: nil, **options, &block)
      options[:class] = class_names("ui-menu__item", "ui-menu__item--destructive" => destructive, options[:class] => options[:class].present?)
      unless checked.nil?
        options[:role] ||= "menuitemcheckbox"
        options[:aria] = { checked: checked }.merge(options[:aria] || {})
      end
      options[:role] ||= "menuitem"
      content = safe_join([ ui_icon_and_content(text, icon, &block), (tag.kbd(shortcut, class: "ui-menu__shortcut") if shortcut) ].compact)

      if url && method && method.to_s != "get"
        button_to(url, method: method, **options) { content }
      elsif url
        link_to(url, **options) { content }
      else
        tag.button(type: options.delete(:type) || "button", **options) { content }
      end
    end

    def ui_menu_label(text, **options)
      tag.div text, **options, class: class_names("ui-menu__label", options[:class])
    end

    def ui_menu_separator
      tag.hr(class: "ui-menu__separator")
    end

    private
      def ui_icon_and_content(text, icon, &block)
        parts = []
        parts << icon_tag(icon) if icon && respond_to?(:icon_tag)
        parts << (block ? capture(&block) : text)
        safe_join(parts.compact)
      end
  end
end
