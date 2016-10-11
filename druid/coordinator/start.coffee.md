
# Druid Coordinator Start

    module.exports = header: 'Druid Coordinator # Start', label_true: 'STARTED', handler: ->
      {druid} = @config.ryba
      @call once: true, 'ryba/zookeeper/server/wait'
      @krb5.ticket
        uid: "#{druid.user.name}"
        principal: "#{druid.krb5_service.principal}"
        keytab: "#{druid.krb5_service.keytab}"
      @service.start
        name: 'druid-coordinator'
