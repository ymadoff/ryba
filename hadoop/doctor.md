
## NodeManager corrupted ownership

The permissions inside the "usercache" folder are set to yarn instead of the
user being impersonnated by yarn.

/data/1/yarn/local/usercache/ryba ryba:yarn OK
/data/1/yarn/local/usercache/ryba/appcache yarn:yarn drwx--x--- insteadof ryba:yarn drwxr-s---
/data/1/yarn/local/usercache/ryba/filecache yarn:yarn insteadof ryba:yarn
/data/1/yarn/local/usercache/ryba/filecache/{id} yarn:yarn insteadof ryba:ryba
/data/1/yarn/local/usercache/ryba/filecache/{id}/{file} yarn:yarn insteadof ryba:ryba

user='ryba'
chown $user /data/*/yarn/local/usercache/$user/appcache
chmod 2750 /data/*/yarn/local/usercache/$user/appcache
chown $user /data/*/yarn/local/usercache/$user/filecache
chown -R $user:$user /data/*/yarn/local/usercache/$user/filecache

The cause is still unknown. 

There are a few concequences of this curruption.

Inside the NodeManager after a mapreduce:

> org.apache.hadoop.util.DiskChecker$DiskErrorException: Could not find usercache

## FileSystem appear full while not full

Some files (such as log files) have been removed while the service is still
running. Here's how to list removed files:

```
# Disk Usage for directory
# -m: in MB
# -n: skip directories on different file systems
du -mx /var/ | sort -n | tail -30
# File system disk space
df -h
# List open files
lsof | grep deleted
```

Solution: restart the service using those files.

## FileSystem is not balanced

http://www.swiss-scalability.com/2013/08/hadoop-hdfs-balancer-explained.html
http://hadoop.apache.org/docs/r2.7.0/hadoop-project-dist/hadoop-hdfs/HDFSCommands.html#balancer

## ResourceManager looking for JobHistoryServer

```
2015-06-30 13:09:54,573 INFO org.apache.hadoop.ipc.Client: Retrying connect to server: hadoop.ryba/10.10.10.2:10020. Already tried 49 time(s); retry policy is RetryUpToMaximumCountWithFixedSleep(maxRetries=50, sleepTime=1000 MILLISECONDS)
2015-06-30 13:09:54,574 ERROR org.apache.hadoop.yarn.server.resourcemanager.rmapp.RMAppImpl: Failed to renew token for application_1435658699800_0022 on recovery : Failed to renew token: Kind: MR_DELEGATION_TOKEN, Service: 10.10.10.2:10020, Ident: (owner=ryba, renewer=yarn, realUser=oozie/hadoop.ryba@HADOOP_SINGLE.RYBA, issueDate=1435669316151, maxDate=1436274116151, sequenceNumber=5, masterKeyId=2)
java.io.IOException: Failed to renew token: Kind: MR_DELEGATION_TOKEN, Service: 10.10.10.2:10020, Ident: (owner=ryba, renewer=yarn, realUser=oozie/hadoop.ryba@HADOOP_SINGLE.RYBA, issueDate=1435669316151, maxDate=1436274116151, sequenceNumber=5, masterKeyId=2)
  at org.apache.hadoop.yarn.server.resourcemanager.security.DelegationTokenRenewer.handleAppSubmitEvent(DelegationTokenRenewer.java:443)
  at org.apache.hadoop.yarn.server.resourcemanager.security.DelegationTokenRenewer.addApplicationSync(DelegationTokenRenewer.java:382)
  at org.apache.hadoop.yarn.server.resourcemanager.rmapp.RMAppImpl$RMAppRecoveredTransition.transition(RMAppImpl.java:854)
  at org.apache.hadoop.yarn.server.resourcemanager.rmapp.RMAppImpl$RMAppRecoveredTransition.transition(RMAppImpl.java:836)
  at org.apache.hadoop.yarn.state.StateMachineFactory$MultipleInternalArc.doTransition(StateMachineFactory.java:385)
  at org.apache.hadoop.yarn.state.StateMachineFactory.doTransition(StateMachineFactory.java:302)
  at org.apache.hadoop.yarn.state.StateMachineFactory.access$300(StateMachineFactory.java:46)
  at org.apache.hadoop.yarn.state.StateMachineFactory$InternalStateMachine.doTransition(StateMachineFactory.java:448)
  at org.apache.hadoop.yarn.server.resourcemanager.rmapp.RMAppImpl.handle(RMAppImpl.java:711)
  at org.apache.hadoop.yarn.server.resourcemanager.RMAppManager.recoverApplication(RMAppManager.java:312)
  at org.apache.hadoop.yarn.server.resourcemanager.RMAppManager.recover(RMAppManager.java:413)
  at org.apache.hadoop.yarn.server.resourcemanager.ResourceManager.recover(ResourceManager.java:1207)
  at org.apache.hadoop.yarn.server.resourcemanager.ResourceManager$RMActiveServices.serviceStart(ResourceManager.java:590)
  at org.apache.hadoop.service.AbstractService.start(AbstractService.java:193)
  at org.apache.hadoop.yarn.server.resourcemanager.ResourceManager.startActiveServices(ResourceManager.java:1014)
  at org.apache.hadoop.yarn.server.resourcemanager.ResourceManager$1.run(ResourceManager.java:1051)
  at org.apache.hadoop.yarn.server.resourcemanager.ResourceManager$1.run(ResourceManager.java:1047)
  at java.security.AccessController.doPrivileged(Native Method)
  at javax.security.auth.Subject.doAs(Subject.java:415)
  at org.apache.hadoop.security.UserGroupInformation.doAs(UserGroupInformation.java:1628)
  at org.apache.hadoop.yarn.server.resourcemanager.ResourceManager.transitionToActive(ResourceManager.java:1047)
  at org.apache.hadoop.yarn.server.resourcemanager.ResourceManager.serviceStart(ResourceManager.java:1091)
  at org.apache.hadoop.service.AbstractService.start(AbstractService.java:193)
  at org.apache.hadoop.yarn.server.resourcemanager.ResourceManager.main(ResourceManager.java:1226)
Caused by: java.net.ConnectException: Call From hadoop.ryba/10.10.10.2 to hadoop.ryba:10020 failed on connection exception: java.net.ConnectException: Connection refused; For more details see:  http://wiki.apache.org/hadoop/ConnectionRefused
  at sun.reflect.NativeConstructorAccessorImpl.newInstance0(Native Method)
  at sun.reflect.NativeConstructorAccessorImpl.newInstance(NativeConstructorAccessorImpl.java:57)
  at sun.reflect.DelegatingConstructorAccessorImpl.newInstance(DelegatingConstructorAccessorImpl.java:45)
  at java.lang.reflect.Constructor.newInstance(Constructor.java:526)
  at org.apache.hadoop.net.NetUtils.wrapWithMessage(NetUtils.java:791)
  at org.apache.hadoop.net.NetUtils.wrapException(NetUtils.java:731)
  at org.apache.hadoop.ipc.Client.call(Client.java:1473)
  at org.apache.hadoop.ipc.Client.call(Client.java:1400)
  at org.apache.hadoop.ipc.ProtobufRpcEngine$Invoker.invoke(ProtobufRpcEngine.java:232)
  at com.sun.proxy.$Proxy8.renewDelegationToken(Unknown Source)
  at org.apache.hadoop.mapreduce.v2.api.impl.pb.client.MRClientProtocolPBClientImpl.renewDelegationToken(MRClientProtocolPBClientImpl.java:268)
  at org.apache.hadoop.mapreduce.v2.security.MRDelegationTokenRenewer.renew(MRDelegationTokenRenewer.java:68)
  at org.apache.hadoop.security.token.Token.renew(Token.java:377)
  at org.apache.hadoop.yarn.server.resourcemanager.security.DelegationTokenRenewer$1.run(DelegationTokenRenewer.java:532)
  at org.apache.hadoop.yarn.server.resourcemanager.security.DelegationTokenRenewer$1.run(DelegationTokenRenewer.java:529)
  at java.security.AccessController.doPrivileged(Native Method)
  at javax.security.auth.Subject.doAs(Subject.java:415)
  at org.apache.hadoop.security.UserGroupInformation.doAs(UserGroupInformation.java:1628)
  at org.apache.hadoop.yarn.server.resourcemanager.security.DelegationTokenRenewer.renewToken(DelegationTokenRenewer.java:527)
  at org.apache.hadoop.yarn.server.resourcemanager.security.DelegationTokenRenewer.handleAppSubmitEvent(DelegationTokenRenewer.java:441)
  ... 23 more
Caused by: java.net.ConnectException: Connection refused
  at sun.nio.ch.SocketChannelImpl.checkConnect(Native Method)
  at sun.nio.ch.SocketChannelImpl.finishConnect(SocketChannelImpl.java:739)
  at org.apache.hadoop.net.SocketIOWithTimeout.connect(SocketIOWithTimeout.java:206)
  at org.apache.hadoop.net.NetUtils.connect(NetUtils.java:530)
  at org.apache.hadoop.net.NetUtils.connect(NetUtils.java:494)
  at org.apache.hadoop.ipc.Client$Connection.setupConnection(Client.java:608)
  at org.apache.hadoop.ipc.Client$Connection.setupIOstreams(Client.java:706)
  at org.apache.hadoop.ipc.Client$Connection.access$2800(Client.java:369)
  at org.apache.hadoop.ipc.Client.getConnection(Client.java:1522)
  at org.apache.hadoop.ipc.Client.call(Client.java:1439)
  ... 36 more
```

Solution: start the JHS server before the YARN RM

## HDFS reports Configured Capacity: 0 (0 B) for datanode

In such case, you may still see Datanode services to be running on the server, 
but if you try to load any data onto HDFS, it will report an exception for 
dfs.replication.min threshold:

```
org.apache.hadoop.ipc.RemoteException(java.io.IOException): File <_FILENAME_>._COPYING_ could only be replicated to x nodes instead of minReplication (=1).  There are x datanode(s) running and x node(s) are excluded in this operation.
	at org.apache.hadoop.hdfs.server.blockmanagement.BlockManager.chooseTarget4NewBlock(BlockManager.java:1550)
	at org.apache.hadoop.hdfs.server.namenode.FSNamesystem.getAdditionalBlock(FSNamesystem.java:3447)
	at org.apache.hadoop.hdfs.server.namenode.NameNodeRpcServer.addBlock(NameNodeRpcServer.java:642)
	at org.apache.hadoop.hdfs.protocolPB.ClientNamenodeProtocolServerSideTranslatorPB.addBlock(ClientNamenodeProtocolServerSideTranslatorPB.java:484)
	at org.apache.hadoop.hdfs.protocol.proto.ClientNamenodeProtocolProtos$ClientNamenodeProtocol$2.callBlockingMethod(ClientNamenodeProtocolProtos.java)
	at org.apache.hadoop.ipc.ProtobufRpcEngine$Server$ProtoBufRpcInvoker.call(ProtobufRpcEngine.java:619)
	at org.apache.hadoop.ipc.RPC$Server.call(RPC.java:962)
	at org.apache.hadoop.ipc.Server$Handler$1.run(Server.java:2039)
	at org.apache.hadoop.ipc.Server$Handler$1.run(Server.java:2035)
	at java.security.AccessController.doPrivileged(Native Method)
	at javax.security.auth.Subject.doAs(Subject.java:415)
	at org.apache.hadoop.security.UserGroupInformation.doAs(UserGroupInformation.java:1628)
	at org.apache.hadoop.ipc.Server$Handler.run(Server.java:2033)
```

Possible situations:

*   Only namenode are running and it's not in safemode   
*   Namenode and Datanodes are both running, but datanodes are not able to send  their heartbeat & blockreport to the namenode.   
*   Datanode is dead   

Note: These are symptoms that either of the below is a problem:

*   Configuration files are not setup properly, including proper permissions for the directories.   
*   There is connectivity issue between datanode and namenode   

Troubleshoot:

*   Verify that capacity is properly configured (using capacity generator script).
*   Verify the status of namenode and datanode services.
*   Verify whether core-site.xml has fs.defaultFS value specified correctly.
*   Verify logs for namenode and datanode services.
*   Verify hdfs-site.xml has dfs.namenode.http(s)-address.<nameservice>.<namenodeid>.
*   Verify data.dir permission on datanodes
