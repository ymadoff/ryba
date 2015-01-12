
# Falcon Check

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'ryba/hadoop/hdfs_client'
    module.exports.push require('../hadoop/hdfs_client').configure
    module.exports.push require('./index').configure

## Check Data Pipelines

Follow the [Hortonworks Data Pipelines example][dpe].

    module.exports.push name: 'Falcon # Check Data Pipelines', skip: true, timeout: -1, label_true: 'CHECKED', callback: (ctx, next) ->
      {user, active_rm_host} = ctx.config.ryba
      cluster_path = "#{user.home}/check_falcon/cluster.xml"
      feed_path = "#{user.home}/check_falcon/feed.xml"
      process_path = "#{user.home}/check_falcon/process.xml"
      # TODO: RM HA latest
      nn_contexts = ctx.contexts 'ryba/hadoop/hdfs_nn', require('../hadoop/hdfs_nn').configure
      nn_rcp = nn_contexts[0].config.ryba.core_site['fs.defaultFS']
      nn_protocol = if nn_contexts[0].config.ryba.hdfs.site['HTTP_ONLY'] then 'http' else 'https'
      nn_nameservice = if nn_contexts[0].config.ryba.hdfs.site['dfs.nameservices'] then ".#{nn_contexts[0].config.ryba.hdfs.site['dfs.nameservices']}" else ''
      nn_shortname = if nn_contexts.length then ".#{nn_contexts[0].config.shortname}" else ''
      # dfs.namenode.https-address.torval.master2
      nn_http = ctx.config.ryba.hdfs.site["dfs.namenode.#{nn_protocol}-address#{nn_nameservice}#{nn_shortname}"] 
      nn_principal = nn_contexts[0].config.ryba.hdfs.site['dfs.namenode.kerberos.principal'].replace '_HOST', nn_contexts[0].config.host
      # TODO: RM HA latest
      rm_contexts = ctx.contexts 'ryba/hadoop/yarn_rm', require('../hadoop/yarn').configure
      rm_shortname = if rm_contexts.length > 1 then ".#{rm_contexts[0].config.shortname}" else ''
      rm_address = rm_contexts[0].config.ryba.yarn.site["yarn.resourcemanager.address#{rm_shortname}"]
      oozie_contexts = ctx.contexts 'ryba/oozie/server', require('../oozie/server').configure
      oozie_url = oozie_contexts[0].config.ryba.oozie_site['oozie.base.url']
      hive_contexts = ctx.contexts 'ryba/hive/server', require('../hive/_.coffee.md').configure
      hive_url = hive_contexts[0].config.ryba.hive.site['hive.metastore.uris']
      hive_principal = hive_contexts[0].config.ryba.hive.site['hive.metastore.kerberos.principal'].replace '_HOST', hive_contexts[0].config.host
      ctx.write [
        content: """
        <?xml version="1.0"?>
        <cluster colo="ryba-data-center" description="description" name="ryba-data-center" xmlns="uri:falcon:cluster:0.1">    
          <interfaces>
            <interface type="readonly" endpoint="hftp://#{nn_http}" version="2.4.0" /> <!-- Required for distcp for replications. -->
            <interface type="write" endpoint="#{nn_rcp}" version="2.4.0" /> <!-- Needed for writing to HDFS-->
            <interface type="execute" endpoint="#{rm_address}" version="2.4.0" /> <!-- Needed to write to jobs as MapReduce-->
            <interface type="workflow" endpoint="#{oozie_url}" version="4.0.0" /> <!-- Required. Submits Oozie jobs.-->
            <interface type="registry" endpoint="#{hive_url}" version="0.13.0" /> <!--Register/deregister partitions in the Hive Metastore and get events on partition availability -->
            <interface type="messaging" endpoint="tcp://#{ctx.config.host}:61616?daemon=true" version="5.1.6" /> <!--Needed for alerts-->
          </interfaces>
          <locations>
            <location name="staging" path="/apps/falcon/prod-cluster/staging" /> <!--HDFS directories used by the Falcon server-->
            <location name="temp" path="/tmp" />
            <location name="working" path="/apps/falcon/prod-cluster/working" />
          </locations>
          <properties>
            <property name="hadoop.rpc.protection" value="authentication"/>
            <property name="dfs.namenode.kerberos.principal" value="#{nn_principal}"/>
            <property name="hive.metastore.kerberos.principal" value="#{hive_principal}"/>
            <property name="hive.metastore.uris" value="#{hive_url}"/>
            <property name="hive.metastore.sasl.enabled" value="true"/>
          </properties>
        </cluster>
        """
        destination: "#{cluster_path}"
        uid: user.name
        eof: true
      ,
        content: """
        <?xml version="1.0"?>
        <feed description="ryba-input-feed" name="testFeed" xmlns="uri:falcon:feed:0.1">
          <tags>externalSource=ryba-external-source,externalTarget=Marketing</tags> <!-- Metadata tagging -->
          <groups>churnAnalysisFeeds</groups> <!--Feed group, feeds can belong to multiple groups -->
          <frequency>hours(1)</frequency> <!--Feed run frequency-->  
          <late-arrival cut-off="hours(6)"/> <!-- Late arrival cut-off -->
          <clusters> <!-- Target clusters for retention and replication. -->
            <cluster name="ryba-data-center" type="source">
              <validity start="2014-02-28T00:00Z" end="2016-03-31T00:00Z"/>
              <retention limit="days(90)" action="delete"/> <!--Currently delete is the only action available -->
            </cluster>
            <!--cluster name="ryba-data-center-secondary" type="target">
              <validity start="2012-01-01T00:00Z" end="2099-12-31T00:00Z"/>
              <retention limit="days(7)" action="delete"/>
              <locations>
                <location type="data" path="/churn/weblogs/${YEAR}-${MONTH}-${DAY}-${HOUR} "/>
              </locations>
            </cluster-->
          </clusters>
          <locations> <!-- Global location across clusters - HDFS paths or Hive tables -->
            <location type="data" path="/weblogs/${YEAR}-${MONTH}-${DAY}-${HOUR} "/>
          </locations>
          <ACL owner="hdfs" group="users" permission="0755"/>  <!-- Required for HDFS. -->
          <schema location="/none" provider="none"/> <!-- Required for HDFS. -->
        </feed>
        """
        destination: "#{feed_path}"
        uid: user.name
        eof: true
      ,
        content: """
        <?xml version="1.0"?>
        <process name="process-test" xmlns="uri:falcon:process:0.1">
            <clusters>
              <cluster name="ryba-data-center">
                <validity start="2011-11-02T00:00Z" end="2011-12-30T00:00Z"/>
              </cluster>
            </clusters>
            <parallel>1</parallel>
            <order>FIFO</order> <!--You can also use LIFO and LASTONLY but FIFO is recommended in most cases--> 
            <frequency>days(1)</frequency> 
            <inputs>
                <input end="today(0,0)" start="today(0,0)" feed="feed-clicks-raw" name="input" />
            </inputs>
            <outputs>
                <output instance="now(0,2)" feed="feed-clicks-clean" name="output" />
            </outputs>
            <workflow engine="pig" path="/apps/clickstream/clean-script.pig" />
            <retry policy="periodic" delay="minutes(10)" attempts="3"/>
            <late-process policy="exp-backoff" delay="hours(1)">
            <late-input input="input" workflow-path="/apps/clickstream/late" />
            </late-process>
        </process>
        """
        destination: "#{process_path}"
        uid: user.name
        eof: true
      ], (err, written) ->
        return next err if err
        ctx.execute [
          cmd: mkcmd.test ctx, "falcon entity -type cluster -submit -file #{cluster_path}"
        ,
          cmd: mkcmd.test ctx, "falcon entity -type feed -submit -file #{feed_path}"
        ,
          cmd: mkcmd.test ctx, "falcon entity -type process -submit -file #{process_path}"
        ], next

## Dependencies

    mkcmd = require '../lib/mkcmd'

[dpe]: http://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.1.3/bk_falcon/content/ch_falcon_data_pipelines.html
