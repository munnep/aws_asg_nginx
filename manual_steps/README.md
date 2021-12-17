# Manual steps

## Summary
This document describes the manual steps for creating a autoscaling group with webservers behind an application load balancer which you can then connect to over the internet. The webserver is in a private subnet

See below diagram for how the setup is:  
![](../diagram/diagram_vpc_asg.png)

## Steps to take
- Create a VPC with cidr block ```10.233.0.0/16```  
![](media/2021-12-08-13-51-43.png)  
- Create 3 subnets. 2 public subnets and 1 private subnet
    - patrick-public1-subnet (ip: ```10.233.1.0/24``` availability zone: ```us-east-1a```)  
    - patrick-public2-subnet (ip: ```10.233.2.0/24``` availability zone: ```us-east-1b```)  
    - patrick-private1-subnet (ip: ```10.233.11.0/24``` availability zone: ```us-east-1a```)  
![](media/2021-12-08-14-05-39.png)  
![](media/2021-12-08-14-05-55.png)  
![](media/2021-12-08-14-06-08.png)  
![](media/2021-12-08-14-06-23.png)  
- create an internet gateway  
![](media/2021-12-08-14-07-45.png)    
![](media/2021-12-08-14-08-09.png)  
- create a nat gateway which you attach to ```patrick-public1-subnet```   
![](media/2021-12-08-15-20-55.png)  
- create routing table for public  
![](media/2021-12-08-14-10-55.png)  
   - edit the routing table for internet access to the internet gateway
   ![](media/2021-12-08-14-12-18.png)  
- create routing table for private  
   ![](media/2021-12-08-14-13-32.png)  
   - edit the routing table for internet access to the nat gateway  
   ![](media/2021-12-08-14-14-41.png)   
- attach routing tables to subnets  
    - patrick-public-route to public subnets      
    ![](media/2021-12-08-14-16-18.png)      
    - patrick-private-route to private subnet   
     ![](media/2021-12-08-14-17-53.png)    
- create a security group that allows http and https from all locations    
![](media/2021-12-08-14-20-11.png)    





- Auto Scaling - Launch Configurations  
![](media/2021-12-15-15-15-48.png)  
- Create launch configuration. 
![](media/2021-12-15-15-16-13.png)  
![](media/2021-12-15-15-19-00.png)  
```
#cloud-config
runcmd:
  - apt-get install -y nginx
  - systemctl enable --no-block nginx 
  - systemctl start --no-block nginx 
````
![](media/2021-12-15-15-21-05.png)  
![](media/2021-12-15-15-21-53.png)  
![](media/2021-12-15-15-33-35.png)  
- The launch configuration should now be visible  
![](media/2021-12-15-16-31-48.png)  

- loadbalancer create a target group which we at a later point connect to the Auto Scaling Group
![](media/2021-12-16-16-13-15.png)  
![](media/2021-12-16-16-13-49.png)  
- Will have no targets yet
![](media/2021-12-16-16-27-26.png)   

- loadbalancer create a appplication load balancer which will connect to the load balancer target  
![](media/2021-12-16-16-14-52.png)  
![](media/2021-12-16-16-15-41.png)  
![](media/2021-12-16-16-15-55.png)  
![](media/2021-12-16-16-16-13.png)  
![](media/2021-12-16-16-16-31.png)  
![](media/2021-12-16-16-17-05.png)  

- Auto Scaling groups. Will configure the group and connect it to auto scaling launch and the created load balancer  
![](media/2021-12-16-16-29-32.png)  
![](media/2021-12-16-16-29-58.png)  
![](media/2021-12-16-16-30-29.png)  
![](media/2021-12-16-16-30-53.png)  
![](media/2021-12-16-16-31-08.png)  
![](media/2021-12-16-16-31-30.png)  
![](media/2021-12-16-16-31-51.png)  

- loadbalancer generated a DNS name which you can use to connect to the application server  
![](media/2021-12-08-15-36-38.png)  
[patrick-loadbalancer-1479571194.us-east-1.elb.amazonaws.com](patrick-loadbalancer-1479571194.us-east-1.elb.amazonaws.com)

### Test the autoscaling

After everything is working you should see one web server running and one web server as a target in the load balancer target group

EC2   
![](media/2021-12-17-10-30-12.png)  

Load balancer target  
![](media/2021-12-17-10-30-52.png)

**Change the Auto scaling group to have 2 servers**
- Edit your Auto scaling group  
![](media/2021-12-17-10-31-52.png)  
- Change the desired capacity to 2  
![](media/2021-12-17-10-32-27.png)  
- After that you should see 2 EC2 instances and load balancer target with 2 instances  
![](media/2021-12-17-10-39-15.png)  
![](media/2021-12-17-10-39-51.png)  
