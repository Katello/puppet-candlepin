define certificates::artemis_certificate (
  $dir,
  $common_name,
  $ca_cert,
  $ca_key,
) {

  $key = "${dir}/${common_name}.key"
  $req = "${dir}/${common_name}.req"
  $certificate = "${dir}/${common_name}.crt"

  exec { "Create ${common_name} artemis client key":
    command => "/usr/bin/openssl genrsa -out '${key}' 2048",
    creates => $key,
  } ->
  exec { "Create ${common_name} artemis client certificate signing request":
    command => "/usr/bin/openssl req -new -key '${key}' -out '${req}' -subj '/C=US/ST=North Carolina/CN=${common_name}'",
    creates => $certificate,
  } ->
  exec { "Create ${common_name} artemis client certificate":
    command => "/usr/bin/openssl x509 -req -in '${req}' -out '${certificate}' -CA '${ca_cert}' -CAkey '${ca_key}' -set_serial 1",
    creates => $certificate,
  }

}
