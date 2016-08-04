
# Repositories for HDP

Declare the HDP repository.

    module.exports = ->
      'configure': ->
        ryba = @config.ryba ?= {}
        ryba.hdp_repo ?= 'http://public-repo-1.hortonworks.com/HDP/centos6/2.x/updates/2.4.2.0/hdp.repo'
      'install': 
        header: 'Ryba # Repository'
        timeout: -1
        if: -> @config.ryba.hdp_repo
        handler: (options) ->
          {proxy, hdp_repo} = @config.ryba
          @download
            source: hdp_repo
            target: '/etc/yum.repos.d/hdp.repo'
            proxy: proxy
          @execute
            cmd: "yum clean metadata; yum update -y"
            if: -> @status -1
          @call
            if: -> @status -2
            handler: (_, callback) ->
              options.log 'Upload PGP keys'
              @fs.readFile "/etc/yum.repos.d/hdp.repo", (err, content) =>
                return callback err if err
                keys = {}
                reg = /^pgkey=(.*)/gm
                while matches = reg.exec content
                  keys[matches[1]] = true
                keys = Object.keys keys
                return callback null, true unless keys.length
                for key in keys
                  @execute # TODO, should use `@download`
                    cmd: """
                    curl #{key} -o /etc/pki/rpm-gpg/#{path.basename key}
                    rpm --import  /etc/pki/rpm-gpg/#{path.basename key}
                    """
                @then callback
