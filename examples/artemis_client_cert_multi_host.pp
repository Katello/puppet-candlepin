#
# Create certificates then install candlepin
#

$first_server_fqdn = 'example01.example.com'
$second_server_fqdn = 'example02.example.com'

class { 'certificates':
  artemis_client_common_names => [$first_server_fqdn, $second_server_fqdn],
} ->
class { 'candlepin':
  ca_key                              => $certificates::ca_key,
  ca_cert                             => $certificates::ca_cert,
  keystore_file                       => $certificates::keystore,
  keystore_password                   => $certificates::keystore_password,
  truststore_file                     => $certificates::truststore,
  truststore_password                 => $certificates::truststore_password,
  java_package                        => 'java-11-openjdk',
  java_home                           => '/usr/lib/jvm/jre-11',
  artemis_client_certificate_user_map => {
    "${certificates::artemis_dir}/${first_server_fqdn}.crt"  => $first_server_fqdn,
    "${certificates::artemis_dir}/${second_server_fqdn}.crt" => $second_server_fqdn,
  },
}
