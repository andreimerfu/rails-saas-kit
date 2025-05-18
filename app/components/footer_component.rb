class FooterComponent < ViewComponent::Base
  include IconsHelper

  def initialize(company_name: "ACME Industries Ltd.", company_description: "Providing reliable tech since 1992")
    @company_name = company_name
    @company_description = company_description
  end
end
