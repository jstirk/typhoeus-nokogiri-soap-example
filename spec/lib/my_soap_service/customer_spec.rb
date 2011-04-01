require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe MySoapService::Customer do
  describe ".find_by_email" do
    it "should request a specific email address, returning the Customer" do
      typhoeus_stub(:customer)
      result = MySoapService::Customer.find_by_email('user@example.com')

      # Ensure that the request XML includes the expected elements
      assert_in_soap_request /<EmailAddress>user@example.com<\/EmailAddress>/

      # Ensure that our response has populated the class
      result.should be_a(Customer)
      result.email.should == 'user@example.com'
    end

    it "should raise an exception if the Customer couldn't be found" do
      typhoeus_stub(:fault)
      lambda {
        MySoapService::Customer.find_by_email('user@example.com')
      }.should raise_exception(MySoapService::SoapError)
    end
  end

  describe ".update_all_by_emails" do
    it "should issue 1 request for each email" do
      hydra = Typhoeus::Hydra.new
      hydra.should_receive(:queue).exactly(2).times
      Typhoeus::Hydra.should_receive(:new).and_return(hydra)

      MySoapService::Customer.update_all_by_emails(%w( user@example.com user2@example.com ))
    end

    it "should update an existing Customer" do
      typhoeus_hydra_stub(:customer)

      Customer.create!(:email => 'user@example.com')

      MySoapService::Customer.update_all_by_emails([ 'user@example.com' ])

      Customer.count.should == 1
      Customer.first.name.should == 'Bogus User'
    end

    it "should create a new Customer" do
      typhoeus_hydra_stub(:customer)

      MySoapService::Customer.update_all_by_emails([ 'user@example.com' ])

      Customer.count.should == 1
      Customer.first.name.should == 'Bogus User'
    end
  end
end
