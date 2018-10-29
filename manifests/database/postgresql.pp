# Candlepin Database Setup using Postgresql
#
# @api private
class candlepin::database::postgresql(

  $candlepin_conf_file     = $::candlepin::candlepin_conf_file,
  $db_dialect              = 'org.hibernate.dialect.PostgreSQLDialect',
  $db_quartz_dialect       = 'org.quartz.impl.jdbcjobstore.PostgreSQLDelegate',
  $db_driver               = 'org.postgresql.Driver',
  $manage_db               = $::candlepin::manage_db,
  $init_db                 = $::candlepin::init_db,
  $db_type                 = $::candlepin::db_type,
  $db_host                 = $::candlepin::db_host,
  $db_port                 = pick($::candlepin::db_port, 5432),
  $db_ssl                  = $::candlepin::db_ssl,
  $db_ssl_verify           = $::candlepin::db_ssl_verify,
  $db_name                 = $::candlepin::db_name,
  $db_user                 = $::candlepin::db_user,
  $db_password             = $::candlepin::db_password,
  $enable_hbm2ddl_validate = $::candlepin::enable_hbm2ddl_validate,
  $log_dir                 = $::candlepin::log_dir,

) {
  assert_private()

  concat::fragment{'PostgreSQL Database Configuration':
    target  => $candlepin_conf_file,
    content => template('candlepin/_candlepin_database.conf.erb'),
  }

  if $manage_db {
    # Prevents errors if run from /root etc.
    Postgresql_psql {
      cwd => '/',
    }

    include ::postgresql::client, ::postgresql::server
    postgresql::server::db { $db_name:
      user     => $db_user,
      password => postgresql_password($db_user, $db_password),
      encoding => 'utf8',
      locale   => 'en_US.utf8',
    }
  }

  if $init_db {
    $ssl_verify_options = $db_ssl_verify ? {
      false => '&sslfactory=org.postgresql.ssl.NonValidatingFactory',
      default => ''
    }

    $ssl_options = $db_ssl ? {
      true  => "?ssl=true${ssl_verify_options}",
      default => ''
    }

    exec { 'cpdb':
      path    => '/usr/share/candlepin:/bin',
      command => "cpdb --create \
                       --schema-only \
                       --dbhost=${db_host} \
                       --dbport=${db_port} \
                       --database='${db_name}${ssl_options}' \
                       --user='${db_user}'  \
                       --password='${db_password}' \
                       >> ${log_dir}/cpdb.log \
                       2>&1 && touch /var/lib/candlepin/cpdb_done",
      creates => '/var/lib/candlepin/cpdb_done',
      before  => Service['tomcat'],
      require => Concat['/etc/candlepin/candlepin.conf'],
    }
    # if both manage_db and init_db enforce order of resources
    if $manage_db {
      Postgresql::Server::Db[$db_name] -> Exec['cpdb']
    }
  }
}
