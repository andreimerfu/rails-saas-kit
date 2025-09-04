# frozen_string_literal: true

require "rails_helper"

RSpec.describe UI::ButtonComponent, type: :component do
  let(:label) { "Click Me" }
  let(:default_options) { { label: label } }

  it "renders a button tag by default" do
    render_inline(described_class.new(**default_options))
    expect(page).to have_button(label, class: "btn")
    expect(page.find("button")[:type]).to eq("button")
  end

  it "renders an anchor tag when path is provided" do
    path = "/test_path"
    render_inline(described_class.new(**default_options, path: path))
    expect(page).to have_link(label, href: path, class: "btn")
  end

  it "renders with a specific type for button tag" do
    render_inline(described_class.new(**default_options, type: "submit"))
    expect(page).to have_button(label, type: "submit", class: "btn")
  end

  context "with styles" do
    UI::ButtonComponent::STYLES.each_key do |style_key|
      it "renders with style: #{style_key}" do
        render_inline(described_class.new(**default_options, style: style_key))
        expect(page).to have_css(".btn.#{UI::ButtonComponent::STYLES[style_key]}", text: label)
      end
    end
  end

  context "with sizes" do
    UI::ButtonComponent::SIZES.each_key do |size_key|
      next if size_key == :md # md is default, no specific class

      it "renders with size: #{size_key}" do
        render_inline(described_class.new(**default_options, size: size_key))
        expect(page).to have_css(".btn.#{UI::ButtonComponent::SIZES[size_key]}", text: label)
      end
    end

    it "renders with default size :md without a size class" do
      render_inline(described_class.new(**default_options, size: :md))
      # Check that it *doesn't* have other size classes
      UI::ButtonComponent::SIZES.each_key do |size_key|
        next if size_key == :md
        expect(page).not_to have_css(".#{UI::ButtonComponent::SIZES[size_key]}")
      end
      expect(page).to have_button(label, class: "btn") # just "btn" and style class
    end
  end

  context "with shapes" do
    UI::ButtonComponent::SHAPES.each_key do |shape_key|
      it "renders with shape: #{shape_key}" do
        render_inline(described_class.new(**default_options, shape: shape_key))
        expect(page).to have_css(".btn.#{UI::ButtonComponent::SHAPES[shape_key]}", text: label)
      end
    end
  end

  it "renders an outline button" do
    render_inline(described_class.new(**default_options, outline: true))
    expect(page).to have_button(label, class: "btn-outline")
  end

  it "renders a disabled button" do
    render_inline(described_class.new(**default_options, disabled: true))
    expect(page).to have_button(label, class: "btn-disabled", disabled: true)
  end

  it "renders a disabled link with class" do
    render_inline(described_class.new(**default_options, path: "/test", disabled: true))
    expect(page).to have_link(label, class: "btn-disabled")
    # Note: `disabled` attribute is not standard for `<a>` tags, DaisyUI uses class.
  end

  it "renders a wide button" do
    render_inline(described_class.new(**default_options, wide: true))
    expect(page).to have_button(label, class: "btn-wide")
  end

  it "renders a block button" do
    render_inline(described_class.new(**default_options, block: true))
    expect(page).to have_button(label, class: "btn-block")
  end

  it "renders with additional HTML options" do
    render_inline(described_class.new(**default_options, id: "my-button", data: { turbo: false }))
    expect(page).to have_button(label, id: "my-button")
    expect(page.find("button")["data-turbo"]).to eq("false")
  end

  it "combines classes correctly" do
    render_inline(described_class.new(label: "Styled Button", style: :primary, size: :lg, outline: true, wide: true))
    expect(page).to have_button("Styled Button", class: "btn btn-primary btn-lg btn-outline btn-wide")
  end
end
