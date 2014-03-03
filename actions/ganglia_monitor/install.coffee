
fs = require 'fs'
eco = require 'eco'
misc = require 'mecano/lib/misc'

module.exports = [
  (ctx, next) ->
    @name 'Ganglia Monitor: Package'
    @timeout 10000
    ctx.ssh.exec 'yum install -y ganglia-gmond', (err, stream) ->
      stream.on 'exit', (code) ->
        next err, if code is 0 then ctx.OK else ctx.PASS
,
  (ctx, next) ->
    @name 'Ganglia Monitor: Configuration'
    fs.readFile "#{__dirname}/resources/gmond.conf", 'utf-8', (err, content) ->
      return next err if err
      ctx.config.ganglia_monitor ?= {}
      ctx.config.ganglia_monitor.collectors ?= ctx.hosts_with_module 'phyla/actions/ganglia_collector'
      ctx.config.ganglia_monitor.monitors ?= ctx.hosts_with_module 'phyla/actions/ganglia_monitor'
      content = eco.render content, ctx.config
      ctx.ssh.sftp (err, sftp) ->
        misc.file.writeFile ctx.ssh, '/etc/ganglia/gmond.conf', content, (err) ->
          ctx.ssh.exec 'service gmond stop', (err, stream) ->
            stream.on 'exit', (code) ->
              next err, if code is 0 then ctx.OK else ctx.ERROR
,
  (ctx, next) ->
    @name 'Ganglia Monitor: Startup'
    @timeout 20000
    ctx.ssh.exec 'chkconfig gmond on && service gmond start', (err, stream) ->
      stream.on 'exit', (code) ->
        next err, if code is 0 then ctx.OK else ctx.ERROR
]

# collector = ''
# for server in node[:cluster][:servers] do
#   if server[:ganglia_collector]
#     collector = server[:ip]
#     break
#   end
# end

# template "/etc/ganglia/gmond.conf" do
#   owner "root"
#   group "root"
#   mode "0644"
#   variables({:collector => collector})
#   source "ganglia/gmond.conf.erb"
# end

# service "ganglia-monitor" do
#   action :restart
# end

