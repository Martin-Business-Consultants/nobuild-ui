# nobuild_ui

shadcn/ui for Rails, with no build step: plain CSS served by Propshaft, a few Stimulus
controllers pinned through importmap, and view helpers that spell the components. No Tailwind,
no Node, no React. Used by Runwell and Lumin Ads.

## Install

```ruby
# Gemfile
gem "nobuild_ui", github: "Martin-Business-Consultants/nobuild-ui", branch: "main"
```

In the layout's `<head>`, before the app's own stylesheets (the kit declares the layer order
`reset, base, components, ui`; an app's extra layers fall in after):

```erb
<%= nobuild_ui_stylesheet_tags "data-turbo-track": "reload" %>
<%= stylesheet_link_tag :app, "data-turbo-track": "reload" %>
```

The controllers (`ui--popover`, `ui--proxy`) load with the app's own through
`eagerLoadControllersFrom("controllers", application)`; nothing to pin.

To work on the kit from an app, point Bundler at a checkout:

```sh
bundle config set local.nobuild_ui ~/Projects/mbc/nobuild-ui
```

## Components

Every component on https://ui.shadcn.com/docs/components, drawn 1:1 as the docs draw them
(shadcn's base primitives in the base-nova style), on native elements: `<dialog>` for dialogs,
sheets and drawers, the `popover` attribute for menus and floating content, `<details>` for
accordions, real inputs for checkboxes, radios, switches, toggles and sliders. Classes are
shadcn's names in the `ui` layer: `ui-<component>`, `ui-<component>__<part>`,
`ui-<component>--<variant>`. Each file's header comment shows its markup.

| File | Components |
| --- | --- |
| `tokens.css` | shadcn's neutral theme, light and dark, radius steps, in the `base` layer |
| `font.css` | Inter, bundled (optional: `nobuild_ui_stylesheet_tags font: false`) |
| `button.css` `button-group.css` | Button (`--secondary --outline --ghost --link --destructive`; `--xs --sm --lg --icon-xs --icon-sm --icon --icon-lg`), Button Group |
| `toggle.css` | Toggle, Toggle Group |
| `badge.css` | Badge (`--secondary --destructive --outline --ghost --link`, plus status `--positive --warning --info --negative --neutral --count`) |
| `card.css` | Card (`__header __title __description __action __content __footer __image`, `--sm`) |
| `display.css` | Table, Tabs, Alert, Avatar, Separator, Skeleton, Kbd, Progress, Breadcrumb, Empty, Item |
| `accordion.css` `pagination.css` `spinner.css` `scroll-area.css` `aspect-ratio.css` | Accordion and Collapsible, Pagination, Spinner, Scroll Area, Aspect Ratio |
| `forms.css` `select.css` `combobox.css` `slider.css` `input-otp.css` | Input, Textarea, Label, Field, Input Group, Native Select, Select, Checkbox, Radio Group, Switch, Combobox, Slider, Input OTP |
| `overlays.css` | Dialog, Alert Dialog, Sheet, Drawer, Dropdown Menu, Context Menu, Menubar, Navigation Menu, Popover, Hover Card, Tooltip, Sonner (toast) |
| `command.css` | Command, Command Dialog |
| `keyboard.css` | `[data-keyboard-current]`, the ring keyboard navigation draws |

Not ported: Calendar, Date Picker, Carousel, Chart, Resizable, Sidebar (each app draws its own
shell from the tokens), Data Table (an app pattern over Table).

Stimulus controllers, registered by the app's `eagerLoadControllersFrom("controllers", …)`:
`ui--popover` (places any popover; menu keys, sub-menus, hover cards, context menus),
`ui--menubar`, `ui--select`, `ui--combobox`, `ui--slider`, `ui--proxy`.

## Helpers

`NobuildUi::Helper` is in every view (an app overrides any helper by defining it):

- Actions: `ui_button`, `ui_link_button`, `ui_button_classes`, `ui_button_group`,
  `ui_button_group_text`, `ui_button_group_separator`, `ui_toggle`, `ui_toggle_classes`,
  `ui_toggle_group`, `ui_badge`
- Display: `ui_kbd`, `ui_avatar`, `ui_avatar_group`, `ui_tabs`, `ui_tabs_list`, `ui_tabs_trigger`,
  `ui_tabs_content`, `ui_alert`, `ui_separator`, `ui_skeleton`, `ui_progress`, `ui_spinner`,
  `ui_breadcrumb`, `ui_empty`, `ui_item`, `ui_item_group`, `ui_item_separator`, `ui_pagination`,
  `ui_accordion`, `ui_accordion_item`, `ui_collapsible`, `ui_aspect_ratio`, `ui_scroll_area`
- Forms: `ui_native_select`, `ui_select_menu`, `ui_combobox`, `ui_slider_tag`, `ui_input_otp`,
  `ui_input_group`, `ui_input_group_addon`, `ui_field_separator`
- Overlays: `ui_dialog`, `ui_dialog_trigger`, `ui_dialog_close`, `ui_dialog_footer`,
  `ui_alert_dialog`, `ui_sheet`, `ui_drawer`, `ui_popover`, `ui_hover_card`, `ui_tooltip`,
  `ui_dropdown`, `ui_menu_item`, `ui_menu_label`, `ui_menu_separator`, `ui_menu_group`,
  `ui_menu_sub`, `ui_menu_checkbox_item`, `ui_menu_radio_item`, `ui_context_menu`, `ui_menubar`,
  `ui_menubar_menu`, `ui_navigation_menu`, `ui_navigation_menu_item`,
  `ui_navigation_menu_link`, `ui_toast`

Icons come from the app's `icon_tag(name)` when it has one.

```erb
<%= ui_dropdown "Active (15)", id: "client-status", label: "Show…" do %>
  <%= ui_menu_item "Active (15)", clients_path(status: "active"), checked: true %>
  <%= ui_menu_item "Former (11)", clients_path(status: "former"), checked: false %>
<% end %>
```

## Keeping it 1:1

The reference is shadcn's own source: `apps/v4/registry/styles/style-nova.css` (each
component's classes) and `apps/v4/registry/bases/base/ui/*.tsx` (its parts) in
github.com/shadcn-ui/ui. When shadcn changes a component, diff those and port the change.

## Theming

Re-point any token from the app, layered or not, and every component follows:

```css
:root { --primary: oklch(0.55 0.2 260); --radius: 0.5rem; }
```

`--brand-primary` / `--brand-primary-foreground`, `--radius-scale` and `--radius-control` are
hooks for an app's settings. CSS rules: tokens only (no raw colours), rem/em sizes, corners
through `--radius-*`, descendant selectors (ReActionView wraps output in `display: contents`
spans in development).
