
## File could not be replicated

message:

15/08/04 14:22:15 INFO mapreduce.JobSubmitter: Cleaning up the staging area /user/ryba/.staging/job_1438696002584_0015
org.apache.hadoop.ipc.RemoteException(java.io.IOException): File /user/ryba/.staging/job_1438696002584_0015/job.jar could only be replicated to 0 nodes instead of minReplication (=1).  There are 2 datanode(s) running and no node(s) are excluded in this operation.

cause:

HFDS DN saturation, logs were printing [DataXceiver errors](../hdfs_dn/doctor.md).
