class UserPolicy < ApplicationPolicy
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

  # Can the user invite members to their organization?
  def invite_member?
    user.is_owner_or_admin?
  end
end
