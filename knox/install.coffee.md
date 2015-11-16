
# Knox Install

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'masson/core/iptables'
    module.exports.push 'masson/core/yum'
    module.exports.push 'ryba/lib/hconfigure'
    module.exports.push 'ryba/lib/write_jaas'

## Users & Groups

    module.exports.push header: 'Knox # Users & Groups', handler: ->
      {knox} = @config.ryba
      @group knox.group
      @user knox.user
      
## IPTables

| Service        | Port  | Proto | Parameter       |
|----------------|-------|-------|-----------------|
| Gateway        | 8443  | http  | gateway.port    |


IPTables rules are only inserted if the parameter "iptables.action" is set to
"start" (default value).

    module.exports.push header: 'Knox # IPTables', handler: ->
      {knox} = @config.ryba
      @iptables
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: knox.site['gateway.port'], protocol: 'tcp', state: 'NEW', comment: "Knox Gateway" }
        ]
        if: @config.iptables.action is 'start'

## Service

    module.exports.push header: 'Knox # Service', timeout: -1, handler: ->
      @service name: 'knox'

## Master Secret

    module.exports.push header: 'Knox # Master Secret', handler: ->
      {knox} = @config.ryba
      @fs.exists '/usr/hdp/current/knox-server/data/security/master', (err, exists) ->
        return next err, false if err or exists
        @ssh.shell (err, stream) ->
          return next err if err
          emitted = done = false
          stream.write "su -l #{knox.user.name} -c '/usr/hdp/current/knox-server/bin/knoxcli.sh create-master'\n"
          stream.on 'data', (data, stderr) ->
            @log[if stderr then 'err' else 'out'].write data
            data = data.toString()
            if emitted
              # Wait the end
            else if done
              emitted = true
              stream.end 'exit\n'
            else if /Enter master secret:/.test data
              stream.write "#{knox.master_secret}\n"
            else if /Enter master secret again:/.test data
              stream.write "#{knox.master_secret}\n"
              done = true
          stream.on 'exit', ->
            return next Error 'Exit before the end' unless done
            next null, done
          stream.pipe @log.out
          stream.stderr.pipe @log.err
      # su -l knox -c '$gateway_home/bin/knoxcli.sh create-master'
      # MySecret

## Configure

    module.exports.push header: 'Knox # Configure', handler: ->
      {knox} = @config.ryba
      @hconfigure
        destination: "#{knox.conf_dir}/gateway-site.xml"
        properties: knox.site
        merge: true

## Env

We do not edit knox-env.sh because environnement variables are directly set
in the gateway.sh service script.
  
    module.exports.push header: 'Knox # Env', handler: ->
      {knox} = @config.ryba
      @write
        destination: "#{knox.conf_dir}/gateway.sh"
        write: for k, v of knox.env
          match: new RegExp "^#{k}=.*$", 'i'
          replace: "#{k.toUpperCase()}=#{v}"
          append: true

## Kerberos

    module.exports.push header: 'Knox # Kerberos', handler: ->
      {knox, realm} = @config.ryba
      {kadmin_principal, kadmin_password, admin_server} = @config.krb5.etc_krb5_conf.realms[realm]
      @krb5_addprinc
        principal: knox.krb5_user.principal
        randkey: true
        keytab: knox.krb5_user.keytab
        uid: knox.user.name
        gid: knox.group.name
        kadmin_principal: kadmin_principal
        kadmin_password: kadmin_password
        kadmin_server: admin_server
      @write_jaas
        destination: knox.site['java.security.auth.login.config']
        content: 'com.sun.security.jgss.initiate':
          principal: knox.krb5_user.principal
          keyTab: knox.krb5_user.keytab
          renewTGT: true
          doNotPrompt: true
          isInitiator: true
          useTicketCache: true
          client: true
        no_entry_check: true
        uid: knox.user.name
        gid: knox.group.name
        mode: 0o600

## Topologies

    module.exports.push header: 'Knox # Topologies', handler: ->
      {knox} = @config.ryba
      @remove
        destination: "#{knox.conf_dir}/topologies/admin.xml"
        unless: 'admin' in Object.keys knox.topologies
      @remove
        destination: "#{knox.conf_dir}/topologies/sandbox.xml"
        unless: 'sandbox' in Object.keys knox.topologies
      for nameservice, topology of knox.topologies
        doc = builder.create 'topology', version: '1.0', encoding: 'UTF-8'
        gateway = doc.ele 'gateway' if topology.providers?
        for role, p of topology.providers
          provider = gateway.ele 'provider'
          provider.ele 'role', role
          provider.ele 'name', p.name
          provider.ele 'enabled', if p.enabled? then "#{p.enabled}" else 'true'
          if typeof p.config is 'object'
            for name in Object.keys(p.config).sort()
              if p.config[name]
                param = provider.ele 'param'
                param.ele 'name', name
                param.ele 'value', p.config[name]
        for role, url of topology.services
          unless url is false
            service = doc.ele 'service'
            service.ele 'role', role.toUpperCase()
            if Array.isArray url then for u in url
              service.ele 'url', u
            else if url not in [null, ''] then service.ele 'url', url
        @write
          destination: "#{knox.conf_dir}/topologies/#{nameservice}.xml"
          content: doc.end pretty: true
          eof: true

## LDAP SSL CA Certificate

Knox use Shiro for LDAP authentication and Shiro cannot be configured for 
unsecure SSL.
With LDAPS, the certificate must be imported into the JRE's keystore for the
client to connect to openldap.

    # module.exports.push header: 'Knox # LDAPS CA cert', handler: ->
    #   {java_home, jre_home} = @config.java
    #   {knox} = @config.ryba
    #   return next() unless knox.ssl?.cafile? and knox.ssl?.caname?
    #   tmp_location = "/tmp/ryba_knox_cacerts_#{Date.now()}"
    #   @upload
    #     source: knox.ssl.cafile
    #     destination: "#{tmp_location}/cacert"
    #   @java_keystore_add
    #     keystore: "#{jre_home or java_home}/lib/security/cacerts"
    #     storepass: "changeit"
    #     caname: knox.ssl.caname
    #     cacert: "#{tmp_location}/cacert"
    #   @remove
    #     destination: "#{tmp_location}/cacert"

## Dependencies

    builder = require 'xmlbuilder'
