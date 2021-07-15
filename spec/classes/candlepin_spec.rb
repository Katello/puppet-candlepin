require 'spec_helper'

describe 'candlepin' do
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }

      describe 'default parameters' do
        let :params do
          {db_password: 'testpassword'}
        end

        it { is_expected.to compile.with_all_deps }

        # install
        it { is_expected.to contain_class('candlepin::install') }
        it { is_expected.to contain_package('candlepin').with_ensure('present') }
        it { is_expected.not_to contain_package('wget') }

        if facts[:os]['release']['major'] == '8'
          it { is_expected.to contain_package('pki-core').that_comes_before('Package[candlepin]') }
        else
          it { is_expected.not_to contain_package('pki-core') }
        end

        # config
        it { is_expected.to contain_class('candlepin::config') }
        it { is_expected.to contain_user('tomcat').with_ensure('present').with_groups([]) }
        it { is_expected.to contain_group('tomcat').with_ensure('present') }
        it do
          verify_concat_fragment_exact_contents(catalogue, 'General Config', [
            'candlepin.environment_content_filtering=true',
            'candlepin.auth.basic.enable=true',
            'candlepin.auth.trusted.enable=false',
            'candlepin.auth.oauth.enable=true',
            'candlepin.auth.oauth.consumer.candlepin.secret=candlepin',
            'candlepin.ca_key=/etc/candlepin/certs/candlepin-ca.key',
            'candlepin.ca_cert=/etc/candlepin/certs/candlepin-ca.crt',
            'candlepin.crl.file=/var/lib/candlepin/candlepin-crl.crl',
            'log4j.logger.org.hibernate.internal.SessionImpl=ERROR',
            'pinsetter.org.candlepin.pinsetter.tasks.ExpiredPoolsJob.schedule=0 0 0 * * ?',
            'pinsetter.org.candlepin.pinsetter.tasks.CertificateRevocationListTask.schedule=0 0 0 1 1 ?',
            'candlepin.audit.hornetq.config_path=/etc/candlepin/broker.xml',
          ])
        end
        it { is_expected.to contain_file('/etc/tomcat/tomcat.conf') }

        it do
          verify_exact_contents(catalogue, '/etc/tomcat/tomcat.conf', [
            'TOMCAT_CFG_LOADED="1"',
            'TOMCATS_BASE="/var/lib/tomcats/"',
            'JAVA_HOME="/usr/lib/jvm/jre"',
            'CATALINA_HOME="/usr/share/tomcat"',
            'CATALINA_TMPDIR="/var/cache/tomcat/temp"',
            'JAVA_OPTS="-Xms1024m -Xmx4096m"',
            'SECURITY_MANAGER="0"',
          ])
        end

        it do
          is_expected.to contain_file('/etc/candlepin/certs/candlepin-ca.key').
            with_group('tomcat').
            with_mode('0640').
            that_notifies('Service[tomcat]')
        end

        it do
          is_expected.to contain_file('/etc/candlepin/certs/candlepin-ca.crt').
            with_mode('0444').
            that_notifies('Service[tomcat]')
        end

        it do
          is_expected.to contain_file('/etc/candlepin/certs/keystore').
            with_group('tomcat').
            with_mode('0640').
            that_notifies('Service[tomcat]')
        end

        it do
          is_expected.to contain_file('/etc/candlepin/certs/truststore').
            with_group('tomcat').
            with_mode('0640').
            that_notifies('Service[tomcat]')
        end

        it { is_expected.to contain_file('/usr/share/tomcat/conf/login.config') }
        it { is_expected.to contain_file('/usr/share/tomcat/conf/cert-roles.properties') }
        it { is_expected.to contain_file('/usr/share/tomcat/conf/conf.d/jaas.conf') }
        it do
          is_expected.to contain_file('/usr/share/tomcat/conf/cert-users.properties').
            with_content("katelloUser=CN=ActiveMQ Artemis Client, OU=Artemis, O=ActiveMQ, L=AMQ, ST=AMQ, C=AMQ\n")
        end

        it { is_expected.to contain_file('/etc/candlepin/broker.xml') }

        it do
          is_expected.to contain_file('/etc/candlepin/broker.xml').
            with_content(/^            <acceptor name="stomp">tcp:\/\/localhost:61613\?protocols=STOMP;useEpoll=false;sslEnabled=true;trustStorePath=\/etc\/candlepin\/certs\/truststore;trustStorePassword=;keyStorePath=\/etc\/candlepin\/certs\/keystore;keyStorePassword=;needClientAuth=true<\/acceptor>/)
        end

        # database
        it { is_expected.not_to contain_class('candlepin::database::mysql') }
        it { is_expected.to contain_class('candlepin::database::postgresql') }
        it 'migrates the database' do
          is_expected.to contain_cpdb_create('candlepin')
            .that_subscribes_to(['Package[candlepin]', 'Concat[/etc/candlepin/candlepin.conf]'])
            .that_requires('Postgresql::Server::Db[candlepin]')
            .that_notifies('Service[tomcat]')
          is_expected.to contain_cpdb_update('candlepin')
            .that_subscribes_to(['Package[candlepin]', 'Concat[/etc/candlepin/candlepin.conf]'])
            .that_notifies('Service[tomcat]')
        end
        it { is_expected.to contain_postgresql__server__db('candlepin') }
        it { is_expected.to contain_postgresql__server__role('candlepin').that_comes_before('Postgresql::Server::Database[candlepin]') }

        it do
          verify_concat_fragment_exact_contents(catalogue, 'PostgreSQL Database Configuration', [
            'jpa.config.hibernate.dialect=org.hibernate.dialect.PostgreSQLDialect',
            'jpa.config.hibernate.connection.driver_class=org.postgresql.Driver',
            'jpa.config.hibernate.connection.url=jdbc:postgresql://localhost:5432/candlepin',
            'jpa.config.hibernate.hbm2ddl.auto=validate',
            'jpa.config.hibernate.connection.username=candlepin',
            'jpa.config.hibernate.connection.password=testpassword',
            'org.quartz.jobStore.misfireThreshold=60000',
            'org.quartz.jobStore.useProperties=false',
            'org.quartz.jobStore.dataSource=myDS',
            'org.quartz.jobStore.tablePrefix=QRTZ_',
            'org.quartz.jobStore.class=org.quartz.impl.jdbcjobstore.JobStoreTX',
            'org.quartz.jobStore.driverDelegateClass=org.quartz.impl.jdbcjobstore.PostgreSQLDelegate',
            'org.quartz.dataSource.myDS.driver=org.postgresql.Driver',
            'org.quartz.dataSource.myDS.URL=jdbc:postgresql://localhost:5432/candlepin',
            'org.quartz.dataSource.myDS.user=candlepin',
            'org.quartz.dataSource.myDS.password=testpassword',
            'org.quartz.dataSource.myDS.maxConnections=5',
          ])
        end

        # service
        it { is_expected.to contain_class('candlepin::service') }
        it { is_expected.to contain_service('tomcat') }
        it { is_expected.not_to contain_exec('cpinit') }
        it { is_expected.to contain_service('tomcat').with_ensure('running') }
      end

      describe 'selinux' do
        describe 'on' do
          let(:facts) { override_facts(super(), os: {selinux: {enabled: true}}) }

          it { is_expected.to compile.with_all_deps }
          it { is_expected.to contain_selboolean('candlepin_can_bind_activemq_port').that_requires('Package[candlepin-selinux]') }
          if facts[:os]['release']['major'] == '8'
            it { is_expected.to contain_package('candlepin-selinux').that_requires('Package[pki-core]') }
          else
            it { is_expected.to contain_package('candlepin-selinux') }
          end
        end

        describe 'off' do
          let(:facts) { override_facts(super(), os: {selinux: {enabled: false}}) }

          it { is_expected.to compile.with_all_deps }
          it { is_expected.not_to contain_selboolean('candlepin_can_bind_activemq_port') }
          it { is_expected.not_to contain_package('candlepin-selinux') }
        end
      end

      describe 'with custom adapter module' do
        let :params do
          {adapter_module: 'my.custom.adapter_module'}
        end

        it { is_expected.to compile.with_all_deps }

        it do
          is_expected.to contain_concat__fragment('General Config').
            with_content(/^module.config.adapter_module=my.custom.adapter_module$/)
        end
      end

      describe 'with ssl_port' do
        let :params do
          {ssl_port: 9070}
        end

        it { is_expected.to compile.with_all_deps }
        it do
          is_expected.to contain_file("/etc/tomcat/server.xml").
            with_content(/^    <Connector port="9070"/).
            with_content(/^               address="localhost"/).
            with_content(/^               protocol="HTTP\/1.1"/).
            with_content(/^               SSLEnabled="true"/)
        end
      end

      describe 'with tls_versions' do
        let :params do
          {tls_versions: ['1.2', '1.3']}
        end

        it { is_expected.to compile.with_all_deps }
        it do
          is_expected.to contain_file("/etc/tomcat/server.xml").
            with_content(/sslProtocol="TLSv1.2,TLSv1.3"/).
            with_content(/sslEnabledProtocols="TLSv1.2,TLSv1.3"/)
        end
      end

      describe 'with java params' do
        let :params do
          {
            java_package: 'java-11-openjdk',
            java_home: '/usr/lib/jvm/jre-11'
          }
        end

        it { is_expected.to contain_package('java-11-openjdk').that_comes_before('Service[tomcat]') }

        it do
          is_expected.to contain_file("/etc/tomcat/tomcat.conf").
            with_content(/JAVA_HOME="\/usr\/lib\/jvm\/jre-11"/)
        end
      end

      describe 'with mysql' do
        let :params do
          {
            db_type: 'mysql',
            db_password: 'testpassword',
          }
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.not_to contain_class('candlepin::database::postgresql') }
        it { is_expected.to contain_class('candlepin::database::mysql') }
        it do
          verify_concat_fragment_exact_contents(catalogue, 'Mysql Database Configuration', [
            'jpa.config.hibernate.dialect=org.hibernate.dialect.MySQLDialect',
            'jpa.config.hibernate.connection.driver_class=com.mysql.jdbc.Driver',
            'jpa.config.hibernate.connection.url=jdbc:mysql://localhost:3306/candlepin',
            'jpa.config.hibernate.hbm2ddl.auto=validate',
            'jpa.config.hibernate.connection.username=candlepin',
            'jpa.config.hibernate.connection.password=testpassword',
            'org.quartz.jobStore.misfireThreshold=60000',
            'org.quartz.jobStore.useProperties=false',
            'org.quartz.jobStore.dataSource=myDS',
            'org.quartz.jobStore.tablePrefix=QRTZ_',
            'org.quartz.jobStore.class=org.quartz.impl.jdbcjobstore.JobStoreTX',
            'org.quartz.jobStore.driverDelegateClass=org.quartz.impl.jdbcjobstore.StdJDBCDelegate',
            'org.quartz.dataSource.myDS.driver=com.mysql.jdbc.Driver',
            'org.quartz.dataSource.myDS.URL=jdbc:mysql://localhost:3306/candlepin',
            'org.quartz.dataSource.myDS.user=candlepin',
            'org.quartz.dataSource.myDS.password=testpassword',
            'org.quartz.dataSource.myDS.maxConnections=5',
          ])
        end
      end

      describe 'with enable_hbm2ddl_validate = false' do
        let :params do
          {enable_hbm2ddl_validate: false}
        end

        context 'with postgresql' do
          it { is_expected.to compile.with_all_deps }
          it do
            is_expected.to contain_concat__fragment('PostgreSQL Database Configuration').
              without_content(/jpa.config.hibernate.hbm2ddl.auto=validate/)
          end
        end

        context 'with mysql' do
          let(:params) { super().merge(db_type: 'mysql') }
          it { is_expected.to compile.with_all_deps }
          it do
            is_expected.to contain_concat__fragment('Mysql Database Configuration').
              without_content(/jpa.config.hibernate.hbm2ddl.auto=validate/)
          end
        end
      end

      context 'with run_init false' do
        let :params do
          {run_init: true}
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_service('tomcat') }
        it do
          is_expected.to contain_exec('cpinit')
            .that_requires(['Package[wget]', 'Service[tomcat]'])
            .that_subscribes_to(['Concat[/etc/candlepin/candlepin.conf]', 'File[/etc/tomcat/server.xml]'])
        end
      end

      describe 'notify' do
        let :pre_condition do
          <<-EOS
          exec { 'notification':
            command => '/bin/true',
            notify  => Class['candlepin'],
          }

          exec { 'dependency':
            command => '/bin/true',
            require => Class['candlepin'],
          }
          EOS
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_exec('notification').that_notifies('Service[tomcat]') }
        it { is_expected.to contain_exec('dependency').that_requires('Service[tomcat]') }
      end

      describe 'with manage_certificate_files false' do
        let(:params) do
          {manage_certificate_files: false}
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.not_to contain_file('/etc/candlepin/certs/candlepin-ca.key') }
        it { is_expected.not_to contain_file('/etc/candlepin/certs/candlepin-ca.crt') }
        it { is_expected.not_to contain_file('/etc/candlepin/certs/keystore') }
        it { is_expected.not_to contain_file('/etc/candlepin/certs/truststore') }
      end
    end
  end
end
