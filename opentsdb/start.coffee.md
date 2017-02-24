
# OpenTSDB Start

    module.exports = header: 'OpenTSDB Start', label_true: 'STARTED', handler: ->
      {opentsdb, realm} = @config.ryba
      @system.execute 
        cmd: "su -l #{opentsdb.user.name} -c \"kinit #{opentsdb.user.name}/#{@config.host}@#{realm} -k -t /etc/security/keytabs/opentsdb.service.keytab\""
        shy: true
      @service.start name: 'opentsdb'
