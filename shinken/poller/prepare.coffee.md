
# Poller Executor Build

    module.exports = []
    module.exports.push 'masson/bootstrap/log'

## Build Prepare

    module.exports.push header: 'Shinken Poller Executor # Build Prepare', timeout: -1,  handler: ->
      {shinken} = @config.ryba
      @docker_build
        image: 'ryba/shinken-poller-executor'
        file: "#{__dirname}/resources/Dockerfile"
        build_arg: [
          "user=#{shinken.user.name}"
          "privileged_krb5_principal=#{shinken.poller.executor.krb5.privileged.principal}"
          "unprivileged_krb5_principal=#{shinken.poller.executor.krb5.unprivileged.principal}"
        ]
      @docker_save
        image: 'ryba/shinken-poller-executor'
        destination: "#{@config.mecano.cache_dir or '.'}/shinken-poller-executor.tar"
