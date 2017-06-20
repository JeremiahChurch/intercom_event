module IntercomEvent
  class WebhookController < ActionController::Base
    # if respond_to?(:before_action)
    #   before_action :request_authentication
    # else
    #   before_filter :request_authentication
    # end

    def event
      IntercomEvent.instrument(params)
      head :ok
    rescue IntercomEvent::UnauthorizedError => e
      log_error(e)
      head :unauthorized
    end

    private

    def log_error(e)
      logger.error e.message
      e.backtrace.each { |line| logger.error "  #{line}" }
    end

    # def request_authentication
    #   if IntercomEvent.authentication_secret
    #     authenticate_or_request_with_http_basic do |username, password|
    #       password == IntercomEvent.authentication_secret
    #     end
    #   end
    # end
  end
end
