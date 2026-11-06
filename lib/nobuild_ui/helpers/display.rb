module NobuildUi
  module Helpers
    # Builders for the display components (display.css, accordion.css, pagination.css,
    # spinner.css, aspect-ratio.css). See the files' header comments for the markup.
    module Display
      ITEM_VARIANTS = %i[default outline muted].freeze
      ITEM_SIZES = %i[default sm xs].freeze
      ASPECT_RATIOS = { square: "square", video: "video", "4:3": "4-3", "3:2": "3-2", "21:9": "21-9", portrait: "portrait" }.freeze

      # Tabs: a root holding a list and panels.
      #
      #   <%= ui_tabs do %>
      #     <%= ui_tabs_list label: "Settings", variant: :line do %>
      #       <%= ui_tabs_trigger "Account", account_path, active: true %>
      #       <%= ui_tabs_trigger "Password", password_path %>
      #     <% end %>
      #     <%= ui_tabs_content do %>…<% end %>
      #   <% end %>
      #
      # orientation: :vertical puts the list beside the panels.
      def ui_tabs(orientation: :horizontal, **options, &block)
        options[:class] = class_names("ui-tabs", "ui-tabs--vertical" => orientation.to_sym == :vertical, options[:class] => options[:class].present?)
        options[:data] = { orientation: orientation }.merge(options[:data] || {})
        tag.div(**options, &block)
      end

      # The list of triggers (a <nav>). variant: :default (segmented) or :line (underlined).
      def ui_tabs_list(label: nil, variant: :default, **options, &block)
        options[:class] = class_names("ui-tabs__list", "ui-tabs__list--line" => variant.to_sym == :line, options[:class] => options[:class].present?)
        options[:aria] = { label: label }.compact.merge(options[:aria] || {})
        tag.nav(**options, &block)
      end

      # A trigger: a link to its tab's page (aria-current="page" while active), or with no url a
      # <button> whose aria-pressed the page's own state sets.
      def ui_tabs_trigger(text = nil, url = nil, active: false, icon: nil, **options, &block)
        options[:class] = class_names("ui-tabs__trigger", options[:class] => options[:class].present?)
        content = ui_display_icon_and_content(text, icon, &block)

        if url
          options[:aria] = { current: ("page" if active) }.compact.merge(options[:aria] || {})
          link_to(url, **options) { content }
        else
          options[:aria] = { pressed: active }.merge(options[:aria] || {})
          tag.button(type: options.delete(:type) || "button", **options) { content }
        end
      end

      def ui_tabs_content(**options, &block)
        tag.div(**options, class: class_names("ui-tabs__content", options[:class]), &block)
      end

      # An alert: ui_alert("Unable to save", "Check the form.", variant: :destructive, icon: "alert").
      # A block is the description (and wins over the second argument); action: is markup for
      # the top-right corner (a small button). variant: :default, :destructive, :warning, :success.
      def ui_alert(title = nil, description = nil, variant: :default, icon: nil, action: nil, **options, &block)
        options[:class] = class_names("ui-alert", "ui-alert--#{variant}" => variant.to_sym != :default, options[:class] => options[:class].present?)
        options[:role] ||= "alert"
        description = capture(&block) if block

        tag.div(**options) do
          safe_join([
            (icon_tag(icon, class: "ui-alert__icon") if icon && respond_to?(:icon_tag)),
            (tag.div(title, class: "ui-alert__title") if title),
            (tag.div(description, class: "ui-alert__description") if description.present?),
            (tag.div(action, class: "ui-alert__action") if action)
          ].compact)
        end
      end

      # Avatars overlapping, with an optional "+3" at the end:
      #   <%= ui_avatar_group(more: 3) do %><%= ui_avatar "Ted Martin" %>…<% end %>
      def ui_avatar_group(more: nil, **options, &block)
        tag.div(**options, class: class_names("ui-avatar-group", options[:class])) do
          safe_join([ capture(&block), (tag.span("+#{more}", class: "ui-avatar-group__count") if more.to_i.positive?) ].compact)
        end
      end

      # A separator: ui_separator, ui_separator(orientation: :vertical), ui_separator(label: "or").
      def ui_separator(orientation: :horizontal, label: nil, **options)
        vertical = orientation.to_sym == :vertical
        if label
          tag.div(label, **options, role: "separator", class: class_names("ui-separator ui-separator--label", options[:class]))
        elsif vertical
          tag.span(**options, role: "separator", aria: { orientation: "vertical" }, class: class_names("ui-separator ui-separator--vertical", options[:class]))
        else
          tag.hr(**options, class: class_names("ui-separator", options[:class]))
        end
      end

      def ui_skeleton(**options)
        tag.div(**options, class: class_names("ui-skeleton", options[:class]))
      end

      # A progress bar: ui_progress(60), or with its label and value above it:
      # ui_progress(60, label: "Upload", show_value: true).
      def ui_progress(value, max: 100, label: nil, show_value: false, **options)
        bar = tag.progress("#{(value.to_f / max * 100).round}%", value: value, max: max, **options,
          class: class_names("ui-progress", options[:class]), aria: { label: label }.compact)
        return bar unless label || show_value

        tag.div(class: "ui-progress-root") do
          safe_join([
            (tag.span(label, class: "ui-progress__label") if label),
            (tag.span("#{(value.to_f / max * 100).round}%", class: "ui-progress__value") if show_value),
            bar
          ].compact)
        end
      end

      # A spinner: ui_spinner, or ui_spinner(label: nil) beside words that already say it.
      def ui_spinner(label: "Loading", **options)
        a11y = label ? { role: "status", aria: { label: label } } : { aria: { hidden: true } }
        tag.span(**a11y, **options, class: class_names("ui-spinner", options[:class]))
      end

      # A breadcrumb from [label, url] pairs; the last (or any with no url) is the current page,
      # and :ellipsis stands for collapsed levels:
      #   ui_breadcrumb([ [ "Home", root_path ], :ellipsis, [ "Clients", clients_path ], [ @client.name ] ])
      def ui_breadcrumb(items, label: "Breadcrumb", **options)
        crumbs = items.map.with_index do |item, index|
          content =
            if item == :ellipsis
              tag.span("", class: "ui-breadcrumb__ellipsis", role: "presentation", aria: { hidden: true })
            else
              text, url = Array(item)
              if url && index < items.size - 1
                link_to(text, url, class: "ui-breadcrumb__link")
              else
                tag.span(text, class: "ui-breadcrumb__page", role: "link", aria: { disabled: true, current: "page" })
              end
            end
          tag.li(content, class: "ui-breadcrumb__item")
        end
        separator = tag.li("", class: "ui-breadcrumb__separator", role: "presentation", aria: { hidden: true })

        tag.nav(**options, aria: { label: label }, class: class_names("ui-breadcrumb", options[:class])) do
          tag.ol(safe_join(crumbs, separator), class: "ui-breadcrumb__list")
        end
      end

      # An empty state:
      #   <%= ui_empty "No projects yet", description: "Create one to get started.", icon: "folder" do %>
      #     <%= ui_button "Create project" %>
      #   <% end %>
      # icon: draws the muted icon box (shadcn's media variant "icon"); media: is any other
      # markup for it (an avatar group). outline: true adds the dashed edge. The block is the
      # content under the header (actions).
      def ui_empty(title, description: nil, icon: nil, media: nil, outline: false, **options, &block)
        options[:class] = class_names("ui-empty", "ui-empty--outline" => outline, options[:class] => options[:class].present?)
        media_tag =
          if icon && respond_to?(:icon_tag)
            tag.div(icon_tag(icon), class: "ui-empty__media ui-empty__media--icon")
          elsif media
            tag.div(media, class: "ui-empty__media")
          end

        tag.div(**options) do
          header = tag.div(class: "ui-empty__header") do
            safe_join([ media_tag, tag.div(title, class: "ui-empty__title"), (tag.p(description, class: "ui-empty__description") if description) ].compact)
          end
          safe_join([ header, (tag.div(capture(&block), class: "ui-empty__content") if block) ].compact)
        end
      end

      # Items in a list: ui_item_group { … } (a div role="list" with shadcn's gaps), or
      # divided: true for ours, edge to edge with a rule between.
      def ui_item_group(divided: false, **options, &block)
        options[:class] = class_names("ui-item-group", "ui-item-group--divided" => divided, options[:class] => options[:class].present?)
        options[:role] ||= "list"
        tag.div(**options, &block)
      end

      def ui_item_separator
        tag.hr(class: "ui-separator ui-item__separator")
      end

      # An item: media, a title and description, and actions (the block).
      #
      #   <%= ui_item "Ted Martin", description: "Owner", media: ui_avatar("Ted Martin"), variant: :outline do %>
      #     <%= ui_button "Edit", variant: :outline, size: :sm %>
      #   <% end %>
      #
      # url: makes the whole item a link (then no block: a link can't hold buttons).
      # icon: (an icon name) or media: (markup), with media_variant: :icon or :image.
      # variant: :default, :outline, :muted; size: :default, :sm, :xs. as: the element (:div).
      def ui_item(title = nil, description: nil, url: nil, icon: nil, media: nil, media_variant: nil, variant: :default, size: :default,
                  as: :div, **options, &block)
        variant = variant.to_sym
        size = size.to_sym
        raise ArgumentError, "unknown item variant #{variant}" unless ITEM_VARIANTS.include?(variant)
        raise ArgumentError, "unknown item size #{size}" unless ITEM_SIZES.include?(size)

        options[:class] = class_names("ui-item", "ui-item--#{variant}" => variant != :default, "ui-item--#{size}" => size != :default,
          options[:class] => options[:class].present?)
        options[:role] ||= "listitem" unless url

        media = icon_tag(icon) if icon && respond_to?(:icon_tag)
        media_variant ||= :icon if icon
        parts = [
          (tag.div(media, class: class_names("ui-item__media", "ui-item__media--#{media_variant}" => media_variant)) if media),
          tag.div(class: "ui-item__content") do
            safe_join([ (tag.div(title, class: "ui-item__title") if title), (tag.p(description, class: "ui-item__description") if description) ].compact)
          end,
          (tag.div(capture(&block), class: "ui-item__actions") if block)
        ].compact

        url ? link_to(url, **options) { safe_join(parts) } : content_tag(as, safe_join(parts), **options)
      end

      # Pagination: page links around the current one, the first and last, and ellipses between.
      #   <%= ui_pagination(page: @page.number, pages: @page.recordset.page_count) { |n| clients_path(page: n) } %>
      # window: pages either side of the current one.
      def ui_pagination(page:, pages:, window: 1, previous_text: "Previous", next_text: "Next", label: "pagination", **options, &url_for_page)
        page = page.to_i
        pages = pages.to_i
        shown = ([ 1, pages ] + ((page - window)..(page + window)).to_a).select { it.between?(1, pages) }.uniq.sort

        entries = []
        if page > 1
          entries << link_to(url_for_page.call(page - 1), class: ui_button_classes(:ghost, class: "ui-pagination__link ui-pagination__previous"),
                             aria: { label: "Go to previous page" }, rel: "prev") do
            safe_join([ tag.span(class: "ui-pagination__chevron", data: { icon: "inline-start" }), tag.span(previous_text, class: "ui-pagination__text") ])
          end
        end
        shown.each_with_index do |number, index|
          entries << tag.span("", class: "ui-pagination__ellipsis", aria: { hidden: true }) if index.positive? && number > shown[index - 1] + 1
          current = number == page
          entries << link_to(number, url_for_page.call(number), class: ui_button_classes(current ? :outline : :ghost, size: :icon, class: "ui-pagination__link"),
                             aria: { current: ("page" if current) }.compact)
        end
        if page < pages
          entries << link_to(url_for_page.call(page + 1), class: ui_button_classes(:ghost, class: "ui-pagination__link ui-pagination__next"),
                             aria: { label: "Go to next page" }, rel: "next") do
            safe_join([ tag.span(next_text, class: "ui-pagination__text"), tag.span(class: "ui-pagination__chevron", data: { icon: "inline-end" }) ])
          end
        end

        tag.nav(**options, aria: { label: label }, class: class_names("ui-pagination", options[:class])) do
          tag.ul(safe_join(entries.map { tag.li(it) }), class: "ui-pagination__content")
        end
      end

      # An accordion of <details>: items sharing a name open one at a time.
      #   <%= ui_accordion do %>
      #     <%= ui_accordion_item "Is it accessible?", name: "faq", open: true do %>…<% end %>
      #   <% end %>
      def ui_accordion(**options, &block)
        tag.div(**options, class: class_names("ui-accordion", options[:class]), &block)
      end

      def ui_accordion_item(title, open: false, name: nil, **options, &block)
        tag.details(**options, open: open, name: name, class: class_names("ui-accordion__item", options[:class])) do
          safe_join([ tag.summary(title, class: "ui-accordion__trigger"), tag.div(capture(&block), class: "ui-accordion__content") ])
        end
      end

      # A collapsible: a summary as its trigger (any classes, a ui-button by default) and content.
      def ui_collapsible(trigger, open: false, trigger_class: nil, **options, &block)
        tag.details(**options, open: open, class: class_names("ui-collapsible", options[:class])) do
          safe_join([
            tag.summary(trigger, class: class_names("ui-collapsible__trigger", trigger_class || ui_button_classes(:ghost, size: :sm))),
            tag.div(capture(&block), class: "ui-collapsible__content")
          ])
        end
      end

      # A box held to a ratio: ui_aspect_ratio(:square) { image_tag(…) }. A ratio outside the
      # named ones (:square, :video, :"4:3", :"3:2", :"21:9", :portrait) is a number, set
      # through the --ratio property.
      def ui_aspect_ratio(ratio = :video, **options, &block)
        if (name = ASPECT_RATIOS[ratio.to_s.to_sym])
          options[:class] = class_names("ui-aspect-ratio", "ui-aspect-ratio--#{name}", options[:class])
        else
          options[:class] = class_names("ui-aspect-ratio", options[:class])
          options[:style] = [ "--ratio: #{ratio.to_f}", options[:style] ].compact.join("; ")
        end
        tag.div(**options, &block)
      end

      # A scroll area: a box that scrolls with the thin shadcn scrollbars.
      def ui_scroll_area(**options, &block)
        tag.div(tabindex: 0, **options, class: class_names("ui-scroll-area", options[:class]), &block)
      end

      private
        def ui_display_icon_and_content(text, icon, &block)
          parts = []
          parts << icon_tag(icon) if icon && respond_to?(:icon_tag)
          parts << (block ? capture(&block) : text)
          safe_join(parts.compact)
        end
    end
  end
end
