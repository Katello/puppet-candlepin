Puppet::Type.newtype(:cpdb_update) do
  desc 'Runs cpdb update command to migrate the database'

  ensurable

  newparam(:db_name, namevar: true)

  newparam(:db_host) do
    desc 'Database host'
  end

  newparam(:db_port) do
    desc 'Database port'
  end

  newparam(:ssl_options) do
    desc 'SSL options if necessary for connecting to the database'
  end

  newparam(:db_user) do
    desc 'User to connect to the database with'
  end

  newparam(:db_password) do
    desc 'Password of the database user'
  end

  autorequire(:concat) do
    ['/etc/candlepin/candlepin.conf']
  end

  autorequire(:cpdb_create) do
    [self[:db_name]]
  end
end
