def typhoeus_stub(name)
  response = Typhoeus::Response.new(:code => 200, :headers => "", :body => xml_fixture(name), :time => 0.3)
  Typhoeus::Request.should_receive(:post).with(any_args()).at_least(:once).and_return(response)
end

def typhoeus_hydra_stub(name)
  response = Typhoeus::Response.new(:code => 200, :headers => "", :body => xml_fixture(name), :time => 0.3)
  hydra = Typhoeus::Hydra.hydra
  hydra.stub(:post, /http/).and_return(response)
  Typhoeus::Hydra.should_receive(:new).and_return(hydra)
end

def xml_fixture(name)
  File.read(File.join(Rails.root, 'spec', 'fixtures', 'soap', name.to_s + '.xml'))
end

def assert_in_soap_request(regex)
  MySoapService::Base.last_request.to_xml.should =~ regex
end
