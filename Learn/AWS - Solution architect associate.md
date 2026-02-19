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

> Sticky sessions => Go to target group -> Edit attributes -> Turn on stickiness -> In case of Application-based cookie then configure cookie name

> Cross zone load balancing => Go to Load balancers -> Select a load balancer and attributes -> Edit to toggle it (Toggle CZLB for specific target groups if necessary)

> SSL/TLS Cert for Load balancers => Select specific load balancer -> Add listener -> Configure with port 443 for HTTPS protocol with default action of forward to specific target group

2. What is a downstream instance and is there an upstream instance? What is the role of elastic load balancer here? How does it provide SSL termination for website and enforce stickiness with cookies?
3. Compare own load balancer vs Elastic load balancer and internal (private) vs external (public) load balancers. Brief on the relation among elastic, application, network and gateway load balancer.
4. What is a health check? How is this crucial to availability? Is it done across instances or target groups? How is it different for each type of load balancers?
5. Draw a decision diagram to choose between different types of load balancers in AWS.
6. How do we configure the ip range in security group of an instance with load balancer? (link SG of LB -> SG of EC2)
7. What layer does ALB, NLB and GLWB operate at? In ALB, Do we load balance multiple applications in the same or across machines or across target groups? (Target groups, containers)
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

### SSL/TLS + ASG

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

### ASG

1. What is Auto scaling group? Does it scale vertical or horizontal? Difference between scale out and scale in
2. Can ASG automatically register new instances to a load balancer? How about recreation of EC2 instance if an old one is unhealthy?
3. How much does ASG cost?
4. Relate minimum, desired and maximum capacity, how it affects the scaling?
5.  
