module MySoapService
  class SoapError < StandardError
    attr_reader :last_request, :last_response

    def initialize(message, last_request, last_response)
      @last_request  = last_request
      @last_response = last_response
      super(message)
    end
  end
end
