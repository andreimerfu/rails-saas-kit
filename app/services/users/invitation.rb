# app/services/users/invitation.rb
module Users
  class Invitation
    include ApplicationService # This includes Dry::Workflow, Dry::Monads[:result, :do], and the BlockHandler

    # Define the steps of the invitation process
    step :validate_input
    step :check_existing_user
    step :invite_user, rollback: :log_failed_invitation_attempt
    map :prepare_success_message

    private

    def validate_input(payload)
      email = payload[:email]
      inviter = payload[:inviter]
      organization = payload[:organization]

      if email.blank?
        return Failure(type: :validation, field: :email, message: "Validation failed: Email cannot be blank.")
      end
      unless email =~ URI::MailTo::EMAIL_REGEXP
        return Failure(type: :validation, field: :email, message: "Validation failed: Invalid email format.")
      end
      unless inviter.is_a?(User) && organization.is_a?(Organization)
        return Failure(type: :validation, message: "Validation failed: Inviter must be a User and Organization must be an Organization.")
      end
      # Pass the original payload through, ensuring all data is carried forward.
      # Dry::Workflow merges the Success payload with the current state.
      Success(payload)
    end

    def check_existing_user(payload)
      email = payload[:email]
      organization = payload[:organization]

      existing_user = User.find_by(email: email)
      if existing_user
        if existing_user.organization_id == organization.id
          return Failure(type: :conflict, message: "Could not invite user: #{email} is already a member of this organization.")
        else
          return Failure(type: :conflict, message: "Could not invite user: #{email} is already associated with a different organization.")
        end
      end
      Success(payload)
    end

    def invite_user(payload)
      email = payload[:email]
      inviter = payload[:inviter]
      organization = payload[:organization]

      invited_user = User.invite!({ email: email, organization_id: organization.id }, inviter)

      if invited_user.persisted? && invited_user.errors.empty?
        Success(payload.merge(invited_user: invited_user))
      else
        error_messages = invited_user.errors.full_messages.to_sentence
        Failure(type: :invitation_failed, message: "Failed to send invitation: #{error_messages}", raw_errors: invited_user.errors.to_hash)
      end
    rescue StandardError => e
      Rails.logger.error "Users::Invitation: Invite step error - #{e.message}\n#{e.backtrace.join("\n")}"
      Failure(type: :invitation_failed, message: "An unexpected error occurred during invitation: #{e.message}")
    end

    def log_failed_invitation_attempt(payload_from_successful_invite_step)
      # This rollback is called if 'invite_user' succeeded but a *subsequent* step failed.
      # 'payload_from_successful_invite_step' is the Success output of the invite_user step.
      invited_user = payload_from_successful_invite_step[:invited_user]
      Rails.logger.warn "Users::Invitation: Rollback for 'invite_user' triggered for user #{invited_user&.email}. Data: #{payload_from_successful_invite_step.inspect}"
      # No explicit Success/Failure needed for rollback methods unless they can fail themselves.
    end

    def prepare_success_message(payload)
      # This map step transforms the successful output of the previous step (invite_user)
      # The 'payload' here is the current state of the workflow, which includes 'invited_user'.
      invited_user = payload[:invited_user]
      email = payload[:email] # Or invited_user.email

      {
        type: :invitation_sent,
        user: invited_user,
        message: "Invitation sent to #{email}."
      }
    end
  end
end
