Puppet::Type.type(:cpdb_create).provide(:cpdb_create) do
  commands cpdb: '/usr/share/candlepin/cpdb'

  def create
    create_database
    write_done_file
  end

  def exists?
    File.exist?(done_file)
  end

  private

  def create_database
    cpdb(
      '--create',
      '--schema-only',
      "--dbhost=#{resource[:db_host]}",
      "--dbport=#{resource[:db_port]}",
      "--database=#{resource[:db_name]}#{resource[:ssl_options]}",
      "--user=#{resource[:db_user]}",
      "--password=#{resource[:db_password]}",
    )
  end

  def done_file
    '/var/lib/candlepin/.puppet-candlepin-cpdb-create-done'
  end

  def write_done_file
    File.open(done_file, 'w') do |file|
      file.write(Time.now)
    end
  end
end
