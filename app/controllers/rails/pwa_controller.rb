# frozen_string_literal: true

module Rails
  class PwaController < ApplicationController
    # Skip authentication for PWA files
    skip_before_action :authenticate_user!, raise: false

    # Skip CSRF protection for these endpoints
    skip_before_action :verify_authenticity_token, if: -> { request.format.json? }

    # Render the manifest.json file
    def manifest
      render template: "pwa/manifest.json", formats: [ :json ], layout: false
    end

    # Render the service-worker.js file
    def service_worker
      render template: "pwa/service-worker", formats: [ :js ], layout: false
    end
  end
end
