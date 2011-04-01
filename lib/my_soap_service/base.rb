require 'nokogiri'
require 'typhoeus'

module MySoapService
  NAMESPACE    = "http://mysoapservice.com/"
  CLIENT_TOKEN = "ABCDEABCDE"

  class Base
    SERVICE_URL  = "http://soap.example.com/"

    cattr_accessor :last_request, :last_response

    # Performs the SOAP request
    def self.soap_it!(for_hydra=false, &block)
      data = construct_envelope(&block)
      @@last_request = data
      if for_hydra then
        Typhoeus::Request.new(SERVICE_URL,
                                :method => :post,
                                :body => data.to_xml,
                                :headers => {'Content-Type' => "text/xml; charset=utf-8"})
      else
        response = Typhoeus::Request.post(SERVICE_URL,
                                :body    => data.to_xml,
                                :headers => {'Content-Type' => "text/xml; charset=utf-8"})

        process_response(response)
      end
    end

    def self.construct_envelope(&block)
      Nokogiri::XML::Builder.new do |xml|
        xml.Envelope("xmlns:soap12" => "http://www.w3.org/2003/05/soap-envelope",
                     "xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance",
                     "xmlns:xsd" => "http://www.w3.org/2001/XMLSchema") do
          xml.parent.namespace = xml.parent.namespace_definitions.first
          xml['soap12'].Header do
            # Header information goes here
            xml.ClientHeader("xmlns" => NAMESPACE) do
              xml.ClientToken CLIENT_TOKEN
            end
          end
          xml['soap12'].Body(&block)
        end
      end
    end

    # Processes the response and decides whether to handle an error or
    # whether to return the content
    def self.process_response(response)
      @@last_response = response

      if response.body =~ /soap:Fault/ then
        handle_error(response)
      else
        return response
      end
    end

    # Parses a soap:Fault error and raises it as a MySoapService::SoapError
    def self.handle_error(response)
      xml   = Nokogiri::XML(response.body)
      xpath = '/soap:Envelope/soap:Body/soap:Fault//ExceptionMessage'
      msg   = xml.xpath(xpath).text

      # TODO: Capture any app-specific exception messages here.
      #       For example, if the server returns a Fault when a search
      #       has no results, you might rather return an empty array.

      raise MySoapService::SoapError.new("Error from server: #{msg}", @@last_request, @@last_response)
    end

    # Merges in the MySoapService namespace
    def self.namespaces(xml)
      { 'mss' => NAMESPACE }.merge(xml.document.namespaces)
    end
  end
end
