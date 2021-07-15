#
# Create certificates then install candlepin
#

$keydir = '/etc/candlepin/certs'
$keystore = "${keydir}/keystore"
$keystore_password = 'secret'
$truststore = "${keydir}/truststore"
$truststore_password = 'secret'
$ca_key = "${keydir}/candlepin-ca.key"
$ca_cert = "${keydir}/candlepin-ca.crt"

exec { "/bin/mkdir -p ${keydir}":
  creates => $keydir,
} ->
exec { 'Create CA key':
  command => "/usr/bin/openssl genrsa -out '${ca_key}' 2048",
  creates => $ca_key,
} ->
exec { 'Create CA certficate':
  command => "/usr/bin/openssl req -new -x509 -key '${ca_key}' -out '${ca_cert}' -nodes -x509 -subj '/C=US/ST=North Carolina/L=Raleigh/O=CustomKatelloCA/CN=${facts['networking']['fqdn']}'",
  creates => $ca_cert,
} ->
exec { 'Create keystore':
  command => "/usr/bin/openssl pkcs12 -export -in '${ca_cert}' -inkey '${ca_key}' -out '${keystore}' -name tomcat -CAfile '${ca_cert}' -caname root -password 'pass:${keystore_password}'",
  creates => $keystore,
} ->
package { ['java']: } ->
exec { 'Create truststore':
  command => "/usr/bin/keytool -import -v -keystore ${truststore} -alias candlepin-ca -file ${ca_cert} -noprompt -storepass ${truststore_password} -storetype pkcs12",
  creates => $truststore,
} ->
class { 'candlepin':
  ca_key              => $ca_key,
  ca_cert             => $ca_cert,
  keystore_file       => $keystore,
  keystore_password   => $keystore_password,
  truststore_file     => $truststore,
  truststore_password => $truststore_password,
  java_package        => 'java-11-openjdk',
  java_home           => '/usr/lib/jvm/jre-11',
  artemis_client_dn   => Deferred('pick', ['', 'CN=ActiveMQ Artemis Deferred, OU=Artemis, O=ActiveMQ, L=AMQ, ST=AMQ, C=AMQ']),
}
