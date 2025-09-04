# frozen_string_literal: true

# Assuming ApplicationComponent is your base class for ViewComponents
# and Heroicon::Engine.helpers is correctly included/available.
module UI
  class AlertComponent < ApplicationComponent # Changed from ViewComponent::Base
    include Heroicon::Engine.helpers

    KIND_MAPPING = {
      info: "alert-info",
      notice: "alert-info", # notice maps to info
      alert: "alert-warning", # alert maps to warning
      success: "alert-success",
      warning: "alert-warning",
      error: "alert-error"
    }.freeze

    ICON_MAPPING = {
      info: "information-circle",
      notice: "information-circle",
      alert: "exclamation-triangle",
      success: "check-circle",
      warning: "exclamation-triangle",
      error: "x-circle"
    }.freeze

    param :text, optional: true # The main message of the alert
    option :kind, type: Dry::Types["coercible.symbol"].enum(*KIND_MAPPING.keys), default: proc { :info } # Added default

    # All other html attributes are passed via `attributes` helper from ApplicationComponent/ViewComponentContrib
    # e.g. class, id, data attributes

    def call
      # The `attributes.except(:class)` is important if you want to merge classes
      # rather than overriding them. The `classes` method handles merging.
      content_tag(:div, class: classes, **attributes.except(:class, :text, :kind)) do
        concat heroicon(icon_name, variant: :outline, options: { class: "h-6 w-6 shrink-0" }) # DaisyUI examples often use h-6 w-6 and shrink-0
        concat content_tag(:span, effective_content) # Wrap content in a span for better alignment with icon
      end
    end

    private

    def icon_name # Renamed from `icon` to avoid conflict with heroicon helper itself
      ICON_MAPPING[kind] || "information-circle"
    end

    def classes
      # `component_classes` generates "alert alert-info" etc.
      # `attributes[:class]` gets any class passed when rendering the component.
      [ component_classes, attributes[:class] ].compact.join(" ")
    end

    def component_classes
      class_names("alert", KIND_MAPPING[kind])
    end

    # This is how ViewComponent's `content` method works by default if a block is given.
    # If `text` param is given, it takes precedence.
    def effective_content
      text.presence || (content if content.present?) # Changed from content_provided?
    end
  end
end
