# Hortonworks Smartsense Server Check

Check for the HST server. Check the three ports (two way ssl ports and webui port)

    module.exports = header: 'HST Server Wait', label_true: 'READY', handler: ->
      {smartsense} = @config.ryba
      @system.execute
        cmd: "echo > /dev/tcp/#{@config.host}/#{smartsense.server.ini.server.port}"
      @system.execute
        cmd: "echo > /dev/tcp/#{@config.host}/#{smartsense.server.ini['security']['server.one_way_ssl.port']}"
      @system.execute
        cmd: "echo > /dev/tcp/#{@config.host}/#{smartsense.server.ini['security']['server.two_way_ssl.port']}"
