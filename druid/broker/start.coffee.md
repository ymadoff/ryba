
# Druid Broker Start

    module.exports = header: 'Druid Broker Start', label_true: 'STARTED', handler: ->
      {druid} = @config.ryba
      @call once: true, 'ryba/zookeeper/server/wait'
      @call once: true, 'ryba/druid/coordinator/wait'
      @call once: true, 'ryba/druid/overlord/wait'
      @call once: true, 'ryba/druid/historical/wait'
      @call once: true, 'ryba/druid/middlemanager/wait'
      @krb5.ticket
        uid: "#{druid.user.name}"
        principal: "#{druid.krb5_service.principal}"
        keytab: "#{druid.krb5_service.keytab}"
      @service.start
        name: 'druid-broker'
