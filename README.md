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

Classes in shadcn's names and variants, in the `ui` layer:

| File | Components |
| --- | --- |
| `tokens.css` | shadcn's neutral theme, light and dark, in the `base` layer |
| `font.css` | Inter, bundled (optional: `nobuild_ui_stylesheet_tags font: false`) |
| `button.css` | `ui-button` (`--secondary --outline --ghost --link --destructive`; `--sm --lg --icon --icon-sm --icon-lg`) |
| `badge.css` | `ui-badge` (`--secondary --destructive --outline`; status: `--positive --warning --info --negative --neutral`) |
| `card.css` | `ui-card` (`__header __title __description __action __content __footer`) |
| `forms.css` | `ui-input ui-select ui-textarea ui-label ui-field ui-checkbox ui-radio ui-switch ui-input-group` |
| `display.css` | `ui-table ui-tabs ui-alert ui-avatar ui-separator ui-skeleton ui-kbd ui-progress ui-breadcrumb ui-empty ui-item` |
| `overlays.css` | `ui-dialog ui-sheet ui-menu ui-popover ui-tooltip ui-toast`, `ui-dropdown` |
| `command.css` | `ui-command` |
| `input-otp.css` | `ui-input-otp` |
| `keyboard.css` | `[data-keyboard-current]`, the ring keyboard navigation draws |

Each file's header comment shows its markup.

## Helpers

`NobuildUi::Helper` is included in every view: `ui_button`, `ui_link_button`,
`ui_button_classes`, `ui_badge`, `ui_kbd`, `ui_avatar`, `ui_dropdown`, `ui_menu_item`,
`ui_menu_label`, `ui_menu_separator`. Menus follow the shadcn docs' own style (base-nova). Icons come from the app's `icon_tag(name)` when it has
one. An app overrides any helper by defining it in its own.

```erb
<%= ui_dropdown "Active (15)", id: "client-status", label: "Show…" do %>
  <%= ui_menu_item "Active (15)", clients_path(status: "active"), checked: true %>
  <%= ui_menu_item "Former (11)", clients_path(status: "former"), checked: false %>
<% end %>
```

## Theming

Re-point any token from the app, layered or not, and every component follows:

```css
:root { --primary: oklch(0.55 0.2 260); --radius: 0.5rem; }
```

`--brand-primary` / `--brand-primary-foreground`, `--radius-scale` and `--radius-control` are
hooks for an app's settings. CSS rules: tokens only (no raw colours), rem/em sizes, corners
through `--radius-*`, descendant selectors (ReActionView wraps output in `display: contents`
spans in development).
