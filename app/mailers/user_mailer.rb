class UserMailer < ApplicationMailer
  def invitation_email(invited_user, inviting_user, organization)
    @invited_user = invited_user
    @inviting_user = inviting_user
    @organization = organization

    mail(to: @invited_user.email, subject: "You've been invited to join #{@organization.name}!")
  end
end
