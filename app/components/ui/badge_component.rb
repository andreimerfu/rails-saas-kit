# frozen_string_literal: true

module UI
  class BadgeComponent < ViewComponent::Base
    # Defines the styles for the badge, mapping to DaisyUI classes.
    STYLES = {
      neutral: "badge-neutral", # Default, often just 'badge'
      primary: "badge-primary",
      secondary: "badge-secondary",
      accent: "badge-accent",
      info: "badge-info",
      success: "badge-success",
      warning: "badge-warning",
      error: "badge-error",
      ghost: "badge-ghost" # Ghost is also a style
    }.freeze

    # Defines the sizes for the badge.
    SIZES = {
      lg: "badge-lg",
      md: "badge-md", # Default DaisyUI badge size
      sm: "badge-sm",
      xs: "badge-xs"
    }.freeze

    attr_reader :label, :style, :size, :outline, :html_options

    # Initializes the BadgeComponent.
    #
    # @param label [String] The text to display on the badge. Required.
    # @param style [Symbol] The style of the badge (e.g., :primary, :secondary). Defaults to :neutral.
    # @param size [Symbol] The size of the badge (e.g., :lg, :sm). Defaults to :md.
    # @param outline [Boolean] Whether the badge should be an outline badge. Defaults to false.
    # @param html_options [Hash] Additional HTML attributes to be added to the badge div.
    #
    # Example Usage:
    # <%= render UI::BadgeComponent.new(label: "New", style: :primary) %>
    # <%= render UI::BadgeComponent.new(label: "Warning", style: :warning, outline: true, size: :lg) %>
    #
    def initialize(label:, style: :neutral, size: :md, outline: false, **html_options)
      @label = label
      @style = style
      @size = size
      @outline = outline
      @html_options = html_options
    end

    def call
      options = html_options.deep_merge(class: badge_classes)
      content_tag :div, label, options
    end

    private

    def badge_classes
      classes = [ "badge" ]
      # Only add style class if it's not the default :neutral,
      # unless :neutral itself has a specific class in STYLES (which it does here for clarity)
      classes << STYLES[style.to_sym] if STYLES[style.to_sym].present? && style.to_sym != :neutral
      classes << STYLES[:neutral] if style.to_sym == :neutral && STYLES[:neutral].present? && STYLES[:neutral] != "badge" # Avoid double "badge"

      classes << SIZES[size.to_sym] if SIZES[size.to_sym].present? && size.to_sym != :md # md is default, no class needed
      classes << "badge-outline" if outline
      classes.compact.uniq.join(" ") # Use uniq to avoid duplicate "badge" if STYLES[:neutral] is just "badge"
    end
  end
end
