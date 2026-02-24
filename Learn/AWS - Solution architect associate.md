To deploy a full stack application in little to none cost with absolute best performance? What services can be used?

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
21. Can multi-az setup help retrieval of recently changed data across read replicas bypassing asynchronous replication?
22. Which requires SQL connection string change for RDS -> Multi-AZ or Read replicas. Which one has DNS name for each endpoint and why not the other one have?

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
35. Compare disaster recovery across regions among -> RDS read replicas/multi-az and Aurora read replicas/global database
36. Compare IAM Database authentication and default IAM users access to RDS db. Which RDS DB doesn't support IAM database auth?
37. How many read replicas do RDS support? (15) How about one RDS cluster? How many Aurora read replicas can be in a single Aurora DB cluster? (15)
38. How to store long-term backups for Aurora DB for DR and Audit? (on-demand backups)


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
17. What are the patterns in elasticache?
18. For scaling reads, which one is not useful - RDS Multi-AZ, RDS Read Replicas and Elasticache cluster

## Route 53

### Overview

> Register domain => Under domains in Route 53 -> Registered domains
> Create a record => Go into a hosted zone -> Create record with name, type, TTL and value
> Create an alias with non-root domain for ALB => Enter record name -> Create record with A type -> Select alias -> Select the specific ALB
> Create an alias with root domain for ALB => Leave record name empty -> A record type -> Toggle Alias and select specific ALB

1. Why do we need DNS? How is DNS naming structured in hierarchial way. What is Route 53? Differentiate  between Domain registrar, service or server?
2. Relate the terms: Domain registrar, DNS Recods, DNS resolvers, Zone file, Name server, Top level domain, Second level domain, Full qualified domain and Domain. Where does WWW comes under?
3. Differentiate second level domain vs sub domain.
4. How DNS Works? (Browser -> Local -> Root -> TLD -> SLD -> Local DNS server -> Browser. Where does Hosted zone come under?
5. Does DNS mean domain name server/system?
6. What is a hosted zone and how is it related Route 53? Differentiate between public and private hosted zones.
7. Can Route 53 run with 100% availabilitty? How? (SLA)
8. Why is it called 53? (reference to tradtional DNS servers)
9. What do the records in route 53 do under the hood? (route traffic for domain) What do each record contain and tell its purpose? (Domain, Record type, Value, Routing policy, TTL)
10. What do each record types map to? What should the target domain's record type be for CNAME? What is a zone apex and why is it not possible to create a CNAME record for the top node of a DNS namespace (like example.com but possible for www.example.com)?
11. Does it cost to create any record types in Route 53? What is the difference between registering a record, creating a record, buying a dns, buying an URL, mapping dns and register domain?
12. What is the need to have privacy protection for the registering domain.
13. When i register a domain in Route 53 -> does it mean i bought a hosted zone? Why is there SOA and NS record already present inside the hosted zone when i register a domain? To create more records, should i use the existing hosted zone?
14. While creating an application load balancer, what port should it allow inbound and outbound traffic? Why is the listener set to port 80 and also set port of the target group to 80? Do all ec2 instances and load balancers have dns name on their own? Can we have instances from different AZ and regions in one target group? List out AWS resources that expose an AWS hostname, out of which should be mapped with CNAME record type to a new hostname with Route 53
15. What is the use of a TTL? What strategy to use in case of ip, dns or record change? Why doesn't alias records don't have mandatory TTL?
16. How is alias different from CNAME? Explain more about top node, root domain and non root domain with example. Can we have mydomain.com pointing to, as an alias, to an alias or aws resource?
17. Is Alias a record type? What record types are free of charge, automatic resource's ip change recognition and support native health check? How is alias an extension to DNS functionality?
18. Alias record is always of type A/AAAA for AWS resources and CNAME for other hostnames. Is it true? Why can't we set TTL for Alias records?
19. Is it possible to set Alias record for an EC2 DNS name? List out the alias records targets and why to have alias for them?
20. Compare CNAME vs alias record for an ALB. Which one is AWS Native and support target health evaluation? How is alias record free of cost?


### Routing Policy

> Health check => Under dashboard, go to health checks -> 

1. Explain the role of a routing policy? How is it different from load balancer if it determines how Route 53 responds to DNS queries? Can we use Route 53 for cross region load balancing?
2. Draw a decision diagram to choose between different routing policies.
3. Is it possible to have multiple values in same record that to from different regions? If yes, why and which is picked and sent to the client? What if each ip values point to different aws resources?
4. If alias is enabled, is it possible to have multiple AWS resource values?
5. Which routing policy support health checks? What is checked?
6. Can the sum of weights of resources be random in weighted routing policy? How is traffic handled? Is it possible to have different aws resources here having unique record names? Why do we need record id?
7. While having multiple values in simple policy it stacks up into one record but for other policies there is a record for each value. Is it true
8. How does AWS calculate the latency and redirect to resource in a latency-based routing policy? Is it done on-the-fly? Is the failover capability of route 53 same as ELB?
9. What is the strategy to configure EC2, ELB, EBS, EFS and Elasticache with Route 53 for least latency + low cost?
10. While creating a record with latency-based policy, the value is set to ip address of an an aws resource in one region and region is set different from the aws region? Can't AWS detect the region of value (ip) entered?
11. With dig command, do we get all the values set for the created record in all policies?
12. Will vpn, clear TTL for DNS cache and send the traffic to a resource with less latency? How?
13. Do both public and private resources support health checks in Route 53? Why and why not?
14. What is the hierarchy to deploy a high availability cross region resource setup with custom domain?
15. What are the different types of health checks? How to choose one for different scenarios? Can a health check be on top of another health check?
16. List out the AWS services that are integrated with CW metrics?
17. How many health checkers are currently present? (15) Do we have a health checker for each region? What does it mean to have a threshold for the health checkers? Do each health checkers evaluate an endpoint, how does it check the health of an endpoint in the first place and what exactly is the metrc to deem an endpoint to be healthy/unhealthy?
18. Is it possible to configure health check condition to pass or fail? Is it possible to setup pass/fail based on text from first X bytes of the response? What is the need for such a setup and value of this X?
19. By default, the health checkers ports are allowed in the resource when health check is enabled. If not, how to allow the resource to allow health checker port. Is it done by firewall or router.
20. If AWS has health checkers all over the globe then what does configuring health checks in Route 53 mean? Does enabling health checks individually for each values (ip) allow the AWS health checkers to check and take care of the failovers?
21. What is the need for a calculated health checks where a health checks combines the results of multiple health checks into a single health check. What operation does it use to combine the results - OR, AND, or NOT? Who monitors the health checks - Route 53, Health checkers or the parent health check? How many child health checks can be monitored at once and Is it possible to specify how many health checks need to pass for the parent to pass?
22. Why is it not possible for route 53 to access private endpoints (private VPC / on-premises resources)? (health checkers are present outside of VPC). Is there a workaround for this? (Cloudwatch alarm has access to private subnet of instances and health check can check the alarm itself based on cloudwatch metric)
23. Doesn't enabling health checks for the records create health check? Why do we create and manually configure endpoints to the health checks?
24. Why do applications have a /health endpoint in them? If we provide the IP address already to monitor the endpoint, what is the necessity to proivde a host name and what if the host name points to a wrong resource ip address? In case of a string matching, Give an example of what could be checked and in what scenario this is helpful.
25. Where would "invert health check status" be helpful? When would we want to customize health checker regions?
26. How to troubleshoot in a case where the instance is working fine but the health checker shows it to be unhealthy? (check the security group of the instances). When the health check is created for an instance, do multiple health checkers all over the globe check them constantly in an interval?
27. Lets say there is a primary instance and a secondary instance (DR purpose), we enabled health check for the primary instance, what will happen if the health check fails? Will there be a failover to the secondary instance? Should we enable health check in the secondary instance as well for the failover to happen? How this scenario will be handled for different routing policies?
28. Won't the routing policies have failover in-built with the health checks? What is the need for a failover routing policy? How many primary and secondary failover types be present?
29. How is Geolocation routing policy different from latency if the latter routes after determining traffic to the regions? Is it customizable to route user based on the location or else is it fixed? Why to create a "default" record? (unmatched location to be directed to that ip address)
30. How is geoproximity routing policy different from geolocation? Give appropriate use cases for this policy. What is the Route 53 traffic flow and what is its role in this geoproximity routing policy?
31. What is CIDR and CIDR blocks? What is the need for a IP-based routing?
32. How is multi-value routing policy different from ELB if it routes traffic to multiple resources? How can it be associated with health check and how many healthy records are returned for each? How can it be said to be client side load balancing? How is this different from simple routing policy? If there is no health check for a multi-value policy record then is it equivalent to a simple routing policy? How many values will be returned with dig command for this record?

### Advanced

1. How are these related -> Domain, Domain registrar, DNS service, EDNS and DNS Records
2. Give me an example of registering domain from 3rd party domain registrar and using Route 53 for DNS service.
3. What are the NS Records? What purpose do they serve with Route 53 vs 3rd party registrar as registrar? What happens if we match the NS records of the 3rd party registrar with route 53 to use route 53 for DNS service?
4. How to resolve DNS queries between VPC and on premise network where the network can be VPC itself/Peered VPC and On-premises network (connected through direct connect or AWS VPN)
5. Connect these -> Public name server, region, route 53 resolver, resolver endpoint, VPC, private hosted zone and an EC2 instance
6. How to connect on-premise data center with AWS? (VPN or DX)
7. What is the role of inbound and outbound endpoint in resolver endpoints?
8. How do we setup on-premises data center with private DNS resolver to AWS and use resolver inbound endpoint to route with Route 53 resolver?

## Classic Solutions Architecture Discussion

### WhatIsTheTime.com

1. Is it possible to vertically scale with zero downtime nor ip address change?
2. Can't we have a single elastic IP attached to multiple instances?
3. What happens if an EC2 instance is restarted or its ip changed whose IP was resolved with a dns record by route 53? Does the route 53 take care of failover? Route 53 eliminates the need for an elastic ip, is it true?
4. Compare the health checks in ELB vs Route 53.
5. How do we point the ELB to an auto scaling group? Does the auto scaling group have an ip address on its own? What is present inside an auto scaling group - one or more instances? target groups? heterogenous aws resources?
6. If auto scaling group takes care of horizontal scaling and failovers what is need for a health check in ELB that load balances across the auto scaling group?
7. Is it possible to have auto scaling groups or ELB across AZs and Regions? If it is possible to have auto scaling groups across different AZs then how do we define min, desired and max capacity?
8. When to go for public vc private ip ec2 instance?

### MyClother.com

1. Lets say the state of a data has to be persisted in a setup with Multi-AZ ASG and Multi-AZ AL, which is a better approach -> sticky session or web cookies or elasticache? Compare each approach with pros and cons. If sticky session and web cookies are stateless approach, what about elasticache, dynamodb or RDS?
2. How to design security groups for restricting traffic to elasticache from ec2, rds from ec2, ec2 from elb? Is it enough to edit just the inbound rules or will editing outbound rules make the application more secure?

### MyWordPress.com

1. Is it a good practice to store uploaded images in EBS attached to an instance? What are the issues? (Distribution across instances) How to address it? (EFS with ENI)
2. For multi-az and read replicas, which one to pick auroa db or rds? Why?

### Faster full stack deployments

1. Golden AMI > Pre install applications, OS dependencies and launch EC2 instance from this AMI
2. Bootstrapping user data > Dynamic configuration, use user data scripts
3. How to use a hybrid of this golden AMI and user data (Elastic beanstalk)
4. RDS > Restore from snapshot: Data base will have schemas and data ready
5. EFS > Restore from snapshot: Disk will be formatted and have data
6. How storing data in RDS stateless?

### Elastic Beanstalk

> Elastic beanstalk => Under beanstalk -> create application -> choose tier -> name application -> choose platform + branch + version -> Code -> Presets -> configure service access

1. What problem does Beanstalk try to solve?
2. Common architecture used for most web apps? (ALB + ASG)
3. When to have a manual deployment setup vs Elastic beanstalk?
4. List out the components of elastic beanstalk -> Application, its version, env, tiers.
5. Draw the lifecycle from creating an application, deploying it and also updating it.
6. Compare web server tier vs worker tier. How do each of them scale and is it possible to push messages to SQS queue from another web server tier?
7. Compare elastic beanstalk deployment modes -> Single instance vs High availability with load balancer.
8. Reason for a development environment in beanstalk?
9. List out service access to create beanstalk environment. (service role, ec2 instance profile and ec2 key pair)
10. How are the events captured during the initialization of elastic beanstalk? (cloudformation)
11. How to visually see the template as a diagram? (Application Composer)
12. Does beanstalk take care of creating security groups on its own for the setup? What about environments for dev, staging or prod?
13. What does the domain name of elastic beanstalk point to? Does it open ip address of ec2? ASG? ALB? Elastic IP?
14. What is a stack in cloudformation?

## Amazon S3

> Create bucket with different policies
> Create bucket with versioning > Properties
> Repicate bucket with/without old objects replication > Management
> Bucket with statis site hosting > Properties
> Bucket with different classes -> Change it in properties while uploading an object? 
> Enable lifecycle rules under management with Intelligent-tiering for a bucket

1. How is S3 different from EFS, EBS and other storage managed services in AWS?
2. Compare the pricing of all managed storage services.
3. Objects -> Files & Buckets -> Directories where buckets are global level and we use a full path to access files, is this true for S3? What are Keys in S3? (full path:> s3://my-bucket/myfile.txt)
4. Why do buckets must have globally unique names i.e. across regions and across all accounts?
5. Do we have a naming convention for only S3 service? Why S3 must not start with prefix xn-- nor end with suffix -s3alias?
6. The key composes prefix + object name, anything else?
7. When to use multi-part upload? Why to have list of key/value pairs along with S3 as metadata?
8. Explain more on object ownership and ACL in S3. Differentiate bucket key vs name
9. Purpose of S3 pre signed url?
10. What is the difference between copy s3 url and copy url in the s3 dashboard?
11. Draw a decision tree to choose between different security policies in S3. Is it possible to encrypt objects in S3? Why to encrypt?
12. Is it possible to have access on objects as resource in S3 policy?
13. How to force objects to be encrypted at upload using s3 bucket policy?
14. How should the policy be designed for: giving public access to s3 bucket for users to access, give an iam user access, give an ec2 instance access, cross account access (bucket policy)
15. Even though the s3 bucket is made public with policy why is it not accessible? Troubleshoot. (Check the default permission settings of S3)
16. Is it possible to configure any bucket that belongs to an account to not be public?
17. If S3 can be used to host static website, why not with other storage services - EBS, EFS or RDS? What about dynamic websites?
18. How to enable compatiblity in s3 to host a website? How is the url of this hosted static website different from an object in s3? (Properties > Enable static website hosting)
19. What does it mean to make all content publicly readable when hosting a static website in a s3 bucket? Does it mean to make the whole bucket to be public or else just the index.html object and dependent objects like images?
20. What benefit do we get in hosting static websites with S3 bucket?
21. Is the versioning in S3 automatic or manual? How does it happen? Is it bucket level or object level? Why to version? (restore and rollback)
22. How to protect against unintended deleted? (have delete marker)
23. Can suspension of versioning delete previous versions? Will deleting a version of any object will add delete marker?
24. If deletion adds marker then how to absolutely delete the object?
25. Is copying in AWS replication asynchronous or synchronous? Does s3 support cross region or only same region replication?
26. Which one to use for DR? Will it replicate previous versions of all the objects? if not, is there a workaround? (S3 batch replication)  Can object deletion with version id be replicated?
27. Is it mandatory to have versioning in order to support replication? Why?
28. Is it possible to replciate existing objects while setting up new replica? How is it possible? (Batch operations job) Wil the versions be replicated as well with their ids? What about delete markers? What will happen if an object is permanently deleted in the source bucket - carries out deletion of the replicated object?
29. Draw a decision tree to choose between s3 storage clasess. Is durability same across all the classes and what about availability? Does the storage classes apply for bucket level or object level?
30. General purpose standard S3 storage class susteain 2 concurrent facility failures, does it mean it is setup with multi-az by default? 
31. How is S3 one zone-infrequent access different from S3 standard-infrequent access?
32. If S3 glacier instant retrieval is great for data accessed once a quarter why the minimum storage duration of 90 day? Why was the former s3 glacier was divided into variants - instant, flexible and archive?
33. Compare the data retrival time taken between different glacier types and its variants.
34. Why does the glacier deep archive alone has minimum storage duration of 180 days
35. What are access tiers in S3? Why do we need to use S3 intelligent tiering?  Does it cost for both auto-tiering and retriveal charges? Compare the object access period for different access tiers.
36. What is availability SLA? Which classes have minimum billable object size and don't have retrieval fee? Why?
37. What are lifecycle rules? and what actions do they support? Is it instant to move existing objects or takes time?
38. Is it reasonable to have multiple transitions with the storage classes? How about intelligent-tiering and then deep archive?
39. What is a directory bucket and how is it different from s3 express one zone? (bucket in single AZ) Does it support replication?
40. What will the version turn out to be for existing files when version in enabled for a s3 bucket?

## Advances S3 *Try to answer different scenarios for lifecycle rules creation*

> Event notifications in Amazon S3 => Properties (Event notifications or Amazon EventBridge) -> Modify access policy of the target service

1. What is the hierarchy of storage classes in S3 for transitioning? How to have a determistic way for the transitions based on a period of time?
2. With lifecycle rules, is it possible to delete access log files? expire objects after some time? delete old versions of files? delete incomplete multi-part uploads?
3. Is the lifecycle rules applied on bucket level, object level, certain object tags or directory level in a bucket?
4. What is a non current version in s3? (which are not top level versions)
5. Any strategy to transition objects to the right storage class or create lifecycle roles? (storage class analysis) What are the storage classes that support s3 analytics and why? 
6. What do you mean be "Delete expired object delete markers or incomplete multi part uploads"?
7. Why do we have the option of requester pays since asking an user to pay to download doesn't feel right?
8. What is the difference between events and actions in s3? Is it possible to fire events for particular objects or buckets? and what happens in case of an event? does it propogate resources or allows services to access objects from S3?
9. List out the services the events can be propogated with the S3 objects in cse of an event? (SNS, SQS or Lambda) How should the role be designed? Should the s3 have access to the service it propogates resource on event or else the services should be configured to have access to certiain group of objects in a bucket? why to have service resource policy attached if roles are already present? What does the service resource policy do here? (authorizes s3 to send data to service). Why don't we use iam roles in amazon s3 for these event architecture? Where do we define resource access policies?
10. Is there a workaround to send events from S3 to services other than sns, sqs and lambda? (amazon event bridge) Does it have better filtering than native one? Which one supports multiple targets? How about archive, replay events and reliable delivery?
11. Is it possible to capture selective actions on selective filtered objects from s3 then send events to services? What action should be allowed to the targeted service? (send message). For the access policy of the targeted service, which one to be selected in the resource - ARN of s3 or targeted service?
12. How to test if notifications work? (Poll from targeted service). Should i manually poll from the targeted service to get the notification from s3 on an action?
13. How are the CRUD operations scaled per second per prefix in a bucket? Are there any limits to the number of prefixes in a bucket? If bucket/folder/sub1/file gets an amount of CRUD operations then what about bucket/folder/file2?
14. How does multi-part upload work? Does it support parallel uploads?
15. How is S3 transfer acceleration different from Cloudfront? Can it support multipart upload on top? Why is it good to minimize public network and maximise private AWS network?
16. When to use mulit-part upload, s3 transfer acceleration or s3 byte range fetches?
17. Is there an option to parallel downloads and how is download different from GETs? How about parallelizing GETs?
18. How does S3 Byte range fetches parallelize GETs? (request specific byte ranges). How to get better resilience (retry with smaller byte range), and can this be done in a automated way possible? Is it possible to have partial GETs incase only head of file is needed?
19. Relate these -> Byte ranges, connections, Seeds and peers (S3 v utorrent)
20. Why to go for S3 Batch operations? What are the components of a job? (list of objects, action and optional parameters) How to filter and get object list? (Athena) What kind of filtering is available?
21. How to manage storage across AWS orgs? (Storage Lens) What are the levels the analytics is done with the usage and is it s3 focused or all services? Why is this useful and how many days of analytics can we get? What do you mean by data aggregation and what are the levels this can be done? Does it suport custom dashboard? Differentiate free and advanced metrics.
22. Is the dashboard - Multi-Region, Multi-AZ or Multi-account. Where is the pre-configuration for the default dashboard? Is it possible to delete the default dashboard?
23. What are the insights drawn by these metrics - Summary (traffic), Cost-optimization, Data-protection (best practice), Access-management (ownership) , Event, Performance (transfer acceleration), Activity (how storage is requested) and Detailed status (status code)
24. Are there extra cost for S3 Transfer acceleration? Where to enable it?
25. Does it cost to publish metrics on cloudwatch? (yes) What is prefix aggregation?
26. What are S3 expiry actions? Why would we need them?

## S3 Security 

> 

1. Why to encrypt S3 objects? Should it be encrypted on the server or client side? What are the options S3 provides for server side encryption? (S3 managed keys, KMS and Custom provided keys) What is the encryption type used for each of the server side encryption types
2. What change/configuration should i do in the application to enable server side s2 encryption? (Set header: "x-amz-server-side-encryption":"AES256") Will setting this header automatically allow AWS to encrypt the uploaded data using SSE-S3?
3. What benefit do we get using key management service for SSE? (user control + audit key usage using cloudtrail) What header do we need to set? ("x-amz-server-side-encryption":"aws:kms")
4. How is cloudtrail different from cloudwatch?
5. What if the S3 don't have access to the KMS key? Is this done automatically with the header attached.
6. If the object is encrypted then can the users that have access to the s3 bucket, can they see the object? It is specified that without the KMS key it is not possible to read the object, does it apply to the public, users with only s3 access and not the kms or users without s3 access?
7. What is the issue with SSE-KMS? (KMS limits) What action does it trigger? (GenreateDataKey) How to request a quota increase? (Quotas console). Why not to use KMS encryption for high throughput S3 setup? (Throttling). Does it cost to create a new KMS key? 
8. Will Amazon S3 store the encryption key for server side encryption? If it is mandatory for HTTPS to be used for SSE-C encryption then what about other SSEs? Is there any header for SSE-C? (x-amz-server-side-encryption-customer-algorithm)
9. Why would we need client side encryption? What systems would need that?
10. What is an in-transit encryption (SSL/TLS), is the connection between user and target server is secure and fully encrypted or the data in flight is encrypted and can't be hijacked? Does S3 have support for HTTP endpoint?
11. Is it possible to force encryption in transit? (Deny if aws:SecureTransport condition is false in the bucket policy) What about forcing encryption using a bucket policy? (encryption headers checking)
12. What is DSSE-KMS, if there is SSE-KMS won't DSSE-KMS seem redundant?
13. What is the default encryption in S3? Does versioning need to be enabled for encryption? If encryption is changed, will it create a new version for the file with new encryption? What if versioning is off?
14. Can objects belonging to a bucket have different SSE? What is the role of bucket key option in SSE-KMS?
15. How about SSE-C, what should the default encryption be that has to be overriden with SSE-C and is it possible only through CLI?
16. How to force encryption using a bucket policy? Is this applicable only to SSE-KMS or SSE-C and not to SSE-S3 or DSSE-KMS? What do you mean by bucket policies are evaluated before "Default encryption"
17. What is CORS? Break down Origin (Scheme - Protocol, Host - Domain and Port) Is this web browser based mechanism or else a restriction on the server instance and frontends at cdn/server? Why do we have this and how to allow different origins for requests? (Access-Control-Allow-Origin/Methods: <origin> in headers) Will this happen if i build an app where frontend runs at localhost:5173 and backend at localhost:3000?
18. What is a preflight request and what is its relation with the CORS? Is the browser checking if an origin from different server is permissiable in another server with different origin i.e. cross origin?
19. Lets say there are two S3 buckets and one serves a html which has an image which is stored as an object in another. What CORS configuration should be done in order to avoid CORS errors? (Access-Control-Allow-Origin: First S3 bucket url or star)
20. What are the properties present in a CORS configuration? (Allowed Headers/Methods/Origins, ExposeHeaders and MaxAgeSeconds)? What is the ExposeHeaders and MaxAgeSeconds? Can we have an extra slash in the Allowed Origins?
21. Does S3 support MFA and what operations does it allow? (permanent delete object version, suspend versioning) Where is this option present - console or cli? (CLI)
22. Can an IAM user that has full access to a bucket enable/disable MFA delete?
23. What is the need to login with a profile in CLI?

