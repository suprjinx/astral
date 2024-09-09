class AuthorizeRequest
  include Interactor
  include FailOnError

  def call
    Services::DomainOwnershipService.new.authorize!(context.identity, context.request)
  end
end
