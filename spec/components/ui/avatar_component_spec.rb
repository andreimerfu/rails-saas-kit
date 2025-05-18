# frozen_string_literal: true

require "rails_helper"

RSpec.describe UI::AvatarComponent, type: :component do
  let(:src) { "/images/stock/avatar-1.jpg" }
  let(:alt) { "User Avatar" }
  let(:placeholder_text) { "JD" }
  let(:default_options) { { src: src, alt: alt } }

  it "renders an avatar with an image" do
    render_inline(described_class.new(**default_options))
    expect(page).to have_css(".avatar")
    expect(page).to have_css("img[src='#{src}'][alt='#{alt}']")
    # Default shape :circle (rounded-full) and size :md (w-16 h-16)
    expect(page).to have_css(".avatar > div.w-16.h-16.rounded-full img")
  end

  it "raises an error if src and placeholder_text are both blank" do
    expect do
      render_inline(described_class.new(src: nil, placeholder_text: nil))
    end.to raise_error(ArgumentError, "Placeholder text is recommended if src is not provided")
  end

  context "with placeholder" do
    it "renders a placeholder avatar if src is not provided" do
      render_inline(described_class.new(placeholder_text: placeholder_text, size: :sm))
      expect(page).to have_css(".avatar.placeholder")
      expect(page).to have_css(".avatar .bg-neutral-focus.text-neutral-content.w-12.h-12.rounded-full span", text: placeholder_text)
      expect(page).not_to have_css("img")
    end

    it "renders placeholder with status class" do
      render_inline(described_class.new(placeholder_text: placeholder_text, online: true))
      # Status class on placeholder is on the inner div with .avatar.placeholder
      expect(page).to have_css(".avatar.placeholder.online")
    end

    it "truncates placeholder text to 3 characters" do
      render_inline(described_class.new(placeholder_text: "LONGERTEXT"))
      expect(page).to have_css(".avatar.placeholder span", text: "LON")
    end
  end

  context "with shapes" do
    it "renders with circle shape by default" do
      render_inline(described_class.new(**default_options))
      expect(page).to have_css(".avatar > div.rounded-full")
    end

    it "renders with rounded shape" do
      render_inline(described_class.new(**default_options, shape: :rounded))
      expect(page).to have_css(".avatar > div.rounded-lg")
    end

    it "renders placeholder with specified shape" do
      render_inline(described_class.new(placeholder_text: "RP", shape: :rounded))
      expect(page).to have_css(".avatar.placeholder .rounded-lg span", text: "RP")
    end
  end

  context "with sizes" do
    UI::AvatarComponent::SIZES.each do |size_key, size_class|
      it "renders with predefined size: #{size_key}" do
        render_inline(described_class.new(**default_options, size: size_key))
        expect(page).to have_css(".avatar > div.#{size_class.split.join('.')}")
      end

      it "renders placeholder with predefined size: #{size_key}" do
        render_inline(described_class.new(placeholder_text: "PS", size: size_key))
        expect(page).to have_css(".avatar.placeholder .#{size_class.split.join('.')}", text: "PS")
      end
    end

    it "renders with custom string size class" do
      custom_size = "w-10 h-10"
      render_inline(described_class.new(**default_options, size: custom_size))
      expect(page).to have_css(".avatar > div.w-10.h-10")
    end

    it "renders placeholder with custom string size class" do
      custom_size = "w-10 h-10"
      render_inline(described_class.new(placeholder_text: "CS", size: custom_size))
      expect(page).to have_css(".avatar.placeholder .w-10.h-10", text: "CS")
    end
  end

  context "with status indicators" do
    it "renders with online indicator for image avatar" do
      render_inline(described_class.new(**default_options, online: true))
      expect(page).to have_css(".avatar.online")
      expect(page).to have_css(".avatar > div img") # Ensure it's the image avatar
    end

    it "renders with offline indicator for image avatar" do
      render_inline(described_class.new(**default_options, offline: true))
      expect(page).to have_css(".avatar.offline")
      expect(page).to have_css(".avatar > div img")
    end

    it "renders placeholder with online status" do
      render_inline(described_class.new(placeholder_text: "ON", online: true))
      expect(page).to have_css(".avatar.placeholder.online")
    end

    it "renders placeholder with offline status" do
      render_inline(described_class.new(placeholder_text: "OF", offline: true))
      expect(page).to have_css(".avatar.placeholder.offline")
    end
  end

  it "renders with custom class" do
    render_inline(described_class.new(**default_options, custom_class: "my-custom-avatar-class"))
    expect(page).to have_css(".avatar.my-custom-avatar-class")
  end

  it "renders with additional HTML options" do
    render_inline(described_class.new(**default_options, id: "user-avatar-1", data: { user_id: "123" }))
    expect(page).to have_css(".avatar#user-avatar-1")
    expect(page.find(".avatar")["data-user-id"]).to eq("123")
  end
end
