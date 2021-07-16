# Manage a Candlepin server
#
# @param oauth_key
#   The OAuth key for talking to the candlepin API
#
# @param oauth_secret
#   The OAuth secret for talking to the candlepin API
#
# @param manage_db
#   Whether a database should be installed, this includes db creation and user
#
# @param init_db
#   Whether a database should be initialised.
#
# @param db_type
#   The type of database Candlepin will be connecting too.
#
# @param db_host
#   Hostname of database server.
#
# @param db_port
#   Port the database listens on. Only needs to be provided if different from
#   standard port of the :db_type.
#
# @param db_ssl
#   Boolean indicating if the connection to the database should be over an SSL
#   connection.
#
# @param db_ssl_verify
#   Boolean indicating if the SSL connection to the database should be verified
#
# @param db_name
#   The name of the Candlepin database
#
# @param db_user
#   The Candlepin database username
#
# @param db_password
#   The Candlepin database password
#
# @param crl_file
#   The Certificate Revocation File for Candlepin
#
# @param user_groups
#   The user groups for the Candlepin tomcat user
#
# @param log_dir
#   Directory for Candlepin logs
#
# @param env_filtering_enabled
#   If subscription filtering is done on a per environment basis
#
# @param keystore_password
#   Password for keystore being used with Tomcat
#
# @param truststore_password
#   Password for truststore being used with Tomcat and Artemis
#
# @param ca_key
#   CA key file to use
#
# @param ca_cert
#   CA certificate file to use
#
# @param tomcat_ssl_cert
#   The certificate to use for Tomcat server
#
# @param tomcat_ssl_key
#   The private key to use for Tomcat server
#
# @param ca_key_password
#   CA key password
#
# @param ciphers
#   Allowed ciphers for ssl connection
#
# @param tls_versions
#   Allowed versions of TLS, for example 1.1, 1.2, etc
#
# @param version
#   Version of Candlepin to install
#
# @param java_package
#   Use in conjunction with java_home to specify the JVM used by Tomcat
#
# @param wget_version
#   Version of wget to install
#
# @param run_init
#   If the init api should be called on Candlepin
#
# @param adapter_module
#   Candlepin adapter implementations to inject into the java runtime
#
# @param enable_basic_auth
#   Whether to enable HTTP basic auth
#
# @param enable_trusted_auth
#   Whether to enable trusted auth
#
# @param consumer_system_name_pattern
#   Regex that consistutes a valid consumer name
#
# @param enable_hbm2ddl_validate
#   If true will perform a schema check to ensure compliance with the models.
#   Disabling this feature may be required if modifications are required to schema
#
# @param ssl_port
#   Port to deploy SSL enabled Tomcat server on
#
# @param host
#   Host to deploy Tomcat server on; defaults to localhost
#
# @param candlepin_conf_file
#   Configuration file location for candlepin
#
# @param tomcat_base
#   In new-style instances, if CATALINA_BASE isn't specified, it will be
#   constructed by joining TOMCATS_BASE and NAME.
#
# @param java_home
#   Where your java installation lives
#
# @param catalina_home
#   Where your tomcat installation lives
#
# @param catalina_tmpdir
#   System-wide tmp
#
# @param java_opts
#   Java Parameters
#
# @param lang
#   Tomcat locale setting
#
# @param security_manager
#   Run tomcat under the Java Security Manager
#
# @param shutdown_wait
#   Time to wait in seconds, before killing process
#
# @param expired_pools_schedule
#   Quartz schedule notation for how often to run the ExpiredPoolsJob
#
# @param certificate_revocation_list_task_schedule
#   Quartz schedule notation for how often to run CRL generation
#
# @param artemis_port
#   Port to expose Artemis on
#
# @param artemis_host
#   Host address to have Artemis listen on; defaults to localhost
#
# @param artemis_client_dn
#   Full DN for the client certificate used to talk to Artemis
#
# @param artemis_client_certificate
#   Path to the client certificate used to talk to Artemis
#
# @param broker_config_file
#   Config file for Artemis
#
# @param user
#   User under which Candlepin will run
#
# @param group
#   Primary group for the Candlepin user
#
class candlepin (
  Boolean $manage_db = true,
  Boolean $init_db = true,
  Enum['postgresql','mysql'] $db_type = 'postgresql',
  Stdlib::Host $db_host = 'localhost',
  Optional[Stdlib::Port] $db_port = undef,
  Boolean $db_ssl = false,
  Boolean $db_ssl_verify = true,
  String $db_name = 'candlepin',
  String $db_user = 'candlepin',
  String $db_password = $candlepin::params::db_password,
  Stdlib::Absolutepath $crl_file = '/var/lib/candlepin/candlepin-crl.crl',
  Variant[Array[String], String] $user_groups = [],
  Stdlib::Absolutepath $log_dir = '/var/log/candlepin',
  String $oauth_key = 'candlepin',
  String $oauth_secret = 'candlepin',
  Boolean $env_filtering_enabled = true,
  Optional[String] $keystore_password = $candlepin::params::keystore_password,
  Optional[String] $truststore_password = $candlepin::params::truststore_password,
  Stdlib::Absolutepath $ca_key = undef,
  Stdlib::Absolutepath $ca_cert = undef,
  Stdlib::Absolutepath $tomcat_ssl_cert = undef,
  Stdlib::Absolutepath $tomcat_ssl_key = undef,
  Optional[String] $ca_key_password = undef,
  Array[String] $ciphers = $candlepin::params::ciphers,
  Array[String] $tls_versions = ['1.2'],
  Optional[String[1]] $java_package = undef,
  String $version = 'present',
  String $wget_version = 'present',
  Boolean $run_init = false,
  Optional[String] $adapter_module = undef,
  Boolean $enable_hbm2ddl_validate = true,
  Boolean $enable_basic_auth = true,
  Boolean $enable_trusted_auth = false,
  Optional[String] $consumer_system_name_pattern = undef,
  Stdlib::Port $ssl_port = 8443,
  Stdlib::Host $host = 'localhost',
  Stdlib::Absolutepath $candlepin_conf_file = '/etc/candlepin/candlepin.conf',
  Stdlib::Absolutepath $tomcat_base = '/var/lib/tomcats/',
  Stdlib::Absolutepath $java_home = '/usr/lib/jvm/jre',
  Stdlib::Absolutepath $catalina_home = '/usr/share/tomcat',
  Stdlib::Absolutepath $catalina_tmpdir = '/var/cache/tomcat/temp',
  String $java_opts = '-Xms1024m -Xmx4096m',
  Optional[String] $lang = undef,
  Boolean $security_manager = false,
  Optional[Integer[0]] $shutdown_wait = undef,
  String $expired_pools_schedule = '0 0 0 * * ?',
  String $certificate_revocation_list_task_schedule = '0 0 0 1 1 ?',
  Stdlib::Host $artemis_host = 'localhost',
  Stdlib::Port $artemis_port = 61613,
  Variant[Deferred, String] $artemis_client_dn = 'CN=ActiveMQ Artemis Client, OU=Artemis, O=ActiveMQ, L=AMQ, ST=AMQ, C=AMQ',
  Stdlib::Absolutepath $artemis_client_certificate = undef,
  Stdlib::Absolutepath $broker_config_file = '/etc/candlepin/broker.xml',
  String $user = 'tomcat',
  String $group = 'tomcat',
) inherits candlepin::params {

  contain candlepin::service

  $truststore = '/etc/candlepin/certs/truststore'
  $truststore_password_path = '/etc/candlepin/certs/truststore_password-file'

  $keystore = '/etc/candlepin/certs/keystore'
  $keystore_password_path = '/etc/candlepin/certs/keystore_password-file'

  Anchor <| title == 'candlepin::repo' |> ->
  class { 'candlepin::install': } ~>
  class { 'candlepin::config':  } ~>
  class { 'candlepin::artemis':  } ~>
  class { "candlepin::database::${candlepin::db_type}": } ~>
  Class['candlepin::service']

}
