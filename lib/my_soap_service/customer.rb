module MySoapService
  class Customer < Base
    # Map XML elements to our local fields
    CUSTOMER_FIELD_MAPPING = { :Name => :name, :EmailAddress => :email }

    def self.find_by_email(email)
      response = soap_it! do |xml|
        xml.GetCustomerDetail('xmlns' => NAMESPACE) do
          xml.EmailAddress email
        end
      end

      data = parse_customer_response(response)
      ::Customer.new(data) if data
    end

    def self.update_all_by_emails(emails)
      hydra = Typhoeus::Hydra.new
      emails.each do |email|
        request = soap_it!(true) do |xml|
          xml.GetCustomerDetail('xmlns' => NAMESPACE) do
            xml.EmailAddress email
          end
        end

        request.on_complete do |r|
          update_customer_from_response(r)
        end

        hydra.queue request
      end

      hydra.run
      true
    end

    def self.parse_customer_response(response)
      if response then
        xml    = Nokogiri::XML(response.body)
        xpath  = '/soap:Envelope/soap:Body/mss:GetCustomerDetailResponse/mss:GetCustomerDetailResult/mss:Customers/mss:Customer'
        result = xml.xpath(xpath, namespaces(xml)).first
        data   = {}
        CUSTOMER_FIELD_MAPPING.each do |soap_element, field|
          data[field] = result.xpath("./mss:#{soap_element}", namespaces(xml)).first.text
        end
        data
      else
        # Nothing to be done, no data returned
        false
      end
    end

    def self.update_customer_from_response(response)
      data = parse_customer_response(response)
      if data then
        customer = ::Customer.find_or_initialize_by_email(data[:email], data)
        customer.update_attributes(data)
        customer
      end
    end
  end
end
