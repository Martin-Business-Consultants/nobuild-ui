module NobuildUi
  module Helpers
    # Builders for the forms components. See the files' header comments for the markup
    # (forms.css, select.css, combobox.css, slider.css, input-otp.css).
    #
    # Choices, for ui_select_menu and ui_combobox, are what options_for_select takes: strings,
    # [label, value] pairs, or a hash of group label => those, drawn as labelled groups.
    module Forms
      INPUT_GROUP_ALIGNS = %i[inline_start inline_end block_start block_end].freeze

      # NativeSelect: a select with shadcn's icon beside it, w-fit.
      #   <%= ui_native_select(size: :sm) { form.select :status, choices, {}, class: "ui-select" } %>
      def ui_native_select(size: :default, **options, &block)
        options[:class] = class_names("ui-native-select", "ui-native-select--sm" => size.to_sym == :sm, options[:class] => options[:class].present?)
        tag.div(**options) do
          safe_join([ capture(&block), tag.span(class: "ui-native-select__icon", aria: { hidden: true }) ])
        end
      end

      # Select (shadcn's Select): a trigger button and a listbox popover, the choice posted
      # through a hidden input named name. Needs the ui--popover and ui--select controllers.
      #   <%= ui_select_menu "client[status]", [["Active", "active"], ["Paused", "paused"]],
      #         selected: @client.status, placeholder: "Pick a status", id: "client-status" %>
      # size: :default or :sm; align: :start, :center or :end. Further options go on the trigger.
      def ui_select_menu(name, choices, id:, selected: nil, placeholder: nil, size: :default, align: :start, label: nil,
                         disabled: false, wrapper: {}, **options)
        groups = ui_choice_groups(choices)
        chosen = groups.flat_map(&:last).find { |(_, value)| value == selected.to_s } unless selected.nil?
        list_id = "#{id}-listbox"

        wrapper = wrapper.merge(class: class_names("ui-select-menu", wrapper[:class]),
          data: { controller: "ui--popover ui--select", "ui--popover-align-value": align }.merge(wrapper[:data] || {}))

        tag.div(**wrapper) do
          hidden = hidden_field_tag(name, chosen&.last, id: nil, data: { "ui--select-target": "input" })

          trigger_options = options.merge(type: "button", id: id, popovertarget: list_id, disabled: disabled,
            class: class_names("ui-select__trigger", "ui-select__trigger--sm" => size.to_sym == :sm, options[:class] => options[:class].present?),
            aria: { haspopup: "listbox", expanded: false, label: label }.compact.merge(options[:aria] || {}),
            data: { placeholder: (chosen ? nil : "") }.compact.merge(options[:data] || {}))
          trigger = tag.button(**trigger_options) do
            safe_join([
              tag.span(chosen ? chosen.first : placeholder, class: "ui-select__value", data: { "ui--select-target": "value" }),
              tag.span(class: "ui-select__icon", aria: { hidden: true })
            ])
          end

          listbox = tag.div(id: list_id, popover: "auto", role: "listbox", class: "ui-menu ui-select__content",
                            data: { "ui--popover-target": "popover", "ui--select-target": "listbox" }) do
            safe_join(groups.each_with_index.map do |(group_label, items), index|
              group = tag.div(class: "ui-select__group", role: "group", aria: { label: group_label }.compact) do
                safe_join([
                  (tag.div(group_label, class: "ui-select__label") if group_label),
                  *items.map do |(text, value)|
                    tag.button(text, type: "button", role: "option", class: "ui-menu__item ui-select__item",
                               data: { value: value }, aria: { selected: chosen&.last == value })
                  end
                ].compact)
              end
              index.zero? ? group : safe_join([ tag.hr(class: "ui-select__separator"), group ])
            end)
          end

          safe_join([ hidden, trigger, listbox ])
        end
      end

      # Combobox: an input that filters a listbox under it, the choice posted through a
      # hidden input named name. Needs the ui--combobox controller.
      #   <%= ui_combobox "project[framework]", frameworks, selected: "next", id: "framework",
      #         placeholder: "Select a framework" %>
      # Further options go on the visible input.
      def ui_combobox(name, choices, id:, selected: nil, placeholder: nil, empty: "No items found.", disabled: false,
                      wrapper: {}, **options)
        groups = ui_choice_groups(choices)
        chosen = groups.flat_map(&:last).find { |(_, value)| value == selected.to_s } unless selected.nil?
        list_id = "#{id}-listbox"

        wrapper = wrapper.merge(class: class_names("ui-combobox", wrapper[:class]),
          data: { controller: "ui--combobox" }.merge(wrapper[:data] || {}))

        tag.div(**wrapper) do
          hidden = hidden_field_tag(name, chosen&.last, id: nil, data: { "ui--combobox-target": "hidden" })

          input_options = options.merge(type: "text", id: id, value: chosen&.first, placeholder: placeholder, disabled: disabled,
            role: "combobox", autocomplete: "off",
            class: class_names("ui-input", options[:class] => options[:class].present?),
            aria: { expanded: false, autocomplete: "list", controls: list_id }.merge(options[:aria] || {}),
            data: { "ui--combobox-target": "input" }.merge(options[:data] || {}))

          group = tag.div(class: "ui-input-group") do
            safe_join([
              tag.input(**input_options),
              tag.span(class: "ui-input-group__addon ui-input-group__addon--inline-end") do
                tag.button(type: "button", tabindex: -1, disabled: disabled, aria: { label: "Show options" },
                           class: "ui-button ui-button--ghost ui-input-group__button ui-input-group__button--icon-xs ui-combobox__trigger",
                           data: { action: "ui--combobox#toggle" }) do
                  tag.span(class: "ui-combobox__trigger-icon", aria: { hidden: true })
                end
              end
            ])
          end

          content = tag.div(id: "#{id}-content", popover: "manual", class: "ui-combobox__content", data: { "ui--combobox-target": "content" }) do
            safe_join([
              tag.div(empty, class: "ui-combobox__empty"),
              tag.div(id: list_id, class: "ui-combobox__list", role: "listbox") do
                safe_join(groups.each_with_index.map do |(group_label, items), index|
                  group_tag = tag.div(class: "ui-combobox__group", role: "group", aria: { label: group_label }.compact) do
                    safe_join([
                      (tag.div(group_label, class: "ui-combobox__label") if group_label),
                      *items.each_with_index.map do |(text, value), item_index|
                        tag.div(text, id: "#{id}-option-#{index}-#{item_index}", role: "option", class: "ui-combobox__item",
                                data: { value: value }, aria: { selected: chosen&.last == value })
                      end
                    ].compact)
                  end
                  index.zero? ? group_tag : safe_join([ tag.hr(class: "ui-combobox__separator"), group_tag ])
                end)
              end
            ])
          end

          safe_join([ hidden, group, content ])
        end
      end

      # Slider: a range input drawn as shadcn's, its track filled by the ui--slider controller.
      #   <%= ui_slider_tag "volume", 50, max: 100, step: 5 %>   (vertical: true stands it up)
      def ui_slider_tag(name, value = nil, min: 0, max: 100, step: 1, vertical: false, **options)
        options[:class] = class_names("ui-slider", "ui-slider--vertical" => vertical, options[:class] => options[:class].present?)
        options[:data] = { controller: class_names("ui--slider", options.dig(:data, :controller)) }.merge((options[:data] || {}).except(:controller))
        options[:aria] = { orientation: "vertical" }.merge(options[:aria] || {}) if vertical
        range_field_tag(name, value, min: min, max: max, step: step, **options)
      end

      # A code shown as InputOTP's slots, in groups with a separator (a minus icon when the
      # app has icon_tag) between them: ui_input_otp("ABCDEF", group_size: 3).
      def ui_input_otp(code, group_size: 3, **options)
        options[:class] = class_names("ui-input-otp", options[:class] => options[:class].present?)
        groups = code.to_s.chars.each_slice(group_size).map do |chars|
          tag.div(class: "ui-input-otp__group") { safe_join(chars.map { tag.span(it, class: "ui-input-otp__slot") }) }
        end
        separator = tag.div(role: "separator", class: "ui-input-otp__separator") { respond_to?(:icon_tag) ? icon_tag("minus") : "-" }
        tag.div(role: "img", aria: { label: code }, **options) { safe_join(groups, separator) }
      end

      # InputGroup and InputGroupAddon:
      #   <%= ui_input_group do %>
      #     <%= ui_input_group_addon { icon_tag "search" } %>
      #     <%= text_field_tag :q, nil, class: "ui-input", placeholder: "Search…" %>
      #     <%= ui_input_group_addon "12 results", align: :inline_end %>
      #   <% end %>
      def ui_input_group(**options, &block)
        tag.div(**options, class: class_names("ui-input-group", options[:class])) { capture(&block) }
      end

      def ui_input_group_addon(text = nil, align: :inline_start, **options, &block)
        align = align.to_sym
        raise ArgumentError, "unknown addon align #{align}" unless INPUT_GROUP_ALIGNS.include?(align)

        options[:class] = class_names("ui-input-group__addon", "ui-input-group__addon--#{align.to_s.dasherize}" => align != :inline_start,
          options[:class] => options[:class].present?)
        tag.span(**options) { block ? capture(&block) : text }
      end

      # FieldSeparator, with optional text on the line: ui_field_separator("Or continue with").
      def ui_field_separator(text = nil, **options)
        tag.div(**options, class: class_names("ui-field__separator", options[:class])) do
          tag.span(text, class: "ui-field__separator-content") if text
        end
      end

      private
        # [[group label or nil, [[label, value], …]], …], every value a string.
        def ui_choice_groups(choices)
          pairs = ->(list) { list.map { it.is_a?(Array) ? [ it.first.to_s, it.last.to_s ] : [ it.to_s, it.to_s ] } }
          choices.is_a?(Hash) ? choices.map { |label, list| [ label.to_s, pairs.(list) ] } : [ [ nil, pairs.(choices) ] ]
        end
    end
  end
end
