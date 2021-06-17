# Candlepin Service and Initialization
#
# @api private
class candlepin::service {
  assert_private()

  service { 'tomcat':
    ensure     => running,
    enable     => true,
    hasstatus  => true,
    hasrestart => true,
  }

  if $candlepin::run_init {
    exec { 'cpinit':
      # tomcat startup is slow - try multiple times (the initialization service is idempotent)
      command => "/usr/bin/wget --no-check-certificate --no-proxy --timeout=30 --tries=40 --wait=20 --retry-connrefused -qO- https://localhost:${candlepin::ssl_port}/candlepin/admin/init > /var/log/candlepin/cpinit.log 2>&1 && touch /var/lib/candlepin/cpinit_done",
      require => [Package['wget'], Service['tomcat']],
      creates => '/var/lib/candlepin/cpinit_done',
      # timeout is roughly "wait" * "tries" from above
      timeout => 800,
    }
  }
}
