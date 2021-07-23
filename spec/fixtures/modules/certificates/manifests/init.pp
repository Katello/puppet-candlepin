# Create certificates
class certificates (
  $artemis_client_common_names = [$facts['networking']['fqdn']],
) {
  $keydir = '/etc/candlepin/certs'
  $keystore = "${keydir}/keystore"
  $keystore_password = 'secret'
  $truststore = "${keydir}/truststore"
  $truststore_password = 'secret'
  $ca_key = "${keydir}/candlepin-ca.key"
  $ca_cert = "${keydir}/candlepin-ca.crt"

  $artemis_dir = '/etc/pki/artemis'

  exec { "/bin/mkdir -p ${keydir}":
    creates => $keydir,
  } ->
  exec { 'Create CA key':
    command => "/usr/bin/openssl genrsa -out '${ca_key}' 2048",
    creates => $ca_key,
    notify  => Service['tomcat'],
  } ->
  exec { 'Create CA certificate':
    command => "/usr/bin/openssl req -new -x509 -key '${ca_key}' -out '${ca_cert}' -nodes -x509 -subj '/C=US/ST=North Carolina/L=Raleigh/O=CustomKatelloCA/CN=${facts['networking']['fqdn']}'",
    creates => $ca_cert,
    notify  => Service['tomcat'],
  } ->
  exec { 'Create keystore':
    command => "/usr/bin/openssl pkcs12 -export -in '${ca_cert}' -inkey '${ca_key}' -out '${keystore}' -name tomcat -CAfile '${ca_cert}' -caname root -password 'pass:${keystore_password}'",
    creates => $keystore,
    notify  => Service['tomcat'],
  } ->
  package { ['java']: } ->
  exec { 'Create truststore':
    command => "/usr/bin/keytool -import -v -keystore ${truststore} -alias candlepin-ca -file ${ca_cert} -noprompt -storepass ${truststore_password} -storetype pkcs12",
    creates => $truststore,
  } ->
  file { $ca_key:
    mode  => '0440',
    group => 'tomcat',
  } ->
  file { $ca_cert:
    mode  => '0440',
    group => 'tomcat',
  } ->
  file { $keystore:
    mode  => '0440',
    group => 'tomcat',
  } ->
  file { $truststore:
    mode  => '0440',
    group => 'tomcat',
  }

  file { $artemis_dir:
    ensure => directory,
  }

  $artemis_client_common_names.each |$common_name| {
    certificates::artemis_certificate { $common_name:
      common_name => $common_name,
      dir         => $artemis_dir,
      ca_cert     => $ca_cert,
      ca_key      => $ca_key,
      require      => [File[$artemis_dir], Exec['Create CA certificate']]
    }
  }
}
