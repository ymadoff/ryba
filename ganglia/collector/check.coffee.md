
# Check Ganglia Collector

    module.exports = []
    module.exports.push 'masson/bootstrap/'

## Check Services

Call the "checkGmetad.sh" deployed by the Ganglia HDP package and check if the
"/usr/bin/rrdcached" and "/usr/sbin/gmetad" daemons are running.

    module.exports.push name: 'Ganglia Collector # Check Services', label_true: 'CHECKED', handler: (ctx, next) ->
      ctx.execute
        cmd: "/usr/libexec/hdp/ganglia/checkGmetad.sh"
      .then next
