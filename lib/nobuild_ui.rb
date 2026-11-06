require "nobuild_ui/version"
require "nobuild_ui/engine"

# shadcn/ui for Rails with no build step: plain CSS components (ui-button, ui-card, ui-menu…),
# a few Stimulus controllers, and view helpers that spell them.
module NobuildUi
  # The stylesheets, in the order they load: tokens first (it declares the layer order),
  # then the components. font bundles Inter and is optional.
  STYLESHEETS = %w[
    tokens
    button button-group toggle badge card
    display accordion pagination spinner scroll-area aspect-ratio
    forms overlays select combobox slider command input-otp keyboard
  ].freeze
end
