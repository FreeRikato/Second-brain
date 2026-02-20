## 5. EC2 Fundamentals
### 44. EC2 Instance purchasing options
> What are throughput, latency, IO, volume, memory & storage? How are they related
1. What are the different types of EC2 Instances Purchasing options?
2. What is the difference between Reserved and Savings Plans?
3. What is the difference between Dedicated Hosts and Dedicated Instances?
4. How is Capacity Reservations different from Reserved instances and Dedicated instances?
5. What are the different payment options and instance scope?
6. Compare the changeable options in convertible reserved instance vs savings plan
7. What do you mean by instance type can be changed in a convertible reserved instance?
8. When will you lose an EC2 spot instance? Is it after the spot instance price crosses user defined spot price or else if spot instance price climbs to demand pricing.
9. Draw a decision tree diagram to choose between the EC2 purchasing options.
10. How to benefit from billing discounts for Capacity reservations?

### 45. Spot instances and Spot fleet
11. How does spot instance work?
12. What is a "Spot Block"? How is it different from spot instance?
13. How to terminate spot instance? 
14. What are the components in a spot request?
15. What is the difference between interrupted and stopped in a persistent valid spot request?
16. Instead of canceling spot instance request that are open, active or disabled. What happens if i cancel spot instance request when it fails, canceled or closed?
17. What is the objective of Spot fleet?
18. Give me an example on how priceCapacityOptimized strategy works in allocating spot instances for a spot fleet?
19. Explain the benefits of capacityOptimized strategy for spot instance allocation in spot fleet.
20. Differentiate Spot instance request with Spot fleet and Spot Block

### 46. EC2 instances launch types hands on 

21. Before launching a spot instance, what should be done?
22. What does these option mean in Maximum price for spot fleet request => 1.Use default 2.Set your max price (per instance/hour)? What is this for?
23. How to launch a spot instance and spot fleet?
24. Is it possible to launch multiple instance types inside of a dedicated host? How about inside of a dedicated instance?
25. How to launch dedicated instance?


## 6. EC2 - Solutions Architect Associate Level

### 47. Private vs Public vs Elastic IP

1. How do machine connect to WWW in a private network? (NAT + internet gateway => Proxy)
2. What is an elastic ip? What problem does it solve? How is it different from public IP?

### 48. Private vs Public vs Elastic IP Hands On

3. Why is the hourly charge for in-use as well as idle public ipv4 address cost the same ($0.005)?
4. There is an option to choose instance and private ip address while associating an elastic ip what if i chose an instance but chose the private ip address of another instance? Why do i have both these options? Can an instance have more than one private ip address?
5. What happens if i toggle on - Allow this elastic IP address to be re-associated?
6. Does disassociating an elastic ip release it?

### 49. EC2 Placement Groups
7. What are Placement groups and what challenge do they address?
8. In a spread placement group, are the instances separated across availability zones or hardware?
9. What is a partition? What is a T-zone? How many partitions can be per AZ?
10. How is partition different from hardware? What is a rack in AWS?
11. Compare the instances limitation per AZ in spread vs partition placement group.
12. Which one has more availability and how - Spread or Partition placement group?
13. Do instances in a partition share rack with same or different instances in other partitions? Why so?
14. How to find which partition the EC2 instances are on? (Metadata service)
15. Draw a decision diagram to choose between different types of placement groups.

### 50. EC2 Placement Groups Hands On
16. Under which section can you find the placement groups? (Network and security)
17. Under spread levels, what do the options rack and hosts mean? What is outposts?
18. After the creation of placement group, what happens if i launch one vs multiple instances in terms of different placement groups?

### 51. Elastic Network Interfaces
19. What is the relationship between virtual network card and elastic network interfaces? What is the use of an ENI?
20. What is the use of having more than one private ipv4 with multiple ethernets? Differentiate private ipv4 vs ethernet vs ENI.
21. Restrictions on Public vs Elastic per Private ipv4 for an ENI.
22. Can ENIs have MAC address on their own with one or more security groups?
23. Is it possible to create ENIs independent of an EC2 instance?
24. Move ENIs from EC2 instances for failover, Explain. Can it be moved outside of an Availability zone

### 52. Elastic Network Interfaces Hands On

25. How to choose the subnet while creating a network interface for an EC2 instance?
26. Are ENIs created on creation of an instance? and what happens to the primary ENIs when the instances associated with them are terminated?


### 53/54. EC2 Hibernate

27. How does stop, terminate and hibernate actions affect EBS volumes and in-memory RAM?
28. How hibernation handle RAM state and EBS volume? Does hibernation require the EBS volume to be encrypted unlike stop and terminate? What is a KMS key?
29. Why hibernation is not supported in bare metal instances?
30. Does hibernated and stopped instance cost money?
31. Differentiate instance store vs EBS volume and which root volume supports hibernation?

## 7. EC2 Instance Storage

### 55-59. EBS Overview + Snapshots and Hands On
1. What are the different types of drives and what type is EBS? What is the purpose of EBS? Why are the EBS volumes handy in case of failovers?
2. Can an EBS volume be mounted to multiple instances or attached to an instance in different AZs? Explain (multi-attach, snapshots)
3. What is IOPS in EBS? How does billing work in renting EBS?
4. Any use of attaching multiple EBS to one instance? What is the default behavior of root and other EBS volumes when the instance it is attached to is terminated?
5. What is the purpose of snapshots in EBS and why is it recommended to detach before snapshot?
6. Why to archive EBS snapshots? What happens if a snapshot is deleted? Does it cost to maintain recycle bin for snapshots?
7. Is it possible to force full initialization of snapshot without latency on first use? (FSR)
8. Difference between copy snapshot and create volume from snapshot?

### 60/61. AMI Overview and Hands On
9. How to customize EC2 instance? What are the benefits? What are the ways to get these customizations? Are AMIs specific to a AWS region?

### 62. EC2 Instance store
10. EC2 instance store are ephemeral in nature. Support the statement
11. Give me a decision tree to decide between different types of storage volumes in EC2.

### 63. More on EBS

> Encrypting unencrypted EBS volume => 
> 1. Create unencrypted volume -> Create snapshot -> Copy snapshot (enable encryption) 
> -> Create volume from the copied encrypted snapshot
> 2. Create unencrypted volume -> Create snapshot -> Create volume from the copied encrypted snapshot (enable encryption)

> Creating an EFS and mounting to multiple EC2
> Create file system (customize) -> Create EC2 instance 
> -> Select subnet (configured with vps while creating EFS) under network settings 
> -> Select EFS under File systems and add shared file system

12. Draw a decision tree diagram to decide on choosing among the EBS volume types along with EC2 instance store
13. Why can't st1 and st2 be used as boot volumes?
14. Brief on the IOPS linkage with throughput or size of an EBS volume in gp2 vs gp3 and io1?
15. What is the limitation to gp2 in terms of IOPS to size of the volume? Compare it to gp3.
16. Which volume types support EBS Multi-attach? Does it support cross-AZ? Which file system is cluster aware?
17. In an encrypted EBS volume, is the data moving between instance <> volume and volumes created from snapshot encrypted or not?
18. What standard algorithm is used for encryption? does encryption have an impact on latency?
19. How to encrypt an unencrypted EBS volume? What is the nature of the snapshot of an unencrypted EBS volums and volume created from encrypted snapshot?
20. How are these different from each other -> S3 vs EBS vs EFS vs instance store?
21. Can multiple instances from different AZ attached with same EFS? What about vice-versa?
22. What about provisioning EFS? Is it encrypted by default?
23. Draw a decision tree diagram to choose among different EFS performance and storage classes.
24. What is the necessity of a lifecycle policy and lifecycle management in EFS?
25. What is the port for NFS to be used in security group for EFS access?
26. Is it possible to delete EFS that is connected and in-use by EC2 instances? How about deleting security groups that are already in-use by other services?
27. Why EFS support only linux instances?

## 8. High availability and Scalability: ALB & ASG

1. Define, relate and differentiate => Scalability (vertical vs horizontal), Elasticity, Availability (passive vs active)
### ELB, ALB, NLB and GWLB

> Launch ALB => Create multiple EC2 instances with user script -> Go to Load Balancers under Load balancing -> Create ALB: Internet facing, IPv4, Select AZs for network mapping, Create security group to allow HTTP from anywhere -> Create Target group

> Link security group of ALB to EC2 => Go to security group used for the instances -> Edit inbound rules
-> With HTTP type select security group of ALB

> Route routing options in ALB => Go to specific ALB -> Listener rules -> Add rule

> Launch NLB => Create multiple EC2 instances with user script -> Go to Load balancers under Load balancing -> Create NLB: Internet facing, IPv4, Select all AZ in Network mapping where each IPv4 address is fixed/static assigned by AWS -> Create security group allowing traffic in port 80 -> Create target group (configure group name, protocol, port and health check) -> Configure security group of the instances to link port 80 with the security group of the NLB

2. What is a downstream instance and is there an upstream instance? What is the role of elastic load balancer here? How does it provide SSL termination for website and enforce stickiness with cookies?
3. Compare own load balancer vs Elastic load balancer and internal (private) vs external (public) load balancers. Brief on the relation among elastic, application, network and gateway load balancer.
4. What is a health check? How is this crucial to availability? Is it done across instances or target groups? How is it different for each type of load balancers?
5. Draw a decision diagram to choose between different types of load balancers in AWS.
6. How do we configure the ip range in security group of an instance with load balancer? (link SG of LB -> SG of EC2)
7. What layer does ALB, NLB and GLWB operate at? In ALB, Do we load balance multiple applications in the same or across machines or across target groups? (Target groups, containers). Do elastic load balancers provide static - ipv4, ipv6 or dns name?
8. ALB supports redirect from HTTP to HTTPS. Support the statement
9. What are the options to route routing in ALB? Why is it great for micro services & container based application? (Port mapping)? What are the action types on top of route routing?
10. What are target groups? Can public ip addresses be in a target group? List out the target groups for each type of load balancer? Do target groups have security group?
11. Why is a HTTP request translated into JSON event for a target group of lambda functions?
12. You get a fixed hostname with ALB. Why?
13. What is connection termination? Why do we need these headers X-Forwarded-For, X-Forwarded-Port and X-Forwarded-Proto in load balancing?
14. Internet-facing vs Internal and IPv4 vs Dualstack ALB.
15. Why do we assign multiple AZ for load balancers in network mapping and what happens to a request from another AZ which is not assigned to load balancer? Can a load balancer be used to distribute traffic to instances from other AZ?
16. What happens if there are two listener rules with same priority for an ALB?
17. How many static ips can ALB, NLB and GLWB have per AZ? Why? Do they support elastic IP to each of the AZ?
18. How to meet the requirement of exposing application only with a set of static IPs with load balancer?
19. Why would we have an NLB in front of ALB? (fixed ips)
20. What load balancer should i use to deploy, scale and manage a fleet of 3rd party network virtual appliances in AWS?
21. What if the internet before reaching the application has to be inspected or analysed?
22. What is a route table?
23. In a GLWB, what is the path of the requests from users to the application (users -> route table -> GLWB -> spread to 3rd party security appliances in target group -> GLWB -> application)
24. If GLWB combines the functions of transparent network gateway and load balancer what about ALB and NLB?
25. What is GENEVE protocol on port 6081 in GLWB?
26. What is the need to sticky sessions or session affinity? (preserve session
    data)
27. Which load balancers support sticky sessions? how is this possible? Any
    constraint to this? (except glwb, cookie, expiration date)
28. Which load balancer supports sticky session without cookie?
29. What are the types of cookies for a sticky session? how to choose between them?
30. Which are the approaches to creating different cookie types? Who generates which type? What naming convention to be used?
31. Do we specify the duration for both type of cookies in the stickiness section of aws console and if yes, how are they different in the first place?
32. What is the need for cross zone balancing? Best vs Worst case scenario for CZLB.
33. What is the nature of CZLB in different types of load balancers by default? Does it cost for inter AZ data?
34. Is it possible to attach elastic IP to ALB?

### SSL/TLS + ASG

> Sticky sessions => Go to target group -> Edit attributes -> Turn on stickiness -> In case of Application-based cookie then configure cookie name

> Cross zone load balancing => Go to Load balancers -> Select a load balancer and attributes -> Edit to toggle it (Toggle CZLB for specific target groups if necessary)

> SSL/TLS Cert for Load balancers => Select specific load balancer -> Add listener -> Configure with port 443 for HTTPS protocol with default action of forward to specific target group

1. Why to go for SSL certificate? (in-flight encryption)
2. Who is responsible to encrypt and decrypt the data?
3. What is the relation between SSL and TLS? Who issues these? Do they expire?
4. Are there public and private SSL/TLS certificates?
5. Explain SSL certificate termination. Who is responsible for this?
6. How to manage these certificates in AWS?
7. When do we add more than one certs? (support multiple domains)
8. Why should the client use server name indication to specify the hostname they reach?
9. What problem does SNI solve? Does it work across all load balancers and cloudfront?
10. Lets say the request comes with SNI, it is understandable that it is matched with the right SSL certificate to be encrypted but how does it be routed to the right target group for that domain?
11. Do all the types of load balancers support multiple SSL certificates? How to support multiple hostname?
12. How to support compatibilit for older versions of SSL or TLS? (Secure listener settings)
13. Is connection draining useful? How it is related to deregistration delay?
14. What happens to the request that are in process inside a deregistering instance if it the instance is stopped suddenly before the deregistration delay period?
15. How to configure HTTPS for multiple hostnames by configuring ALB?

### ASG

> Auto scaling groups => Go into ASG under auto scaling -> Create a launch template, choose launch options, Other service integration, Configure group size & scaling, add notifications and add tags

> Auto scaling policies => Inside the auto scaling group, go into Automatic scaling -> Select the type of strategy and create one

1. What is Auto scaling group? Does it scale vertical or horizontal? Difference between scale out and scale in
2. Can ASG automatically register new instances to a load balancer? How about recreation of EC2 instance if an old one is unhealthy?
3. How much does ASG cost?
4. Relate minimum, initial, desired and maximum capacity, how it affects the scaling?
5. What is the need of load balancer if there is ASG already which would take care of scaling? How to combine and use load balancer with ASG with health checks and scaling?
6. What are the main attributes to a launch template for ASG and can it have instances with heterogeneous attributes?
7. Why to have EC2 User data in launch template?
8. How to use cloudwatch alarm and scaling policies to go hand in hand for better traffic handling?
9. Does the scaling policies apply only for scale out or also supports scale in?
10. Can ASG work across AZs i.e. Create instances from different AZs? How to configure subnets for such launch templates?
11. If we attach a load balancer on top of auto scaling group and select a target group, will the ASG scale in and out instances inside the target group?
12. On what basis does the ASG scale in or out by default without any custom scaling policies?
13. What security group or EC2 user data can make the instance unhealthy? Will the ASG endlessly launch instances if the instance it launch is unhealthy due to an issue?
14. What are the different strategies under scaling policies? Draw a decision diagram to choose between these strategies.
15. List out some metrics to watch out for to scale with ASG.
16. How does ready-to-use AMI reduce configuration time for faster request serving and cooldown period reduction?
17. If a scale out in target tracking policy is determined with cloudwatch, does it scale in on its own? For example i have set to scale out at 40% CPU usage and it creates an instance what if the CPU usage goes down? How does it determine when to scale in?
18. Does Network load balancer support health checks for both HTTP and TCP?

## 9. AWS Fundamentals: RDS + Aurora + ElastiCache

### RDS

Create RDS => Under Aurora and RDS -> Go to databases -> Create database -> Select template and deployment options

1. Differentiate RDS, DynamoDB and Aurora
2. If it supports multiple database engines, does it support the respective query language for the engines as well?
3. Compare RDS vs deploying db on EC2
4. What is provisioning and what does it mean for automated provisioning + OS patching + Maintenance window for upgrades in RDS?
5. Differentiate point in time restore with snapshots
6. What is read replicas? What is its purpose? (scale reads)
7. For a multi AZ setup, are multiple instances connected to one RDS or a single instance is connected to distributed RDS across different AZs? What about its backing with an EBS and how it gets affected with multi AZ setup
8. How to support unpredictable workloads with RDS? What happens if it crosses maximum storage threshold? Are both scale-in and scale-out policies determined for auto-scaling? How about support for all RDS database engines?
9. Are read replicas tied to an AZ or a region? Won't synchronous replication of DB consume time? What happens if the application reads from Read Replica before data replication and why is it called eventually consistent?
10. What is the benefit of promoting replicas to be its own DB and for an application the connection string is mostly tied to one fixed DB, how to leverage all read replicas in RDS cluster?
11. Brief on the network cost for read replicas. (no pay for same region)
12. For a multi-az setup, is the replication operation -> Sync or Async? Will the new write to master DB replicated to the replicated DB for multi-AZ and read replica setups?
13. How many DNS name do we have in a multi-az setup compared to read replica setup? What is it used for?
14. What is the secondary db called in multi-az and read replica setups? In case of a problem with master what happens to these secondary dbs? List out the Failover scenarios in both setups.
15. Can the read replicas converted to multi AZ setup for DR? How to convert RDS from single AZ to multi AZ? Do we need to stop the DB for these conversions? How AWS does these conversions behind the scenes?
16. Differentiate standby with readable standby? Why does RDS need Storage of its own? For a no preference AZ, where will the RDS be created?
17. Why to have Multi-AZ deployment for a read replica?
18. How to completely delete a RDS DB?
19. Is it possible to have control of the underlying OS and database customization of an RDS? What is an SSM Session Manager and how is it different from SSH?
20. Why is it necessary to deactivate automation mode before customization on the DB? Which engines support such customization?

### Aurora

Create Aurora DB => RDS > Create database -> Aurora type with psql or mysql engine -> 

1. Why do we have Aurora in the first place if Postgres and MySQL engines already exist? is Aurora DB - Postgres or MySQL?
2. Compare the scaling, replica, availability and Failover of Aurora storage compare to other. If it is better then why does it cost more than RDS?
3. Does Aurora always have 6 copies of data across 3 AZ (4 for writes and 3 for reads)
4. Explain the self healing, storage stripping and auto expanding feature of aurora db.
5. If one aurora instance takes writes then how are other copies synced? Which one has cross region replication - RDS or Aurora?
6. How is the conversion of read replica to master in Aurora different from RDS?
7. What are writer and reader endpoint and what is its role? Do we need the application to connect to the read replicas? If yes, why cause connecting to master should be enought right? Is reader endpoint connected to master along with the read replicas? What happens to the endpoint in case of a failover?
8. Pick out features avaialable in Aurora vs RDS from -> Automatic fail-over, Backup & Recovery, Isolation & Security, Industry compliance, Push-button scaling, Automated patching with zero downtime, Advance monitoring, Routine Maintenance and Backtrack
9. Differentiate Backtrack from point in time and Auto scaling from Push-button scaling
10. What are these features: global database, parallel query and local write forwarding in Aurora
11. Why do we configure instance for Aurora? won't AWS do it automatically? Why do we get the option of serverless, r and t classes
12. Why do we have multiple endpoints in Aurora for writer and reader instance? Why isn't there desired capacity in scaling policy of Aurora?
13. How to delete the aurora db? Is there any particular sequence of steps to it?
14. Are all replicas in shared storage volume for - RDS and Aurora? What is the connection between -> Aurora DB, Aurora cluster, Aurora global database and Aurora cross region read replicas?
15. Is reader endpoint a load balancer for multiple read replicas in Aurora? Can read replicas be of different sizes? If so what is its purpose? How is custom endpoint different from reader endpoint?
16. What is database instantiation? How is it done in Aurora serverless?
17. Does proxy fleet in Aurora serverless have cold starts?
18. How is Aurora Global Datbase (AGD) different from Aurora Cross Region Read Replicas? What is recovery time objective and what is its place in AGD?
19. Compare cross region replication of RDS, Aurora DB and AGD.
20. How to enable ML-based predictions via SQL in applications (Aurora ML -> SageMaker and Comprehend)
21. Lets say a company uses microsoft SQL server and wish to migrate to Aurora postgresql, how is this possible with little to no code changes. If the translation T-SQL queries into Aurora postgres, does it translate to psql syntax and what is the role of AWS SCT & DMS?
22. When does the automated backups run in RDS and Aurora? Can it be disable in both of them? Is it full backup or semi? What about the transaction log backups? How long is the point in time backup supported?
23. Which backup has no limit to retention - Automated or Manual? How is DB snapshots different from Point in time?
24. Does it cost even after stopping RDS or Aurora DB? What about ELBs? any way to avoid this cost?
25. Does RDS/Autora backup/snapshot restoration create a new database or modify an existing replica?
26. How to migrate to MySQL RDS/Aurora cluster from on-premises database? (S3, Percona XtraBackup)
27. What is the copy-on-write protocol and how is it useful for database cloning? Which one supports this - RDS/Aurora?
28. Differentiate at-rest vs in-flight encryption. How to enrypt an un-encrypted database and is it possible to encrypt its existing read replicas since an unencrypted master can only have unencrytped read replicas? Why to use AWS TLS root certiciate especially on client-side for in-flight encryption?
29. Do RDS and Aurora support SSH? (except RDS Custom)
30. How to get a longer retention of the Audit logs? (sent to cloudwatch logs)
31. How is RDS proxy different from proxy fleet and reader endpoint in Aurora, Can't we use a ELB here? How does it reduce failover time in RDS/Aurora by 66%
32. How is RDS proxy serverless? Does it support multi-AZ or multi-region? 
33. If RDS proxy is never publicly accessible, what about RDS/Aurora? How to access them them? Why such a setup?
34. What is connection pooling? How can it be exhausted? What are open connections and why connections timeout?

### ElastiCache

Redis Elasticache => Under Elasticache, get started -> 

1. What is the difference between valkey, redis and memcached? I don't get the idea of a in-memory databases in cloud, cache is used for frequently accessed data and use key to return value which is much faster than database returns, What if the in-memory database is present at a place farther from the application than a database? What if we use sqlite embededded with the application and use it for caching rather than cloud in-memory database? Should the cloud in-memory database i.e. ElastiCache present near the database or application? Compare indexed database returns with in-memory database cache-hit returns if both db and in-memory db are present in the same location.
2. How does elasticache make the application stateless? What is common to RDS and Elasticache?
3. How to decide if a data should be indexed/cached?
4. Which one is better for user session store for one vs multple instances of an application -> elasticache, cookies, RDS, refresh token or session token
5. How to make data durable in redis elasticache? (AOF peristance) What is the need for sorted sets in redis elasticache?
6. Why doesn't memcached elasticache support replication unlike memcached? How does memcached support sharding and compare the data persistence + thread architecture of redis vs memcached elasticache?
7. Which one supports serverless - redis vs memcached elasticache? How and Why it does?
8. What is a node-based cluster deployment? What is its relation to the redis & memcached elasticache? What is a cluster cache and cluster mode?
9. Are the cluster cache and RDS/Aurora cluster in same AZ synced, what if they don't exist in same AZ?
10. Differentiate between - Cluster, Shard, Node group, Serverless in caching
11. How to plan and use redis/memcached Elasticache with RDS/Aurora (including proxy) effectively for a single vs multi-instance application? List out different scenarios + configuration like high availability, low cost, high performance and more such metrics
12. Why to have an on premise elasticache? How to do it?
13. Does elasticache support cross-region?
14. What's the purpose of primary and reader endpoint in elasticache?
15. Does elasticache support IAM authentication? What is an AWS API-level security?
16. Compare these redis auth options - 1. Password -> security group -> SSL in-flight encryption 2. IAM Authentication? What auth does memcached support? (SASL)
17. 
