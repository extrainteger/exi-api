module API
  module V1
    module ExceptionHandlers
      def self.included(base)
        base.instance_eval do
          
          rescue_from :all do |e|
            # When required params are missing or validation fails
            if e.class.name == 'Grape::Exceptions::ValidationErrors'
              code    = 406
              message = e.message
              # Bad token
            elsif e.class.name == 'RuntimeError' && e.message == 'Invalid base64 string'
              code    = 406
              message = '401 Unauthorized'
            # Record not found
            elsif e.is_a?(ActiveRecord::RecordNotFound)
              code    = 404
              model   = e.model.constantize.model_name.human(locale: :id).downcase
              message = I18n.t(:'activerecord.errors.messages.record_not_found', model: model, locale: :id)
            # Record invalid
            elsif e.is_a?(ActiveRecord::RecordInvalid) || e.is_a?(ActiveRecord::RecordNotDestroyed)
              code    = 422
              message = e.message
            # Pagy overflow
            elsif e.is_a?(Pagy::OverflowError)
              code    = 406
              message = "Out of page :("
            # 500 internal server error
            else
              code    = 500
              message = e.message
            end
            
            error! message, code
          end

        end
      end
    end
  end
end
