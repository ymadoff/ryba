
# Ambari NiFi Configure

    module.exports = ->
      {ssl} = @config
      options = @config.ambari_nifi ?= {}

## Environment

      options.conf_dir ?= '/etc/nifi/conf'
      options.log_dir ?= '/var/log/nifi'
      options.toolkit ?= {}
      options.toolkit.source ?= 'http://www-eu.apache.org/dist/nifi/1.2.0/nifi-toolkit-1.2.0-bin.zip'
      options.toolkit.target ?= '/etc/nifi/conf/nifi-toolkit'

## User and Groups

      # Group
      options.group = name: options.group if typeof options.group is 'string'
      options.group ?= {}
      options.group.name ?= 'nifi'
      options.group.system ?= true
      # User
      options.user = name: options.user if typeof options.user is 'string'
      options.user ?= {}
      options.user.name ?= 'nifi'
      options.user.gid = options.group.name
      options.user.system ?= true
      options.user.comment ?= 'NiFi User'
      options.user.home ?= '/var/lib/nifi'
      options.user.limits ?= {}
      options.user.limits.nofile ?= 64000
      options.user.limits.nproc ?= 10000

## Nifi

https://community.hortonworks.com/articles/81184/understanding-the-initial-admin-identity-access-po.html

      options.ssl ?= ssl
      options.truststore ?= {}
      options.keystore ?= {}
      if options.ssl
        throw Error "Required Option: ssl.cert" if  not options.ssl.cert
        throw Error "Required Option: ssl.key" if not options.ssl.key
        throw Error "Required Option: ssl.cacert" if not options.ssl.cacert
        options.truststore.target ?= "#{options.conf_dir}/truststore.jks"
        throw Error "Required Property: truststore.password" if not options.truststore.password
        options.truststore.caname ?= 'hadoop_root_ca'
        options.truststore.type ?= 'jks'
        throw Error "Invalid Truststore Type: #{truststore.type}" unless options.truststore.type in ['jks', 'jceks', 'pkcs12']
        options.keystore.target ?= "#{options.conf_dir}/keystore.jks"
        throw Error "Required Property: keystore.password" if not options.keystore.password
        throw Error "Required Property: keystore.keypass" if not options.keystore.keypass
