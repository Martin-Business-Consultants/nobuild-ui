module NobuildUi
  module Helpers
    # Builders for the actions components. See the files' header comments for the markup
    # (button-group.css, toggle.css). ui_button, ui_link_button, ui_button_classes and ui_badge
    # live in NobuildUi::Helper.
    module Actions
      TOGGLE_VARIANTS = %i[default outline].freeze
      TOGGLE_SIZES = %i[default sm lg].freeze

      # Buttons joined edge to edge:
      #   <%= ui_button_group(aria: { label: "View" }) do %> <%= ui_button("Cards", variant: :outline) %> … <% end %>
      # orientation: :vertical stacks them.
      def ui_button_group(orientation: :horizontal, **options, &block)
        vertical = orientation.to_sym == :vertical
        options[:role] ||= "group"
        options[:data] = { orientation: orientation.to_s }.merge(options[:data] || {})
        options[:class] = class_names("ui-button-group", "ui-button-group--vertical" => vertical, options[:class] => options[:class].present?)
        tag.div(**options) { capture(&block) }
      end

      # A muted label cell in a button group: ui_button_group_text("https://"), or with icon:.
      def ui_button_group_text(text = nil, icon: nil, **options, &block)
        options[:class] = class_names("ui-button-group__text", options[:class])
        tag.span(**options) { ui_icon_and_content(text, icon, &block) }
      end

      # A 1px rule between a group's buttons.
      def ui_button_group_separator(**options)
        options[:class] = class_names("ui-button-group__separator", options[:class])
        tag.div(role: "separator", aria: { orientation: "vertical" }, **options)
      end

      # Class names for a toggle: ui_toggle_classes(:outline, size: :sm).
      def ui_toggle_classes(variant = :default, size: :default, **options)
        variant = variant.to_sym
        size = size.to_sym
        raise ArgumentError, "unknown toggle variant #{variant}" unless TOGGLE_VARIANTS.include?(variant)
        raise ArgumentError, "unknown toggle size #{size}" unless TOGGLE_SIZES.include?(size)

        class_names("ui-toggle", "ui-toggle--#{variant}" => variant != :default, "ui-toggle--#{size}" => size != :default,
          options[:class] => options[:class].present?)
      end

      # A two-state button. With name:, a native checkbox inside a <label> holds the state and
      # submits with the form (no JavaScript):
      #   ui_toggle("Bold", name: "bold", pressed: true)
      # Without name:, a <button aria-pressed> the app flips itself (ReActionView state, Stimulus):
      #   ui_toggle(icon: "bold", pressed: bold, aria: { label: "Bold" })
      def ui_toggle(text = nil, pressed: false, name: nil, value: "1", variant: :default, size: :default, icon: nil, disabled: false, **options, &block)
        options[:class] = ui_toggle_classes(variant, size: size, class: options[:class])
        content = ui_icon_and_content(text, icon, &block)

        if name
          tag.label(**options) { safe_join([ check_box_tag(name, value, pressed, id: nil, disabled: disabled), content ]) }
        else
          tag.button(type: "button", aria: { pressed: pressed.to_s }, disabled: disabled, **options) { content }
        end
      end

      # A row of toggles, one or several picked: radios (type: :single) or checkboxes (:multiple)
      # named name:, so the choice submits with the form and needs no JavaScript.
      #   <%= ui_toggle_group(name: "view", variant: :outline, spacing: 0, aria: { label: "View" }) do |group| %>
      #     <%= group.item "Cards", value: "cards", checked: true %>
      #     <%= group.item value: "table", icon: "table", aria: { label: "Table" } %>
      #   <% end %>
      # spacing: 0 joins the items edge to edge (0 to 4, as shadcn's spacing; 2 is the default).
      def ui_toggle_group(name:, type: :single, variant: :default, size: :default, spacing: 2, orientation: :horizontal, **options, &block)
        spacing = spacing.to_i
        raise ArgumentError, "unknown toggle group spacing #{spacing}" unless (0..4).cover?(spacing)

        ui_toggle_classes(variant, size: size) # validates both
        group = ToggleGroup.new(self, name: name, type: type.to_sym, variant: variant, size: size)
        options[:role] ||= type.to_sym == :single ? "radiogroup" : "group"
        options[:class] = class_names("ui-toggle-group",
          "ui-toggle-group--spacing-#{spacing}" => spacing != 2,
          "ui-toggle-group--vertical" => orientation.to_sym == :vertical,
          "ui-toggle-group--#{size}" => size.to_sym != :default,
          options[:class] => options[:class].present?)
        tag.div(**options) { capture(group, &block) }
      end

      # The group handed to ui_toggle_group's block; item draws one toggle in it.
      class ToggleGroup
        def initialize(view, name:, type:, variant:, size:)
          @view, @name, @type, @variant, @size = view, name, type, variant, size
        end

        def item(text = nil, value:, checked: false, icon: nil, disabled: false, **options, &block)
          view = @view
          options[:class] = view.ui_toggle_classes(@variant, size: @size, class: options[:class])
          input =
            if @type == :multiple
              view.check_box_tag("#{@name}[]", value, checked, id: nil, disabled: disabled)
            else
              view.radio_button_tag(@name, value, checked, id: nil, disabled: disabled)
            end
          content = view.send(:ui_icon_and_content, text, icon, &block)
          view.tag.label(**options) { view.safe_join([ input, content ]) }
        end
      end
    end
  end
end
