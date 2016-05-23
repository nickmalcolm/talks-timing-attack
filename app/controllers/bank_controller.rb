class BankController < ActionController::API
  include ActionController::HttpAuthentication::Token::ControllerMethods

  TOKEN = "secret"

  before_action :authenticate, except: [:teller]

  def teller
    render plain: "Hello, I'm the bank teller. How can I help?"
  end

  def vault
    render plain: "You have entered the vault"
  end

  private
    def authenticate
      authenticate_or_request_with_http_token do |token, options|
        token == TOKEN
      end
    end

end
