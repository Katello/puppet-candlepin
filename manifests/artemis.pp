# Configuration for Artemis
#
# @api private
class candlepin::artemis {
  assert_private()

  $artemis_cert_dir = '/etc/candlepin/certs/artemis'

  file { $candlepin::broker_config_file:
    ensure  => file,
    content => template('candlepin/broker.xml.erb'),
    mode    => '0640',
    owner   => $candlepin::user,
    group   => $candlepin::group,
  }

  file { "${candlepin::catalina_home}/conf/login.config":
    ensure  => file,
    content => file('candlepin/tomcat/login.config'),
    mode    => '0640',
    owner   => $candlepin::user,
    group   => $candlepin::group,
  }

  if $candlepin::artemis_client_certificate_user_map {
    file { $artemis_cert_dir:
      ensure => directory,
      owner  => $candlepin::user,
      group  => $candlepin::group,
    }

    $candlepin::artemis_client_certificate_user_map.each |$certificate, $user| {
      file { "${artemis_cert_dir}/${user}.crt":
        ensure => file,
        source => $certificate,
        owner  => $candlepin::user,
        group  => $candlepin::group,
        mode   => '0640',
      }
    }

    artemis_cert_users { "${candlepin::catalina_home}/conf/cert-users.properties":
      ensure            => present,
      certificate_users => $candlepin::artemis_client_certificate_user_map,
      mode              => '0640',
      owner             => $candlepin::user,
      group             => $candlepin::group,
    }
  } elsif $candlepin::artemis_client_dn {
    file { "${candlepin::catalina_home}/conf/cert-users.properties":
      ensure  => file,
      content => Deferred('inline_epp', ["katelloUser=<%= \$artemis_client_dn %>\n", {'artemis_client_dn' => $candlepin::artemis_client_dn}]),
      mode    => '0640',
      owner   => $candlepin::user,
      group   => $candlepin::group,
    }
  }

  if $candlepin::artemis_client_dn {
    $artemis_users = ['katelloUser']
  } elsif $candlepin::artemis_client_certificate_user_map {
    $artemis_users = $candlepin::artemis_client_certificate_user_map.map |$certificate, $user| {
      $user
    }
  }

  if $candlepin::artemis_client_dn or $candlepin::artemis_client_certificate_user_map {
    file { "${candlepin::catalina_home}/conf/cert-roles.properties":
      ensure  => file,
      content => template('candlepin/tomcat/cert-roles.properties.erb'),
      mode    => '0640',
      owner   => $candlepin::user,
      group   => $candlepin::group,
    }
  }

  file { "${candlepin::catalina_home}/conf/conf.d/jaas.conf":
    ensure  => file,
    content => file('candlepin/tomcat/jaas.conf'),
    mode    => '0640',
    owner   => $candlepin::user,
    group   => $candlepin::group,
  }

  if $facts['os']['selinux']['enabled'] {
    selboolean { 'candlepin_can_bind_activemq_port':
      value      => 'on',
      persistent => true,
    }
  }
}
