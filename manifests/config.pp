# Configuration for Candlepin
#
# @api private
class candlepin::config {
  assert_private()

  contain candlepin::certificates

  $tomcat_config_dir = '/etc/tomcat'

  user { $candlepin::user:
    ensure => present,
    gid    => $candlepin::group,
    groups => $candlepin::user_groups,
  }

  group { $candlepin::group:
    ensure => present,
  }

  concat::fragment { 'General Config':
    target  => $candlepin::candlepin_conf_file,
    content => template('candlepin/candlepin.conf.erb'),
  }

  concat{ $candlepin::candlepin_conf_file:
    mode  => '0600',
    owner => $candlepin::user,
    group => $candlepin::group,
  }

  file { "${tomcat_config_dir}/server.xml":
    ensure  => file,
    content => template('candlepin/tomcat/server.xml.erb'),
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
  }

  file { "${tomcat_config_dir}/tomcat.conf":
    ensure  => file,
    content => template('candlepin/tomcat/tomcat.conf.erb'),
    mode    => '0644',
    owner   => 'root',
    group   => $candlepin::group,
  }
}
