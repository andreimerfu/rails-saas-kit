# frozen_string_literal: true

require "rails_helper"

RSpec.describe UI::BadgeComponent, type: :component do
  let(:label) { "My Badge" }
  let(:default_options) { { label: label } }

  it "renders a basic badge with label" do
    render_inline(described_class.new(**default_options))
    expect(page).to have_css(".badge", text: label)
    # Default style is :neutral, which maps to badge-neutral
    expect(page).to have_css(".badge.badge-neutral")
  end

  context "with styles" do
    UI::BadgeComponent::STYLES.each_key do |style_key|
      it "renders with style: #{style_key}" do
        render_inline(described_class.new(**default_options, style: style_key))
        expected_class = UI::BadgeComponent::STYLES[style_key]
        if style_key == :neutral && expected_class == "badge" # Special case if neutral maps to just "badge"
          expect(page).to have_css(".badge", text: label)
          expect(page).not_to have_css(".badge-primary") # Ensure no other style is applied
        else
          expect(page).to have_css(".badge.#{expected_class}", text: label)
        end
      end
    end
  end

  context "with sizes" do
    UI::BadgeComponent::SIZES.each_key do |size_key|
      next if size_key == :md # md is default, no specific class

      it "renders with size: #{size_key}" do
        render_inline(described_class.new(**default_options, size: size_key))
        expect(page).to have_css(".badge.#{UI::BadgeComponent::SIZES[size_key]}", text: label)
      end
    end

    it "renders with default size :md without a size class" do
      render_inline(described_class.new(**default_options, size: :md))
      UI::BadgeComponent::SIZES.each_key do |size_key|
        next if size_key == :md
        expect(page).not_to have_css(".#{UI::BadgeComponent::SIZES[size_key]}")
      end
      # It should have 'badge' and the default style class ('badge-neutral')
      expect(page).to have_css(".badge.badge-neutral", text: label)
    end
  end

  it "renders an outline badge" do
    render_inline(described_class.new(**default_options, outline: true))
    expect(page).to have_css(".badge.badge-outline", text: label)
  end

  it "renders with additional HTML options" do
    render_inline(described_class.new(**default_options, id: "my-badge", data: { value: "123" }))
    expect(page).to have_css(".badge#my-badge", text: label)
    expect(page.find(".badge")["data-value"]).to eq("123")
  end

  it "combines classes correctly" do
    render_inline(described_class.new(label: "Styled Badge", style: :primary, size: :lg, outline: true))
    expect(page).to have_css(".badge.badge-primary.badge-lg.badge-outline", text: "Styled Badge")
  end

  it "handles neutral style correctly (should have badge-neutral)" do
    render_inline(described_class.new(label: "Neutral Badge", style: :neutral))
    expect(page).to have_css(".badge.badge-neutral", text: "Neutral Badge")
    # Ensure it doesn't have "badge badge" if STYLES[:neutral] was just "badge"
    expect(page.find(".badge")[:class].split.count("badge")).to eq(1)
  end
end
