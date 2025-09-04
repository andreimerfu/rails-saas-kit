# frozen_string_literal: true

module UI
  class ButtonComponent < ViewComponent::Base
    # Defines the styles for the button, mapping to DaisyUI classes.
    STYLES = {
      primary: "btn-primary",
      secondary: "btn-secondary",
      accent: "btn-accent",
      info: "btn-info",
      success: "btn-success",
      warning: "btn-warning",
      error: "btn-error",
      ghost: "btn-ghost",
      link: "btn-link",
      neutral: "btn-neutral", # Added neutral as it's common
      glass: "glass" # Added glass effect
    }.freeze

    # Defines the sizes for the button.
    SIZES = {
      lg: "btn-lg",
      md: "btn-md", # Default DaisyUI button size
      sm: "btn-sm",
      xs: "btn-xs"
    }.freeze

    # Defines shapes for the button
    SHAPES = {
      circle: "btn-circle",
      square: "btn-square"
    }.freeze

    attr_reader :label, :path, :type, :style, :size, :outline, :disabled, :wide, :block, :shape, :html_options, :tag_name

    # Initializes the ButtonComponent.
    #
    # @param label [String] The text to display on the button. Required.
    # @param path [String, nil] The URL the button links to. If nil, a <button> tag is rendered.
    # @param type [String] The type attribute for the <button> tag (e.g., 'button', 'submit'). Defaults to 'button'.
    # @param style [Symbol] The style of the button (e.g., :primary, :secondary). Defaults to :neutral.
    # @param size [Symbol] The size of the button (e.g., :lg, :sm). Defaults to :md.
    # @param outline [Boolean] Whether the button should be an outline button. Defaults to false.
    # @param disabled [Boolean] Whether the button should be disabled. Defaults to false.
    # @param wide [Boolean] Whether the button should be wider. Defaults to false.
    # @param block [Boolean] Whether the button should be a block button (full width). Defaults to false.
    # @param shape [Symbol, nil] The shape of the button (e.g., :circle, :square).
    # @param html_options [Hash] Additional HTML attributes to be added to the button tag.
    def initialize(label:, path: nil, type: "button", style: :neutral, size: :md, outline: false, disabled: false, wide: false, block: false, shape: nil, **html_options) # rubocop:disable Metrics/ParameterLists
      @label = label
      @path = path
      @type = type
      @style = style
      @size = size
      @outline = outline
      @disabled = disabled
      @wide = wide
      @block = block
      @shape = shape
      @html_options = html_options

      @tag_name = @path.present? ? :a : :button
    end

    def call
      options = html_options.deep_merge(class: button_classes)
      options[:type] = type if tag_name == :button && type.present?
      options[:disabled] = true if disabled # HTML standard for disabled
      options[:href] = path if tag_name == :a && path.present?

      content_tag(tag_name, options) do
        label_content
      end
    end

    private

    def label_content
      # In a real scenario, you might want to allow icons or more complex content here.
      # For now, just the label.
      label.html_safe # rubocop:disable Rails/OutputSafety
    end

    def button_classes
      classes = [ "btn" ]
      classes << STYLES[style.to_sym] if STYLES[style.to_sym]
      classes << SIZES[size.to_sym] if SIZES[size.to_sym] && size.to_sym != :md # md is default, no class needed
      classes << SHAPES[shape.to_sym] if shape.present? && SHAPES[shape.to_sym]
      classes << "btn-outline" if outline
      classes << "btn-wide" if wide
      classes << "btn-block" if block
      # DaisyUI uses 'btn-disabled' class for styling, but the attribute is also needed
      classes << "btn-disabled" if disabled
      classes.compact.join(" ")
    end
  end
end
