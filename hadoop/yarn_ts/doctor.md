
## Wait for NameNode

```
Caused by: org.apache.hadoop.hdfs.server.namenode.SafeModeException: Cannot create directory /tmp/hadoop-yarn/yarn/timeline/generic-history/ApplicationHistoryDataRoot. Name node is in safe mode.
```

The ATS doesnt wait for HDFS to exit safemode.
