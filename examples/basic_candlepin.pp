#
# Create certificates then install candlepin
#

$keydir = '/etc/pki'
$keystore_password = 'secret'
$truststore_password = 'secret'
$ca_key = "${keydir}/candlepin-ca.key"
$ca_cert = "${keydir}/candlepin-ca.crt"

$common_name = $facts['networking']['fqdn']
$dir = '/etc/pki'
$tomcat_key = "${dir}/${common_name}.key"
$tomcat_req = "${dir}/${common_name}.req"
$tomcat_cert = "${dir}/${common_name}.crt"

exec { "/bin/mkdir -p ${keydir}":
  creates => $keydir,
} ->
exec { 'Create CA key':
  command => "/usr/bin/openssl genrsa -out '${ca_key}' 2048",
  creates => $ca_key,
  notify  => Service['tomcat'],
} ->
exec { 'Create CA certficate':
  command => "/usr/bin/openssl req -new -x509 -key '${ca_key}' -out '${ca_cert}' -nodes -x509 -subj '/C=US/ST=North Carolina/L=Raleigh/O=CustomKatelloCA/CN=${facts['networking']['fqdn']}'",
  creates => $ca_cert,
  notify  => Service['tomcat'],
} ->
exec { "Create ${common_name} tomcat key":
  command => "/usr/bin/openssl genrsa -out '${tomcat_key}' 2048",
  creates => $tomcat_key,
} ->
exec { "Create ${common_name} tomcat certificate signing request":
  command => "/usr/bin/openssl req -new -key '${tomcat_key}' -out '${tomcat_req}' -subj '/C=US/ST=North Carolina/CN=${common_name}'",
  creates => $tomcat_req,
} ->
exec { "Create ${common_name} tomcat certificate":
  command => "/usr/bin/openssl x509 -req -in '${tomcat_req}' -out '${tomcat_cert}' -CA '${ca_cert}' -CAkey '${ca_key}' -set_serial 1",
  creates => $tomcat_cert,
} ->
package { ['java']: } ->
class { 'candlepin':
  ca_key                     => $ca_key,
  ca_cert                    => $ca_cert,
  keystore_password          => $keystore_password,
  truststore_password        => $truststore_password,
  tomcat_ssl_cert            => $tomcat_cert,
  tomcat_ssl_key             => $tomcat_key,
  artemis_client_certificate => $tomcat_cert,
  java_package               => 'java-11-openjdk',
  java_home                  => '/usr/lib/jvm/jre-11',
  artemis_client_dn          => Deferred('pick', ['', 'CN=ActiveMQ Artemis Deferred, OU=Artemis, O=ActiveMQ, L=AMQ, ST=AMQ, C=AMQ']),
}
