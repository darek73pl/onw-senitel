
1. Before deployment you have to put sentinel image into ECR and place URI as container_image variable.

2. Terraform backend is default - state file is stored locally

3. Deployment: 
  - terraform init
  - terraform apply

4. Input data structure for lambdas:
{
    "cam_id": "camera_unique_id",
    "metadata": {
        "key1": "value1",
        "key2": "value2",
        "key3": "value3"
    }
}

5. Nodes of ECS are located in private subnets. They are accessible by SSH from VPC or by Sessions Manager. Nodes communicate with Internet by NAT gateway (additionally paid)

6. Due to Terraform bug follow the step to revome whole deployed infrastructure:
  - remove manualy ECS cluster
  - remove manually ASG assigned to ECS Capacity Provider
  - run terraform destroy
 
7. Files used to create sentinel container image are located in folder docker
