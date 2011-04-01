require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe MySoapService::Base do
  describe ".soap_it!" do
    it "should raise an exception if it receives a fault response" do
      typhoeus_stub(:fault)
      lambda {
        MySoapService::Base.soap_it! do |xml|
        end
      }.should raise_exception(MySoapService::SoapError)
    end
  end
end
