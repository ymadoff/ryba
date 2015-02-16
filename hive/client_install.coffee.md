
# Hive & HCat Client

    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push 'ryba/hive/_'
    module.exports.push 'ryba/hadoop/mapred_client'
    module.exports.push 'ryba/tez'
    module.exports.push 'ryba/hadoop/yarn_client'
    module.exports.push require('./client').configure

## Configure

See [Hive/HCatalog Configuration Files](http://docs.hortonworks.com/HDPDocuments/HDP1/HDP-1.3.2/bk_installing_manually_book/content/rpm-chap6-3.html)

    module.exports.push name: 'Hive & HCat Client # Configure', handler: (ctx, next) ->
      {hive, hadoop_group} = ctx.config.ryba
      ctx.hconfigure
        destination: "#{hive.conf_dir}/hive-site.xml"
        default: "#{__dirname}/../resources/hive/hive-site.xml"
        local_default: true
        properties: hive.site
        merge: true
      , (err, configured) ->
        return next err if err
        ctx.execute
          cmd: """
          chown -R #{hive.user.name}:#{hadoop_group.name} #{hive.conf_dir}
          chmod -R 755 #{hive.conf_dir}
          """
        , (err) ->
          next err, configured


      

  

















