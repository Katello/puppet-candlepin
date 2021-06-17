require 'spec_helper_acceptance'

# TODO: Add Artemis listening test https://projects.theforeman.org/issues/29561

describe 'candlepin works' do
  include_examples 'the example', 'basic_candlepin.pp'

  describe port(8443) do
    it { is_expected.to be_listening }
  end

  describe command('curl -k -s -o /dev/null -w \'%{http_code}\' https://localhost:8443/candlepin/status') do
    its(:stdout) { is_expected.to eq '200' }
  end

  describe command('nmap --script +ssl-enum-ciphers localhost -p 8443') do
    # We don't enable TLSv1.3 by default yet. TLSv1.3 support was added in tomcat 7.0.92
    # But tomcat 7.0.76 is the latest version available on EL7
    its(:stdout) { is_expected.not_to match(%r{TLSv1\.3}) }

    # Test that TLSv1.2 is enabled
    its(:stdout) { is_expected.to match(%r{TLSv1\.2}) }

    # Test that older TLS versions are disabled
    its(:stdout) { is_expected.not_to match(%r{TLSv1\.1}) }
    its(:stdout) { is_expected.not_to match(%r{TLSv1\.0}) }

    # Test that the least cipher strength is "strong" or "A"
    its(:stdout) { is_expected.to match(%r{least strength: (A|strong)}) }
  end
end
