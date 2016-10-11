
# Druid MiddleManager Start

    module.exports = header: 'Druid MiddleManager # Start', label_true: 'STARTED', handler: ->
      {druid} = @config.ryba
      @call once: true, 'masson/core/krb5_client/wait'
      @call once: true, 'ryba/zookeeper/server/wait'
      @call once: true, 'ryba/hadoop/hdfs_nn/wait'
      @call once: true, 'ryba/druid/coordinator/wait'
      @call once: true, 'ryba/druid/overlord/wait'
      @krb5.ticket
        uid: "#{druid.user.name}"
        principal: "#{druid.krb5_service.principal}"
        keytab: "#{druid.krb5_service.keytab}"
      @service.start
        name: 'druid-middlemanager'
