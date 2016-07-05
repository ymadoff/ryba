
# Ranger Usersync Process

    module.exports = header: 'Ranger UserSync Install', handler: ->
      {ranger,ssl} = @config.ryba
      
      @register 'hdp_select', 'ryba/lib/hdp_select'
      @register 'hconfigure', 'ryba/lib/hconfigure'
      
## Users & Groups
      
      @group ranger.group
      @user ranger.user

## Package

Install the Ranger user Sync package and set it to the latest version. Note, we
select the "kafka-broker" hdp directory. There is no "kafka-consumer"
directories.

      @call header: 'Packages', handler: ->
        hdp_current_version = null
        @call ( options, callback) =>
          @execute
            cmd:  "hdp-select versions | tail -1 | tr '.' '_' | tr '-' '_'"
          , (err, executed, stdout, stderr) =>
            return callback err if err
            hdp_current_version = stdout.trim()
            return callback null, executed
        @call ->
          @service
            name: "ranger_#{hdp_current_version}-usersync"
        @hdp_select
          name: 'ranger-usersync'
      
      @call header: 'Layout', handler: ->
        @mkdir
          destination: ranger.usersync.conf_dir
        @mkdir
          destination: ranger.usersync.log_dir
        @mkdir
          destination: ranger.usersync.pid_dir 


# ## IPTables
#
# | Service              | Port  | Proto       | Parameter          |
# |----------------------|-------|-------------|--------------------|
# | Ranger policymanager | 6080  | http        | port               |
# | Ranger policymanager | 6082  | https       | port               |
#
# IPTables rules are only inserted if the parameter "iptables.action" is set to
# "start" (default value).
#
#     module.exports.push
#       header: 'Ranger Admin # IPTables',
#       handler: ->
#         {ranger} = @config.ryba
#         return unless @config.iptables.action is 'start'
#         @iptables
#           rules: [
#             { chain: 'INPUT', jump: 'ACCEPT', dport: ranger.admin.site['ranger.service.http.port'], protocol: 'tcp', state: 'NEW', comment: "Ranger Admin HTTP WEBUI" }
#             { chain: 'INPUT', jump: 'ACCEPT', dport: ranger.admin.site['ranger.service.https.port'], protocol: 'tcp', state: 'NEW', comment: "Ranger Admin HTTPS WEBUI" }
#           ]

# ## Ranger ranger-usersync Driver
#
#     module.exports.push header: 'Ranger Admin # Driver', handler: ->
#       {ranger} = @config.ryba
#       @link
#         source: '/usr/share/java/mysql-connector-java.jar'
#         destination: ranger.admin.install['SQL_CONNECTOR_JAR']


## Setup Scripts

Update the file "install.properties" with the properties defined by the
"ryba.ranger.usersync.install" configuration.
      
      @render
        header: 'Configure Install Scripts'
        destination: "/usr/hdp/current/ranger-usersync/install.properties"
        source: "#{__dirname}/../resources/usersync-install.properties.js2"
        local_source: true
        write: for k, v of ranger.usersync.install
          match: RegExp "^#{quote k}=.*$", 'mg'
          replace: "#{k}=#{v}"
          append: true
        eof: true
        backup: true
      
      @write
        header: 'Configure Setup Scripts'
        destination: '/usr/hdp/current/ranger-usersync/setup.py'
        write : for k, v of ranger.usersync.setup
          match: RegExp "^#{quote k} =.*$", 'mg'
          replace: "#{k} = '#{v}'"
          append: true
        eof: true
        backup: true

      @execute
        header: 'Execute Setup Scripts'
        cmd: """
          cd /usr/hdp/current/ranger-usersync/
          ./setup.sh
        """
    
      # the setup scripts already render an init.d script but it does not respect 
      # the convention exit code 3 when service is stopped on the status code
      @render
        destination: '/etc/init.d/ranger-usersync'
        source: "#{__dirname}/../resources/ranger-usersync"
        local_source: true
        mode: 0o0755
        context: @config.ryba
        unlink: true
      
      writes = [
        match: RegExp "JAVA_OPTS=.*", 'm'
        replace: "JAVA_OPTS=\"${JAVA_OPTS} -XX:MaxPermSize=256m -Xmx#{ranger.usersync.heap_size} -Xms#{ranger.usersync.heap_size} \""
        append: true
      ]
      for k,v of ranger.usersync.opts
        writes.push
          match: RegExp "^JAVA_OPTS=.*#{k}", 'm'
          replace: "JAVA_OPTS=\"${JAVA_OPTS} -D#{k}=#{v}\" # RYBA, DONT OVERWRITE 'ryba/ranger/usersync'"
          append: true
      @write
        header: 'Usersync Env'
        destination: '/etc/ranger/usersync/conf/ranger-usersync-env-1.sh'
        write: writes
          
      @hconfigure
        header: 'Usersync site'
        destination: "/etc/ranger/usersync/conf/ranger-ugsync-site.xml"
        properties: ranger.usersync.site
        merge: true
        backup: true
      # 
      # @java_keystore_add
      #   keystore: ranger.usersync.site['ranger.usersync.truststore.file']
      #   storepass: 'ryba123'
      #   caname: "hadoop_root_ca"
      #   cacert: "#{ssl.cacert}"
      #   local_source: true
      # @java_keystore_add
      #   keystore: ranger.admin.site['ranger.https.attrib.keystore.file']
      #   storepass: ranger.admin.site['ranger.service.https.attrib.keystore.pass']
      #   caname: "hadoop_root_ca"
      #   cacert: "#{ssl.cacert}"
      #   key: "#{ssl.key}"
      #   cert: "#{ssl.cert}"
      #   keypass: 'ryba123'
      #   name: ranger.admin.site['ranger.service.https.attrib.keystore.keyalias']
      #   local_source: true
      # @java_keystore_add
      #   keystore: ranger.admin.site['ranger.https.attrib.keystore.file']
      #   storepass: ranger.admin.site['ranger.service.https.attrib.keystore.pass']
      #   caname: "hadoop_root_ca"
      #   cacert: "#{ssl.cacert}"
      #   local_source: true

## Dependencies

    glob = require 'glob'
    path = require 'path'
    quote = require 'regexp-quote'