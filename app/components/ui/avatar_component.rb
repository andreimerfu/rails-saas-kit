# frozen_string_literal: true

module UI
  class AvatarComponent < ViewComponent::Base
    attr_reader :src, :alt, :shape, :size, :online, :offline, :placeholder_text, :custom_class, :html_options

    # Defines the shapes for the avatar.
    SHAPES = {
      circle: "rounded-full", # DaisyUI uses utility classes for shapes
      rounded: "rounded-lg"   # Example for a less rounded avatar
    }.freeze

    # Defines common sizes, mapping to width/height utilities.
    # These are example sizes; users can pass custom width/height via html_options.
    # DaisyUI avatar itself doesn't have strict size classes like btn-lg, but uses w-* h-*
    SIZES = {
      xs: "w-8 h-8",
      sm: "w-12 h-12",
      md: "w-16 h-16", # A common medium size
      lg: "w-24 h-24",
      xl: "w-32 h-32"
    }.freeze

    # Initializes the AvatarComponent.
    #
    # @param src [String, nil] The URL of the avatar image.
    # @param alt [String] The alt text for the avatar image. Defaults to "Avatar".
    # @param shape [Symbol] The shape of the avatar (:circle, :rounded). Defaults to :circle.
    # @param size [Symbol, String, nil] Predefined size symbol (e.g., :sm, :md) or a custom Tailwind class string for size (e.g., "w-10 h-10").
    #                                   If nil, no specific size class is applied (relies on CSS or parent).
    # @param online [Boolean] Displays an online indicator. Defaults to false.
    # @param offline [Boolean] Displays an offline indicator. Defaults to false. (online takes precedence)
    # @param placeholder_text [String, nil] Text to display if `src` is nil (e.g., initials). Max 2-3 chars recommended.
    # @param custom_class [String, nil] Additional custom classes for the main avatar div.
    # @param html_options [Hash] Additional HTML attributes for the main avatar div.
    #
    # Example Usage:
    # <%= render UI::AvatarComponent.new(src: "path/to/image.jpg", alt: "User Name", online: true) %>
    # <%= render UI::AvatarComponent.new(placeholder_text: "JD", size: :lg, shape: :rounded) %>
    # <%= render UI::AvatarComponent.new(src: "path/to/image.jpg", size: "w-20 h-20") %>
    #
    def initialize(src: nil, alt: "Avatar", shape: :circle, size: :md, online: false, offline: false, placeholder_text: nil, custom_class: nil, **html_options) # rubocop:disable Metrics/ParameterLists
      @src = src
      @alt = alt
      @shape = shape
      @size = size
      @online = online
      @offline = offline
      @placeholder_text = placeholder_text
      @custom_class = custom_class
      @html_options = html_options

      raise ArgumentError, "Cannot be both online and offline" if online && offline
      raise ArgumentError, "Placeholder text is recommended if src is not provided" if src.blank? && placeholder_text.blank?
    end

    def call
      options = html_options.deep_merge(class: avatar_wrapper_classes)

      content_tag :div, **options do
        if src.present?
          content_tag :div, class: image_wrapper_classes do
            image_tag src, alt: alt
          end
        elsif placeholder_text.present?
          content_tag :div, class: "avatar placeholder #{status_class}".strip do
            content_tag :div, class: placeholder_inner_classes do
              content_tag :span, placeholder_text.first(3) # DaisyUI placeholder usually shows 2-3 chars
            end
          end
        end
      end
    end

    private

    def avatar_wrapper_classes
      classes = [ "avatar" ]
      classes << status_class if src.present? # Status indicator only if there's an image avatar
      classes << custom_class if custom_class.present?
      classes.compact.join(" ")
    end

    def image_wrapper_classes
      img_classes = []
      img_classes << size_class
      img_classes << SHAPES[shape.to_sym] if SHAPES[shape.to_sym]
      img_classes.compact.join(" ")
    end

    def placeholder_inner_classes
      # Placeholder text is typically inside a neutral bg with text color
      # and also needs shape and size.
      ph_classes = [ "bg-neutral-focus", "text-neutral-content" ]
      ph_classes << size_class
      ph_classes << SHAPES[shape.to_sym] if SHAPES[shape.to_sym]
      ph_classes.compact.join(" ")
    end

    def size_class
      return SIZES[size.to_sym] if size.is_a?(Symbol) && SIZES[size.to_sym]
      return size if size.is_a?(String) # Allows passing custom Tailwind size classes
      SIZES[:md] # Default if nil or invalid symbol
    end

    def status_class
      return "online" if online
      return "offline" if offline
      ""
    end
  end
end
