# Candlepin params
#
# @api private
class candlepin::params {
  # this comes from keystore
  $db_password = extlib::cache_data('foreman_cache_data', 'candlepin_db_password', extlib::random_password(32))

  $truststore_password = extlib::cache_data('candlepin', 'truststore_password', extlib::random_password(32))
  $keystore_password = extlib::cache_data('candlepin', 'keystore_password', extlib::random_password(32))

  $keystore_type = 'PKCS12'

  $ciphers = [
    'SSL_RSA_WITH_3DES_EDE_CBC_SHA',
    'TLS_RSA_WITH_AES_256_CBC_SHA',
    'TLS_ECDH_ECDSA_WITH_AES_128_CBC_SHA',
    'TLS_ECDH_ECDSA_WITH_AES_256_CBC_SHA',
    'TLS_ECDH_RSA_WITH_3DES_EDE_CBC_SHA',
    'TLS_ECDH_RSA_WITH_AES_128_CBC_SHA',
    'TLS_ECDH_RSA_WITH_AES_256_CBC_SHA',
    'TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA',
  ]
}
