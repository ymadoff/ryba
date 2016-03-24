
# Ambari Server Install

    # util = require 'util'
    # misc = require 'mecano/lib/misc'
    # each = require 'each'
    # ini = require 'ini'
    # url = require 'url'
    # builder = require 'xmlbuilder'
     
    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'masson/commons/java'
    # module.exports.push 'masson/commons/mysql_client'
    # module.exports.push require('./index').configure
 
See the documentation about [Software Requirements][sr].

## Package

Install Ambari server package.

    module.exports.push header: 'Ambari Server # Package', timeout: -1, handler: ->
      @service
        name: 'ambari-server'
        startup: true

## Repository

Declare the Ambari custom repository.

    module.exports.push header: 'Ambari Server # Repo', handler: ->
      {ambari_server} = @config.ryba
      @download
        source: ambari_server.repo
        destination: '/etc/yum.repos.d/ambari.repo'
      @execute
        cmd: "yum clean metadata; yum update -y"
        if: -> @status -1

## Database

Prepare the Ambari Database

    module.exports.push header: 'Ambari Server # Database', handler: ->
      {ambari_server, db_admin} = @config.ryba
      mysql_exec = "#{db_admin.path} -u#{db_admin.username} -p#{db_admin.password} -h#{db_admin.host} -P#{db_admin.port} "
      db =
        name: ambari_server.config['server.jdbc.database_name']
        user: ambari_server.config['server.jdbc.user.name']
        password: ambari_server.database_password

Password is stored inside a file which location is referenced by the property
"server.jdbc.user.passwd" in the configuration file.

      @write
        destination: ambari_server.config['server.jdbc.user.passwd']
        content: ambari_server.database_password
        backup: true
        mode: 0o0660

Create the database hosting the Ambari data with restrictive user permissions.

      @execute
        cmd: """
        #{mysql_exec} -e "
        create database #{db.name};
        grant all privileges on #{db.name}.* to '#{db.user}'@'localhost' identified by '#{db.password}';
        grant all privileges on #{db.name}.* to '#{db.user}'@'%' identified by '#{db.password}';
        flush privileges;
        "
        """
        unless_exec: "#{mysql_exec} -e 'use #{db.name}'"

Load the database with initial data

      @execute
        cmd: """
        #{mysql_exec} #{db.name} < /var/lib/ambari-server/resources/Ambari-DDL-MySQL-CREATE.sql
        """
        if_exec: "[ `#{mysql_exec} -B -N -e 'use #{db.name}; show tables' | wc -l` == '0' ]"
 
## Configuration

Merge used defined configuration. This could be used to set up 
LDAP or Active Directory Authentication.

    module.exports.push header: 'Ambari Server # Config', ->
      {ambari_server, db_admin} = @config.ryba
      db =
        name: ambari_server.config['server.jdbc.database_name']
        user: ambari_server.config['server.jdbc.user.name']
        password: ambari_server.database_password
      # @write
      #   destination: '/etc/ambari-server/conf/ambari.properties'
      #   content: """
      #   server.jdbc.rca.driver=org.postgresql.Driver
      #   jdk1.7.dest-file=jdk-7u67-linux-x64.tar.gz
      #   views.request.connect.timeout.millis=5000
      #   server.jdbc.rca.url=jdbc:postgresql://{fqdn}:5432/ambari
      #   agent.package.install.task.timeout=1800
      #   server.connection.max.idle.millis=900000
      #   bootstrap.script=/usr/lib/python2.6/site-packages/ambari_server/bootstrap.py
      #   server.version.file=/var/lib/ambari-server/resources/version
      #   views.http.strict-transport-security=max-age=31536000
      #   recovery.type=AUTO_START
      #   api.authenticate=true
      #   http.strict-transport-security=max-age=31536000
      #   server.jdbc.driver=org.postgresql.Driver
      #   server.persistence.type=remote
      #   jdk1.8.jcpol-url=http://public-repo-1.hortonworks.com/ARTIFACTS/jce_policy-8.zip
      #   jdk1.8.dest-file=jdk-8u60-linux-x64.tar.gz
      #   rolling.upgrade.skip.packages.prefixes=
      #   common.services.path=/var/lib/ambari-server/resources/common-services
      #   http.x-frame-options=DENY
      #   webapp.dir=/usr/lib/ambari-server/web
      #   jce.download.supported=true
      #   agent.threadpool.size.max=25
      #   recovery.lifetime_max_count=1024
      #   jdk1.8.re=(jdk.*)/jre
      #   ambari.python.wrap=ambari-python-wrap
      #   ambari-server.user=root
      #   jdk1.8.url=http://public-repo-1.hortonworks.com/ARTIFACTS/jdk-8u60-linux-x64.tar.gz
      #   jdk1.7.url=http://public-repo-1.hortonworks.com/ARTIFACTS/jdk-7u67-linux-x64.tar.gz
      #   server.jdbc.user.name=ambari
      #   server.jdbc.port=5432
      #   server.os_family=redhat6
      #   java.home=/usr/java/default
      #   server.jdbc.postgres.schema=ambari
      #   user.inactivity.timeout.default=0
      #   java.releases=jdk1.8,jdk1.7
      #   server.jdbc.hostname={fqdn}.fr
      #   skip.service.checks=false
      #   shared.resources.dir=/usr/lib/ambari-server/lib/ambari_commons/resources
      #   jdk.download.supported=true
      #   recommendations.dir=/var/run/ambari-server/stack-recommendations
      #   ulimit.open.files=10000
      #   rolling.upgrade.min.stack=HDP-2.2
      #   jdk1.8.desc=Oracle JDK 1.8 + Java Cryptography Extension (JCE) Policy Files 8
      #   server.tmp.dir=/var/lib/ambari-server/data/tmp
      #   server.os_type=centos6
      #   server.jdbc.rca.user.passwd=/etc/ambari-server/conf/password.dat
      #   resources.dir=/var/lib/ambari-server/resources
      #   custom.action.definitions=/var/lib/ambari-server/resources/custom_action_definitions
      #   views.http.x-frame-options=SAMEORIGIN
      #   recovery.enabled_components=METRICS_COLLECTOR
      #   jdk1.7.re=(jdk.*)/jre
      #   server.execution.scheduler.maxDbConnections=5
      #   jdk1.7.desc=Oracle JDK 1.7 + Java Cryptography Extension (JCE) Policy Files 7
      #   bootstrap.setup_agent.script=/usr/lib/python2.6/site-packages/ambari_server/setupAgent.py
      #   jdk1.8.jcpol-file=jce_policy-8.zip
      #   rolling.upgrade.max.stack=
      #   server.http.session.inactive_timeout=1800
      #   jdk1.7.jcpol-file=UnlimitedJCEPolicyJDK7.zip
      #   server.execution.scheduler.misfire.toleration.minutes=480
      #   security.server.keys_dir=/var/lib/ambari-server/keys
      #   stackadvisor.script=/var/lib/ambari-server/resources/scripts/stack_advisor.py
      #   server.jdbc.rca.user.name=ambari
      #   server.execution.scheduler.maxThreads=5
      #   metadata.path=/var/lib/ambari-server/resources/stacks
      #   server.jdbc.url=jdbc:postgresql://{fqdn}:5432/ambari
      #   server.fqdn.service.url=http://{fqdn}/latest/meta-data/public-hostname
      #   views.http.x-xss-protection=1; mode=block
      #   bootstrap.dir=/var/run/ambari-server/bootstrap
      #   jdk1.7.home=/usr/jdk64/
      #   kerberos.keytab.cache.dir=/var/lib/ambari-server/data/cache
      #   jdk1.8.home=/usr/jdk64/
      #   user.inactivity.timeout.role.readonly.default=0
      #   http.x-xss-protection=1; mode=block
      #   agent.task.timeout=900
      #   client.threadpool.size.max=25
      #   jdk1.7.jcpol-url=http://public-repo-1.hortonworks.com/ARTIFACTS/UnlimitedJCEPolicyJDK7.zip
      #   server.jdbc.user.passwd=/etc/ambari-server/conf/password.dat
      #   server.execution.scheduler.isClustered=false
      #   server.stages.parallel=true
      #   views.request.read.timeout.millis=10000
      #   server.jdbc.database=postgres
      #   server.jdbc.database_name=ambari
      #   """
      @write_ini
        destination: "#{ambari_server.conf_dir}/ambari.properties"
        content: ambari_server.config
        merge: true
        backup: true
      @execute
        cmd: """
        ambari-server setup \
          -s \
          -j #{ambari_server.java_home} \
          --database=mysql \
          --databasehost=#{db_admin.host} \
          --databaseport=#{db_admin.port} \
          --databasename=#{db.name} \
          --databaseusername=#{db.user} \
          --databasepassword=#{db.password} \
          --cluster-name=#{@config.cluster.name}
        """
