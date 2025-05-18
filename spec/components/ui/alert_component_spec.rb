# frozen_string_literal: true

require "rails_helper"

RSpec.describe UI::AlertComponent, type: :component do
  let(:title_text) { "This is a title" }
  let(:body_text) { "This is the alert body content." }
  context "basic rendering" do
    it "renders with a title and body" do
      render_inline(described_class.new(title: title_text)) do
        body_text
      end

      expect(page).to have_css(".alert")
      expect(page).to have_text(body_text)
    end

    it "renders with only body if no title is provided" do
      render_inline(described_class.new) do
        body_text
      end

      expect(page).to have_css(".alert")
      expect(page).to have_text(body_text)
    end
  end

  context "with styles" do
    UI::AlertComponent::KIND_MAPPING.each do |style_key, style_class|
      it "renders with style: #{style_key}" do
        render_inline(described_class.new(kind: style_key)) do
          body_text
        end
        if style_class.present?
          expect(page).to have_css(".alert.#{style_class}")
        else
          # For :default style which might have an empty class string
          expect(page).to have_css(".alert")
          UI::AlertComponent::KIND_MAPPING.each_value do |other_style_class|
            next if other_style_class.blank?
            expect(page).not_to have_css(".#{other_style_class}")
          end
        end
      end
    end
  end

  context "with additional HTML options" do
    it "applies custom id and data attributes" do
      render_inline(described_class.new(id: "custom-alert", data: { test_id: "alert-123" })) do
        body_text
      end
      expect(page).to have_css(".alert#custom-alert")
      expect(page.find(".alert")["data-test-id"]).to eq("alert-123")
    end
  end
end
