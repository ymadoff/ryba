
# OpenTSDB Start

    module.exports = header: 'OpenTSDB Start', label_true: 'STARTED', handler: ->
      {opentsdb, realm} = @config.ryba
      @execute 
        cmd: "/usr/bin/kinit #{opentsdb.user.name}/#{@config.host}@#{realm} -k -t /etc/security/keytabs/opentsdb.service.keytab"
        shy: true
      @service.start name: 'opentsdb'
