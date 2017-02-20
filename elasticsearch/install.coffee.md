
# Elasticsearch Install

Installs ElasticSearch on the specified hosts. It's divided into four main steps.
The configuration of the Elastics Search Users and Group, the configuration of Kerberos, the installation
of Elastics Search from rpm repositories and the configuration of Elastic Search environment

    module.exports = header: 'ES Install', handler: ->
      {elasticsearch ,realm} = @config.ryba
      # krb5 = @config.krb5.etc_krb5_conf.realms[realm]
## Users & Groups

By default, the "zookeeper" package create the following entries:

```bash
cat /etc/passwd | grep elasticsearch
elasticsearch:x:493:493:elasticsearch user:/home/elasticsearch:/sbin/nologin
cat /etc/group | grep elasticsearch
elasticsearch:x:493:
```

      @system.group elasticsearch.group
      @system.user elasticsearch.user

## Kerberos

      # @krb5_addprinc krb5,
      #   skip: true
      #   header: 'Kerberos'
      #   principal: elasticsearch.principal
      #   randkey: true
      #   keytab: elasticsearch.keytab
      #   uid: elasticsearch.user.name
      #   gid: elasticsearch.group.name

## Install

ElasticSearch archive comes with an RPM

      @call header: 'Packages', timeout: -1, handler: ->
        @file.download
          source: elasticsearch.source
          target: "/var/tmp/elasticsearch-#{elasticsearch.version}.noarch.rpm"
          # unless_exec: "rpm -q --queryformat '%{VERSION}' elasticsearch | grep '#{elasticsearch.version}'"
          unless_exists: true
        @execute
          cmd:"""
          yum localinstall -y --nogpgcheck /var/tmp/elasticsearch-#{elasticsearch.version}.noarch.rpm
          chkconfig --add elasticsearch
          """
          unless_exec: "rpm -q --queryformat '%{VERSION}' elasticsearch | grep '#{elasticsearch.version}'"

## Env

      @call header: 'Environment', handler: ->
        @file.yaml
          target: '/etc/elasticsearch/elasticsearch.yml'
          content:
            'cluster.name': "#{elasticsearch.cluster.name}"
            'index.number_of_shards': "#{elasticsearch.number_of_shards}"
            'index.number_of_replicas': "#{elasticsearch.number_of_replicas}"
          merge: true
          backup: true
        # write = [
        #   match: /^.*cluster.name: .*/m
        #   replace: "cluster.name: \"#{elasticsearch.cluster.name}\" # RYBA CONF `elasticsearch.cluster.name`, DON'T OVERWRITE"
        # ,
        #   match: /^.*index.number_of_shards: .*/m
        #   replace: "index.number_of_shards: #{elasticsearch.number_of_shards} # RYBA CONF `elasticsearch.number_of_shards`, DON'T OVERWRITE"
        # ,
        #   match: /^.*index.number_of_replicas: .*/m
        #   replace: "index.number_of_replicas: #{elasticsearch.number_of_replicas} # RYBA CONF `elasticsearch.number_of_replicas`, DON'T OVERWRITE"
        # ]
        # if elasticsearch.node?
        #   {node} = elasticsearch
        #   if node.name? then write.push
        #     match: /^.*node.name: .*/m
        #     replace: "node.name: \"#{elasticsearch.node.name}\" # RYBA CONF `elasticsearch.node.name`, DON'T OVERWRITE"
        #   if node.master? then write.push
        #     match: /^node.master: .*/m
        #     replace: "node.master: #{elasticsearch.node.master} # RYBA CONF `elasticsearch.node.master`, DON'T OVERWRITE"
        #     append: true
        #   if node.data? then write.push
        #     match: /^node.data: .*/m
        #     replace: "node.data: #{elasticsearch.node.data} # RYBA CONF `elasticsearch.node.data`, DON'T OVERWRITE"
        #     append: true
        # @file
        #   target: 
        #   write: write
