module Api
  module V1
    module ApiAuthentication
      extend ActiveSupport::Concern

      included do
        before_action :authenticate_api_key!
        attr_reader :current_api_key, :current_merchant
      end

      private

      def authenticate_api_key!
        api_key = extract_api_key_from_header

        return render_unauthorized("API key is missing") unless api_key

        @current_api_key = ApiKey.authenticate(api_key)

        return render_unauthorized("Invalid API key") unless @current_api_key

        return render_unauthorized("API key has expired") unless @current_api_key.active?

        # Set the current merchant
        @current_merchant = @current_api_key.merchant

        # Track usage
        @current_api_key.touch_last_used!
      end

      def extract_api_key_from_header
        # Support both:
        # Authorization: Bearer sk_abc123...
        # Authorization: sk_abc123...
        auth_header = request.headers["Authorization"]
        return nil unless auth_header

        # Remove "Bearer " prefix if present
        auth_header.gsub(/^Bearer\s+/, "").strip
      end

        def render_unauthorized(message)
          formatter = Formatters::Factory.for_request(request)
          render body: formatter.serialize_error(message),
                 status: :unauthorized,
                 content_type: formatter.content_type
        end
    end
  end
end
