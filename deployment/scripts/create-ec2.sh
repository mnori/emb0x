aws ec2 run-instances \
    --image-id ami-0c02fb55956c7d316 \ # Ubuntu 22.04 LTS (replace with your region's AMI ID)
    --count 1 \
    --instance-type t2.micro \
    --key-name emb0x-key \
    --security-group-ids <your-security-group-id> \
    --subnet-id <your-subnet-id> \
    --user-data file://user-data.sh \
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=emb0x-instance}]'

    