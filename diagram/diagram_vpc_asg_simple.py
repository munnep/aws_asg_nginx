from diagrams import Cluster, Diagram, Edge
from diagrams.aws.compute import EC2, EC2AutoScaling
from diagrams.aws.network import VPC, PrivateSubnet, PublicSubnet, InternetGateway, NATGateway, ElbApplicationLoadBalancer
from diagrams.onprem.compute import Server

# Variables
outformat = "png"
filename = "diagram_vpc_asg_simple"
direction = "TB"


with Diagram(
    direction=direction,
    filename=filename,
    outformat=outformat,
) as diag:
    # Non Clustered
    user = Server("user")
    loadbalancer = ElbApplicationLoadBalancer("Application \n Load Balancer")
    ec2_asg_web_server = EC2AutoScaling("Autoscaling Group \n Webserver")
 
    # Diagram
    user >> loadbalancer >> ec2_asg_web_server 


diag
