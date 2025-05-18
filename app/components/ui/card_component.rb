# frozen_string_literal: true

module UI
  class CardComponent < ViewComponent::Base
    attr_reader :title, :image_url, :image_alt, :bordered, :image_full, :compact_card, :normal_size, :html_options

    # Initializes the CardComponent.
    #
    # @param title [String, nil] The title of the card. Displayed in a <h2 class="card-title">.
    # @param image_url [String, nil] URL for the image at the top of the card.
    # @param image_alt [String] Alt text for the image. Defaults to "Card image".
    # @param bordered [Boolean] Adds a border to the card. Defaults to true.
    # @param image_full [Boolean] Image will be full width of the card, without side padding. Defaults to false.
    # @param compact_card [Boolean] Makes the card compact. Defaults to false.
    # @param normal_size [Boolean] Makes the card responsive (default), use false for fixed size. Defaults to true.
    # @param html_options [Hash] Additional HTML attributes for the main card div.
    #
    # Slots:
    #   with_body: The main content of the card. Required.
    #   with_actions: Content for the card actions section (e.g., buttons). Optional.
    #   with_figure: For custom content in the <figure> tag if image_url is not used. Optional.
    #
    # Example Usage:
    # <%= render UI::CardComponent.new(title: "Shoes!", image_url: "/images/stock/photo-1606107557195-0e29a4b5b4aa.jpg", bordered: true) do |card| %>
    #   <% card.with_body do %>
    #     <p>If a dog chews shoes whose shoes does he choose?</p>
    #   <% end %>
    #   <% card.with_actions do %>
    #     <%= render UI::ButtonComponent.new(label: "Buy Now", style: :primary) %>
    #   <% end %>
    # <% end %>
    def initialize(title: nil, image_url: nil, image_alt: "Card image", bordered: true, image_full: false, compact_card: false, normal_size: true, **html_options) # rubocop:disable Metrics/ParameterLists
      @title = title
      @image_url = image_url
      @image_alt = image_alt
      @bordered = bordered
      @image_full = image_full
      @compact_card = compact_card
      @normal_size = normal_size # DaisyUI default is responsive, card-normal makes it fixed width on larger screens
      @html_options = html_options
    end

    renders_one :body, ->(&block) do
      # The body slot itself doesn't need to render anything complex here,
      # it just captures the block. The `call` method will render it.
      # We ensure it's captured by calling the block.
      # If you need to wrap the body content or add classes directly here, you could.
      # For now, the `card-body` div is handled in the main `call` method.
      view_context.capture(&block) if block
    end
    renders_one :actions
    renders_one :figure # For custom figure content

    def call
      content_tag :div, class: card_classes, **html_options do
        concat(figure_content)
        concat(card_body_content)
      end
    end

    private

    def card_classes
      classes = [ "card", "bg-base-100" ] # bg-base-100 is common for cards
      classes << "shadow-xl" # Default shadow, can be configured
      classes << "border border-base-300" if bordered
      classes << "image-full" if image_full && (image_url.present? || figure.present?)
      classes << "card-compact" if compact_card
      classes << "card-normal" if !normal_size && !compact_card # card-normal for fixed size, but not if compact
      classes.compact.join(" ")
    end

    def figure_content
      return unless image_url.present? || figure.present?

      content_tag :figure do
        if figure.present?
          figure
        elsif image_url.present?
          image_tag image_url, alt: image_alt
        end
      end
    end

    def card_body_content
      # The `body` slot is expected to be provided.
      # If `body` is nil (not provided), this might render an empty card-body or you could raise an error.
      # For DaisyUI, card-body is usually always present.
      content_tag :div, class: "card-body" do
        concat(content_tag(:h2, title, class: "card-title")) if title.present?
        concat(body) if body.present? # Render the captured body slot
        concat(actions_section) if actions.present?
      end
    end

    def actions_section
      content_tag :div, class: "card-actions justify-end" do # Common to justify actions to the end
        actions
      end
    end
  end
end
