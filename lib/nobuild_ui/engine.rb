require "nobuild_ui/helper"

module NobuildUi
  class Engine < ::Rails::Engine
    # Propshaft serves app/assets/* on its own; the controllers are served from app/javascript.
    initializer "nobuild_ui.assets" do |app|
      app.config.assets.paths << root.join("app/javascript") if app.config.respond_to?(:assets)
    end

    initializer "nobuild_ui.importmap", before: "importmap" do |app|
      if app.config.respond_to?(:importmap)
        app.config.importmap.paths << root.join("config/importmap.rb")
        app.config.importmap.cache_sweepers << root.join("app/javascript")
      end
    end

    initializer "nobuild_ui.helper" do
      ActiveSupport.on_load(:action_view) { include NobuildUi::Helper }
    end
  end
end
