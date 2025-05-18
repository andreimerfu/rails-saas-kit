# frozen_string_literal: true

require "rails_helper"

RSpec.describe UI::CardComponent, type: :component do
  let(:title_text) { "Card Title Example" }
  let(:body_text) { "This is the main content of the card." }
  let(:image_url_example) { "/images/stock/photo-1606107557195-0e29a4b5b4aa.jpg" }
  let(:image_alt_example) { "Stock photo of shoes" }

  context "basic rendering" do
    it "renders a card with title and body" do
      render_inline(described_class.new(title: title_text)) do |card|
        card.with_body { "<p>#{body_text}</p>".html_safe }
      end

      expect(page).to have_css(".card .card-body")
      expect(page).to have_css("h2.card-title", text: title_text)
      expect(page).to have_selector(".card .card-body p", text: body_text)
      # Default classes: bg-base-100, shadow-xl, bordered
      expect(page).to have_css(".card.bg-base-100.shadow-xl.border.border-base-300")
    end

    it "renders without a title if not provided" do
      render_inline(described_class.new) do |card|
        card.with_body { "<p>#{body_text}</p>".html_safe }
      end
      expect(page).not_to have_css("h2.card-title")
      expect(page).to have_selector(".card .card-body p", text: body_text)
    end

    it "does not render card-body content if body slot is empty" do
      render_inline(described_class.new(title: title_text)) do |card|
        # No body slot provided
      end
      expect(page).to have_css(".card .card-body") # card-body div itself is present
      expect(page).to have_css("h2.card-title", text: title_text) # title can still be there
      expect(page).not_to have_selector(".card .card-body p") # but no paragraph from body
    end
  end

  context "with image_url" do
    it "renders an image when image_url is provided" do
      render_inline(described_class.new(image_url: image_url_example, image_alt: image_alt_example)) do |card|
        card.with_body { body_text }
      end
      expect(page).to have_css(".card figure img[src='#{image_url_example}'][alt='#{image_alt_example}']")
    end

    it "does not render an image if image_url is not provided" do
      render_inline(described_class.new) do |card|
        card.with_body { body_text }
      end
      expect(page).not_to have_css(".card figure img")
    end

    it "applies image-full class when image_full is true and image_url is present" do
      render_inline(described_class.new(image_url: image_url_example, image_full: true)) do |card|
        card.with_body { body_text }
      end
      expect(page).to have_css(".card.image-full figure img")
    end
  end

  context "with card style options" do
    it "renders without border if bordered is false" do
      render_inline(described_class.new(bordered: false)) do |card|
        card.with_body { body_text }
      end
      expect(page).not_to have_css(".card.border.border-base-300")
      expect(page).to have_css(".card.shadow-xl") # Shadow should still be there by default
    end

    it "renders as compact if compact_card is true" do
      render_inline(described_class.new(compact_card: true)) do |card|
        card.with_body { body_text }
      end
      expect(page).to have_css(".card.card-compact")
    end

    it "renders as normal (fixed-width on large screens) if normal_size is false and not compact" do
      render_inline(described_class.new(normal_size: false, compact_card: false)) do |card|
        card.with_body { body_text }
      end
      expect(page).to have_css(".card.card-normal")
    end

    it "does not render card-normal if normal_size is true (default responsive)" do
      render_inline(described_class.new(normal_size: true)) do |card|
        card.with_body { body_text }
      end
      expect(page).not_to have_css(".card.card-normal")
    end

    it "compact takes precedence over normal_size: false" do
      render_inline(described_class.new(compact_card: true, normal_size: false)) do |card|
        card.with_body { body_text }
      end
      expect(page).to have_css(".card.card-compact")
      expect(page).not_to have_css(".card.card-normal")
    end
  end

  context "with additional HTML options" do
    it "applies custom id and data attributes to the card" do
      render_inline(described_class.new(id: "my-special-card", data: { tracking_id: "xyz789" })) do |card|
        card.with_body { body_text }
      end
      expect(page).to have_css(".card#my-special-card")
      expect(page.find(".card")["data-tracking-id"]).to eq("xyz789")
    end
  end
end
