Puppet::Type.newtype(:artemis_cert_users) do
  desc 'Manages a CertificateLoginModule user configuration file for Artemis'

  ensurable

  newparam(:path, :namevar => true)

  def exists?
    self[:ensure] == :present
  end

  newparam(:certificate_users) do
    desc "A map of certificates to users from which the client distinguished name will be calculated."
    isrequired
  end

  newparam(:username) do
    desc "The username to associate with the distinguished name."
    isrequired
  end

  newparam(:owner, parent: Puppet::Type::File::Owner) do
    desc "Specifies the owner of the file. Valid options: a string containing a username or integer containing a uid."
  end

  newparam(:group, parent: Puppet::Type::File::Group) do
    desc "Specifies a permissions group for the file. Valid options: a string containing a group name or integer containing a gid."
  end

  newparam(:mode, parent: Puppet::Type::File::Mode) do
    desc "Specifies the permissions mode of the file. Valid options: a string containing a permission mode value in octal notation."
  end

  def should_content
    content = ''

    self[:certificate_users].each do |certificate, user|
      begin
        cert = OpenSSL::X509::Certificate.new(File.read(certificate))
        subject = cert.subject.to_s(OpenSSL::X509::Name::RFC2253)
        subject = subject.split(',').join(', ')
        content += "#{user}=#{subject}\n"
      rescue OpenSSL::X509::CertificateError, Errno::ENOENT => e
        Puppet.err("The file at #{self[:path]} could not be read or is not a valid x509 certificate: #{e}")
        nil
      end
    end

    content
  end

  def generate
    file_opts = {
      ensure: (self[:ensure] == :absent) ? :absent : :file,
    }

    [:path,
     :owner,
     :group,
     :mode].each do |param|
      file_opts[param] = self[param] unless self[param].nil?
    end

    excluded_metaparams = [:before, :notify, :require, :subscribe, :tag]

    Puppet::Type.metaparams.each do |metaparam|
      unless self[metaparam].nil? || excluded_metaparams.include?(metaparam)
        file_opts[metaparam] = self[metaparam]
      end
    end

    [Puppet::Type.type(:file).new(file_opts)]
  end

  def eval_generate
    content = should_content

    unless content.nil?
      catalog.resource("File[#{self[:path]}]")[:content] = content
    end

    [catalog.resource("File[#{self[:path]}]")]
  end
end
