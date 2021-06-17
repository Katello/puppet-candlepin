# Candlepin Database Setup using Mysql
#
# @api private
class candlepin::database::mysql (
  $candlepin_conf_file = $candlepin::candlepin_conf_file,
  $db_dialect = 'org.hibernate.dialect.MySQLDialect',
  $db_quartz_dialect = 'org.quartz.impl.jdbcjobstore.StdJDBCDelegate',
  $db_driver = 'com.mysql.jdbc.Driver',
  $db_type = $candlepin::db_type,
  $db_host = $candlepin::db_host,
  $db_port = pick($candlepin::db_port, 3306),
  $db_name = $candlepin::db_name,
  $db_user = $candlepin::db_user,
  $db_password = $candlepin::db_password,
  $enable_hbm2ddl_validate = $candlepin::enable_hbm2ddl_validate,
) {
  assert_private()

  concat::fragment { 'Mysql Database Configuration':
    target  => $candlepin_conf_file,
    content => template('candlepin/_candlepin_database.conf.erb'),
  }
}
