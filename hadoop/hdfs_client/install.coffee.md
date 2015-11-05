
# Hadoop HDFS Client Install

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'ryba/hadoop/core'
    # module.exports.push require('./index').configure
    module.exports.push 'ryba/lib/hconfigure'
    module.exports.push 'ryba/lib/hdp_select'

    module.exports.push header: 'HDFS Client # Configuration', handler: ->
      {hadoop_conf_dir, hdfs, hadoop_group} = @config.ryba
      @hconfigure
        destination: "#{hadoop_conf_dir}/hdfs-site.xml"
        default: "#{__dirname}/../../resources/core_hadoop/hdfs-site.xml"
        local_default: true
        properties: hdfs.site
        uid: hdfs.user.name
        gid: hadoop_group.name
        merge: true
        backup: true

## HDP Select

    module.exports.push header: 'HDFS Client # HDP Select', handler: ->
      @hdp_select
        name: 'hadoop-client'
