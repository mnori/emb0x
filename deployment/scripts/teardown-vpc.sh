#!/bin/bash

# Delete all VPCs tagged emb0x-vpc
VPC_IDS=$(aws ec2 describe-vpcs \
  --filters "Name=tag:Name,Values=emb0x-vpc" \
  --query "Vpcs[].VpcId" \
  --output text \
  --region "$AWS_REGION" || true)

if [ -n "$VPC_IDS" ]; then
  echo "Processing VPCs: $VPC_IDS"
  for VPC_ID in $VPC_IDS; do
    [ -z "$VPC_ID" ] && continue
    echo "Cleaning VPC $VPC_ID"

    # Detach & delete Internet Gateways
    IGW_IDS=$(aws ec2 describe-internet-gateways \
      --filters "Name=attachment.vpc-id,Values=$VPC_ID" \
      --query "InternetGateways[].InternetGatewayId" \
      --output text --region "$AWS_REGION" || true)
    for IGW in $IGW_IDS; do
      [ -z "$IGW" ] && continue
      aws ec2 detach-internet-gateway --internet-gateway-id "$IGW" --vpc-id "$VPC_ID" --region "$AWS_REGION" 2>/dev/null || true
      aws ec2 delete-internet-gateway --internet-gateway-id "$IGW" --region "$AWS_REGION" 2>/dev/null || true
      echo "Deleted IGW $IGW"
    done

    # Delete NAT Gateways
    NAT_IDS=$(aws ec2 describe-nat-gateways \
      --filter "Name=vpc-id,Values=$VPC_ID" \
      --query "NatGateways[].NatGatewayId" \
      --output text --region "$AWS_REGION" 2>/dev/null || true)
    for NAT in $NAT_IDS; do
      [ -z "$NAT" ] && continue
      aws ec2 delete-nat-gateway --nat-gateway-id "$NAT" --region "$AWS_REGION" || true
      # Wait (short poll) for deletion
      for i in $(seq 1 30); do
        S=$(aws ec2 describe-nat-gateways --nat-gateway-ids "$NAT" \
          --query "NatGateways[0].State" --output text --region "$AWS_REGION" 2>/dev/null || echo "deleted")
        [ "$S" = "deleted" ] && break
        sleep 4
      done
      echo "Deleted NAT Gateway $NAT (or scheduled)."
    done

    # Delete VPC Endpoints
    VPCE_IDS=$(aws ec2 describe-vpc-endpoints \
      --filters "Name=vpc-id,Values=$VPC_ID" \
      --query "VpcEndpoints[].VpcEndpointId" \
      --output text --region "$AWS_REGION" || true)
    if [ -n "$VPCE_IDS" ]; then
      aws ec2 delete-vpc-endpoints --vpc-endpoint-ids $VPCE_IDS --region "$AWS_REGION" || true
      echo "Deleted VPC Endpoints: $VPCE_IDS"
    fi

    # Delete subnets (all in VPC)
    SUBNETS=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" \
      --query "Subnets[].SubnetId" --output text --region "$AWS_REGION" || true)
    for SUB in $SUBNETS; do
      [ -z "$SUB" ] && continue
      aws ec2 delete-subnet --subnet-id "$SUB" --region "$AWS_REGION" 2>/dev/null || echo "Subnet $SUB still in use."
    done

    # Delete non-main route tables
    RT_IDS=$(aws ec2 describe-route-tables \
      --filters "Name=vpc-id,Values=$VPC_ID" \
      --query "RouteTables[].RouteTableId" \
      --output text --region "$AWS_REGION" || true)
    for RT in $RT_IDS; do
      [ -z "$RT" ] && continue
      IS_MAIN=$(aws ec2 describe-route-tables --route-table-ids "$RT" \
        --query "RouteTables[0].Associations[?Main==\`true\`].Main" \
        --output text --region "$AWS_REGION" 2>/dev/null || echo "False")
      [ "$IS_MAIN" = "True" ] && continue
      aws ec2 delete-route-table --route-table-id "$RT" --region "$AWS_REGION" 2>/dev/null || echo "Could not delete route table $RT"
    done

    # Final attempt to delete VPC
    if aws ec2 delete-vpc --vpc-id "$VPC_ID" --region "$AWS_REGION" 2>/dev/null; then
      echo "Deleted VPC $VPC_ID"
    else
      echo "VPC $VPC_ID still has dependencies."
    fi
  done
else
  echo "No tagged VPCs (emb0x-vpc) found."
fi