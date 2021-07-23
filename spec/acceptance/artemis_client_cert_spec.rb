require 'spec_helper_acceptance'

#TODO: Add Artemis listening test https://projects.theforeman.org/issues/29561

describe 'candlepin works' do
  context 'initial certificates' do
    include_examples 'the example', 'artemis_client_cert.pp'

    describe port(8443) do
      it { is_expected.to be_listening }
    end

    describe command('curl -k -s -o /dev/null -w \'%{http_code}\' https://localhost:8443/candlepin/status') do
      its(:stdout) { should eq "200" }
    end

    describe command('nmap --script +ssl-enum-ciphers localhost -p 8443') do
      # We don't enable TLSv1.3 by default yet. TLSv1.3 support was added in tomcat 7.0.92
      # But tomcat 7.0.76 is the latest version available on EL7
      its(:stdout) { should_not match(/TLSv1\.3/) }

      # Test that TLSv1.2 is enabled
      its(:stdout) { should match(/TLSv1\.2/) }

      # Test that older TLS versions are disabled
      its(:stdout) { should_not match(/TLSv1\.1/) }
      its(:stdout) { should_not match(/TLSv1\.0/) }

      # Test that the least cipher strength is "strong" or "A"
      its(:stdout) { should match(/least strength: (A|strong)/) }
    end

    describe file("/usr/share/tomcat/conf/cert-users.properties") do
      it { should be_file }
      it { should be_mode 640 }
      it { should be_owned_by 'tomcat' }
      it { should be_grouped_into 'tomcat' }
      its(:content) { should eq("example01.example.com=CN=example01.example.com, ST=North Carolina, C=US\n") }
    end

    describe file("/usr/share/tomcat/conf/cert-roles.properties") do
      it { should be_file }
      it { should be_mode 640 }
      it { should be_owned_by 'tomcat' }
      it { should be_grouped_into 'tomcat' }
      its(:content) { should eq("candlepinEventsConsumer=example01.example.com\n") }
    end
  end

  context 'with new certificates' do
    before(:context) do
      on default, 'rm -rf /etc/pki/artemis'
    end

    include_examples 'the example', 'artemis_client_cert_new_host.pp'

    describe port(8443) do
      it { is_expected.to be_listening }
    end

    describe command('curl -k -s -o /dev/null -w \'%{http_code}\' https://localhost:8443/candlepin/status') do
      its(:stdout) { should eq "200" }
    end

    describe command('nmap --script +ssl-enum-ciphers localhost -p 8443') do
      # We don't enable TLSv1.3 by default yet. TLSv1.3 support was added in tomcat 7.0.92
      # But tomcat 7.0.76 is the latest version available on EL7
      its(:stdout) { should_not match(/TLSv1\.3/) }

      # Test that TLSv1.2 is enabled
      its(:stdout) { should match(/TLSv1\.2/) }

      # Test that older TLS versions are disabled
      its(:stdout) { should_not match(/TLSv1\.1/) }
      its(:stdout) { should_not match(/TLSv1\.0/) }

      # Test that the least cipher strength is "strong" or "A"
      its(:stdout) { should match(/least strength: (A|strong)/) }
    end

    describe file("/usr/share/tomcat/conf/cert-users.properties") do
      it { should be_file }
      it { should be_mode 640 }
      it { should be_owned_by 'tomcat' }
      it { should be_grouped_into 'tomcat' }
      its(:content) { should eq("example02.example.com=CN=example02.example.com, ST=North Carolina, C=US\n") }
    end

    describe file("/usr/share/tomcat/conf/cert-roles.properties") do
      it { should be_file }
      it { should be_mode 640 }
      it { should be_owned_by 'tomcat' }
      it { should be_grouped_into 'tomcat' }
      its(:content) { should eq("candlepinEventsConsumer=example02.example.com\n") }
    end
  end

  context 'with multiple certificates' do
    before(:context) do
      on default, 'rm -rf /etc/pki/artemis'
    end

    include_examples 'the example', 'artemis_client_cert_multi_host.pp'

    describe port(8443) do
      it { is_expected.to be_listening }
    end

    describe command('curl -k -s -o /dev/null -w \'%{http_code}\' https://localhost:8443/candlepin/status') do
      its(:stdout) { should eq "200" }
    end

    describe command('nmap --script +ssl-enum-ciphers localhost -p 8443') do
      # We don't enable TLSv1.3 by default yet. TLSv1.3 support was added in tomcat 7.0.92
      # But tomcat 7.0.76 is the latest version available on EL7
      its(:stdout) { should_not match(/TLSv1\.3/) }

      # Test that TLSv1.2 is enabled
      its(:stdout) { should match(/TLSv1\.2/) }

      # Test that older TLS versions are disabled
      its(:stdout) { should_not match(/TLSv1\.1/) }
      its(:stdout) { should_not match(/TLSv1\.0/) }

      # Test that the least cipher strength is "strong" or "A"
      its(:stdout) { should match(/least strength: (A|strong)/) }
    end

    describe file("/usr/share/tomcat/conf/cert-users.properties") do
      it { should be_file }
      it { should be_mode 640 }
      it { should be_owned_by 'tomcat' }
      it { should be_grouped_into 'tomcat' }
      its(:content) { should eq("example01.example.com=CN=example01.example.com, ST=North Carolina, C=US\nexample02.example.com=CN=example02.example.com, ST=North Carolina, C=US\n") }
    end

    describe file("/usr/share/tomcat/conf/cert-roles.properties") do
      it { should be_file }
      it { should be_mode 640 }
      it { should be_owned_by 'tomcat' }
      it { should be_grouped_into 'tomcat' }
      its(:content) { should eq("candlepinEventsConsumer=example01.example.com,example02.example.com\n") }
    end
  end
end
