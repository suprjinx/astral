module FailOnError
  extend ActiveSupport::Concern

  included do
    around do |interactor|
      interactor.call
    rescue Interactor::Failure => e
      # this error class should be propogated for organizers
      raise e
    rescue => e
      Rails.logger.error("#{e.message} (#{e.class})")
      context.fail!(error: e)
    end
  end
end
