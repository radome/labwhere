require File.expand_path('../boot', __FILE__)

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Labwhere
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'
    #convert dates and times to correct time zone
    config.time_zone = 'London'
    config.active_record.default_timezone = :local
    config.active_record.time_zone_aware_attributes = false

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # redirect errors to errors controller
    config.exceptions_app = self.routes

    # Do not swallow errors in after_commit/after_rollback callbacks.
    config.active_record.raise_in_transactional_callbacks = true

    config.autoload_paths += %W(#{config.root}/lib/utils #{config.root}/lib/validators)

    config.autoload_paths += %W(#{config.root}/app/models/users #{config.root}/app/models/locations #{config.root}/app/models/restrictions)

    config.autoload_paths += %W(#{config.root}/lib/label_printing #{config.root}/app/models/labware_collection)

    config.mailer = YAML.load_file("#{Rails.root}/config/mailer.yml")[Rails.env]

    config.label_templates = Rails.application.config_for(:label_templates)

    # replace fixtures with factory girl
    config.generators do |g|
        g.test_framework :rspec,
            fixtures: true,
            view_specs: false,
            helper_specs: false,
            routing_specs: false,
            controller_specs: false,
            request_specs: true
        g.fixture_replacement :factory_girl, dir: "spec/factories"

    end
  end
end
