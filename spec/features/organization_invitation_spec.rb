require 'rails_helper'

RSpec.feature "Organization Invitations", type: :feature do
  let(:organization) { create(:organization, name: "Test Corp") }
  let(:owner) { create(:user, :owner, organization: organization, name: "John Owner") }
  let(:new_user_email) { "newuser@example.com" }

  before do
    # For feature specs, we need to manually sign in via the UI or use a more direct approach
    login_as(owner, scope: :user)
  end

  describe "Inviting a new member" do
    scenario "Owner can invite a new member to the organization" do
      visit manage_organization_path

      within("form[action='#{organization_organization_invitations_path}']") do
        fill_in "Email Address", with: new_user_email
        click_button "Send Invitation"
      end

      expect(page).to have_content("Invitation sent to #{new_user_email}")

      # Verify user was created with invitation
      invited_user = User.find_by(email: new_user_email)
      expect(invited_user).to be_present
      expect(invited_user.invitation_token).to be_present
      expect(invited_user.organization).to eq(organization)
      expect(invited_user.invited_by).to eq(owner)
    end

    scenario "Cannot invite existing member" do
      existing_member = create(:user, email: "existing@example.com", organization: organization)

      visit manage_organization_path

      within("form[action='#{organization_organization_invitations_path}']") do
        fill_in "Email Address", with: existing_member.email
        click_button "Send Invitation"
      end

      expect(page).to have_content("Could not invite user: #{existing_member.email} is already a member of this organization")
    end
  end

  describe "Accepting invitation" do
    context "without enterprise SSO" do
      let!(:invited_user) { create(:user, :invited, email: new_user_email, organization: organization) }

      scenario "User can accept invitation and set password" do
        logout

        visit accept_invitation_path(token: invited_user.raw_invitation_token)

        expect(page).to have_content("Set Your Password")
        expect(page).to have_content("You've been invited to join #{organization.name}")

        fill_in "user_password", with: "SecurePassword123!"
        fill_in "user_password_confirmation", with: "SecurePassword123!"
        click_button "Set Password and Join"

        expect(page).to have_content("Welcome! Your password has been set and you are now signed in")
        expect(current_path).to eq(authenticated_root_path)

        # Verify invitation was accepted
        invited_user.reload
        expect(invited_user.invitation_accepted_at).to be_present
        expect(invited_user.encrypted_password).to be_present
      end

      scenario "Invalid invitation token shows error" do
        logout(:user)

        visit accept_invitation_path(token: "invalid_token")

        expect(page).to have_content("Invalid or expired invitation token.")
        expect(current_path).to eq(unauthenticated_root_path)
      end
    end

    context "with enterprise SSO" do
      let!(:sso_setting) { create(:enterprise_oauth_setting, domain: "sso-company.com", provider: "google_oauth2") }
      let!(:sso_organization) { create(:organization, name: "SSO Company", domain: "sso-company.com") }
      let!(:sso_owner) { create(:user, :owner, organization: sso_organization) }
      let!(:invited_sso_user) { create(:user, :invited, email: "user@sso-company.com", organization: sso_organization) }

      scenario "User is redirected to SSO login" do
        logout(:user)

        visit accept_invitation_path(token: invited_sso_user.raw_invitation_token)

        expect(page).to have_content("Your invitation has been accepted. Please log in with your company SSO.")
        expect(current_path).to eq(new_user_session_path)

        # Verify invitation was accepted
        invited_sso_user.reload
        expect(invited_sso_user.invitation_accepted_at).to be_present
      end
    end
  end

  describe "Sign in page with SSO detection" do
    let!(:sso_setting) { create(:enterprise_oauth_setting, domain: "enterprise.com", provider: "microsoft_entra_id") }

    scenario "Entering SSO email shows SSO option", js: true do
      logout(:user)
      visit new_user_session_path

      fill_in "Email address", with: "user@enterprise.com"
      # Use a different approach to trigger the blur event
      page.execute_script("document.getElementById('user_email').blur()")
      sleep 0.5 # Give JavaScript time to execute

      expect(page).to have_content("Your organization uses Single Sign-On")
      expect(page).to have_link("Continue with SSO")
      expect(page).not_to have_field("Password", visible: true)
    end

    scenario "Entering non-SSO email shows password field", js: true do
      logout(:user)
      visit new_user_session_path

      fill_in "Email address", with: "user@regular.com"
      # Use a different approach to trigger the blur event
      page.execute_script("document.getElementById('user_email').blur()")
      sleep 0.5 # Give JavaScript time to execute

      expect(page).not_to have_content("Your organization uses Single Sign-On")
      expect(page).to have_field("Password", visible: true)
    end
  end
end
