class OrganizationPolicy < ApplicationPolicy
  def index?
    user.admin?
  end

  def show?
    user.admin?
  end

  def create?
    user.admin?
  end

  def new?
    create?
  end

  def update?
    user.admin?
  end

  def edit?
    update?
  end

  def destroy?
    user.admin?
  end

  def admin?
    user.admin?
  end

  def pricing?
    # The user must be associated with the record (organization)
    # and have the 'owner' role within that organization.
    user.present? && record.present? && user.organization == record && user.role == "owner"
  end

  # Can the current user remove members from this organization in general?
  def remove_member?
    return false unless user.present? && record.present? # record is the organization

    # User must be an admin or an owner of the organization (record)
    user.admin? || (user.organization == record && user.role == "owner")
  end

  # Can the current user invite members to this organization?
  def invite_member?
    return false unless user.present? && record.present? # record is the organization

    # User must be an admin or an owner of the organization (record)
    user.admin? || (user.organization == record && user.role == "owner")
  end

  class Scope < Scope
    def resolve
      if user.admin?
        scope.all
      else
        # If not an admin, scope to organizations where the user is a member,
        # or adjust as needed for your application's logic.
        # For now, keeping it simple and restrictive like other policies.
        # If users should see their own organization, this would be:
        # scope.where(id: user.organization_id)
        scope.none
      end
    end
  end
end
