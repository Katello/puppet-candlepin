#
# Create certificates then install candlepin
#
class { 'certificates': } ->
class { 'candlepin':
  ca_key              => $certificates::ca_key,
  ca_cert             => $certificates::ca_cert,
  keystore_file       => $certificates::keystore,
  keystore_password   => $certificates::keystore_password,
  truststore_file     => $certificates::truststore,
  truststore_password => $certificates::truststore_password,
  java_package        => 'java-11-openjdk',
  java_home           => '/usr/lib/jvm/jre-11',
  artemis_client_dn   => Deferred('pick', ['', 'CN=ActiveMQ Artemis Deferred, OU=Artemis, O=ActiveMQ, L=AMQ, ST=AMQ, C=AMQ']),
}
