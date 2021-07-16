# Configuration for Artemis
#
# @api private
class candlepin::certificates {
  assert_private()

  $config_dir = '/etc/candlepin'

  $ca_key = "${config_dir}/certs/candlepin-ca.key"
  $ca_cert = "${config_dir}/certs/candlepin-ca.crt"
  $ca_key_password = $candlepin::ca_key_password
  $crl_file = $candlepin::crl_file

  file { $ca_cert:
    ensure => file,
    source => $candlepin::ca_cert,
    mode   => '0440',
    owner  => 'root',
    group  => $candlepin::group,
  }

  file { $ca_key:
    ensure    => file,
    source    => $candlepin::ca_key,
    mode      => '0440',
    owner     => 'root',
    group     => $candlepin::group,
    show_diff => false,
  }

  file { $candlepin::truststore_password_path:
    ensure    => file,
    content   => $candlepin::truststore_password,
    owner     => 'root',
    group     => $candlepin::group,
    mode      => '0440',
    show_diff => false,
  }

  truststore { $candlepin::truststore:
    ensure        => present,
    password_file => $candlepin::truststore_password_path,
    owner         => 'root',
    group         => $candlepin::group,
    mode          => '0640',
  }

  truststore_certificate { "${candlepin::truststore}:ca":
    ensure        => present,
    password_file => $candlepin::truststore_password_path,
    certificate   => $candlepin::ca_cert,
  }

  truststore_certificate { "${candlepin::truststore}:artemis-client":
    ensure        => present,
    password_file => $candlepin::truststore_password_path,
    certificate   => $candlepin::artemis_client_certificate,
  }

  file { $candlepin::keystore_password_path:
    ensure    => file,
    content   => $candlepin::keystore_password,
    owner     => 'root',
    group     => $candlepin::group,
    mode      => '0440',
    show_diff => false,
  }

  keystore { $candlepin::keystore:
    ensure        => present,
    password_file => $candlepin::truststore_password_path,
    owner         => 'root',
    group         => $candlepin::group,
    mode          => '0640',
  }

  keystore_certificate { "${candlepin::keystore}:tomcat":
    ensure        => present,
    password_file => $candlepin::keystore_password_path,
    certificate   => $candlepin::tomcat_ssl_cert,
    private_key   => $candlepin::tomcat_ssl_key,
    ca            => $candlepin::ca_cert,
  }
}

