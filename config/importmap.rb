# The kit's Stimulus controllers, registered as ui--popover and ui--proxy by
# eagerLoadControllersFrom("controllers", application).
pin_all_from NobuildUi::Engine.root.join("app/javascript/nobuild_ui/controllers"), under: "controllers/ui", to: "nobuild_ui/controllers"
