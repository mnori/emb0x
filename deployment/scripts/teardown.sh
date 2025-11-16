#!/bin/bash
# Stops terminal being held up by AWS CLI pagers
: "${AWS_REGION:=$AWS_REGION}"
INSTANCE_NAME="emb0x-instance"
export AWS_PAGER=""

# Optional: terminate any existing instance with same Name tag (non-blocking)
# Cleanly collect existing, non-terminated instance IDs
# Collect non-terminated, tagged instances
RAW_IDS=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=${INSTANCE_NAME}" \
            "Name=instance-state-name,Values=running,pending,stopping,stopped" \
  --query "Reservations[].Instances[].InstanceId" \
  --output text \
  --region "$AWS_REGION" || true)

# Normalize (strip CRLF, remove duplicates)
EXISTING_IDS=""
for ID in $RAW_IDS; do
  CLEAN_ID=$(echo "$ID" | tr -d '\r')
  [[ -n "$CLEAN_ID" ]] && EXISTING_IDS+=" $CLEAN_ID"
done
EXISTING_IDS=$(echo "$EXISTING_IDS" | xargs -n1 | sort -u | xargs)

if [ -n "$EXISTING_IDS" ]; then
  echo "Found candidate instances: $EXISTING_IDS"
  VALID_IDS=()
  for ID in $EXISTING_IDS; do
    STATE=$(aws ec2 describe-instances --instance-ids "$ID" \
      --query "Reservations[0].Instances[0].State.Name" \
      --output text --region "$AWS_REGION" 2>/dev/null || echo "missing")
    if [[ "$STATE" == "running" || "$STATE" == "stopped" || "$STATE" == "pending" || "$STATE" == "stopping" ]]; then
      VALID_IDS+=("$ID")
      echo "Keep $ID (state=$STATE)"
    else
      echo "Skip $ID (state=$STATE)"
    fi
  done

  if [ ${#VALID_IDS[@]} -gt 0 ]; then
    echo "Terminating: ${VALID_IDS[*]}"
    aws ec2 terminate-instances --instance-ids "${VALID_IDS[@]}" --region "$AWS_REGION"
    aws ec2 wait instance-terminated --instance-ids "${VALID_IDS[@]}" --region "$AWS_REGION"
  else
    echo "No valid instances to terminate."
  fi
else
  echo "No existing instances to terminate."
fi

# ENI cleanup
echo "Cleaning ENIs referencing emb0x-security-group..."
ENI_IDS=$(aws ec2 describe-network-interfaces \
  --filters "Name=group-name,Values=emb0x-security-group" \
  --query "NetworkInterfaces[].NetworkInterfaceId" \
  --output text --region "$AWS_REGION" || true)

if [ -n "$ENI_IDS" ]; then
  for ENI in $ENI_IDS; do
    [ -z "$ENI" ] && continue
    STATUS=$(aws ec2 describe-network-interfaces --network-interface-ids "$ENI" \
      --query "NetworkInterfaces[0].Status" --output text --region "$AWS_REGION" 2>/dev/null || echo "gone")
    [ "$STATUS" = "gone" ] && continue

    ATTACH_ID=$(aws ec2 describe-network-interfaces --network-interface-ids "$ENI" \
      --query "NetworkInterfaces[0].Attachment.AttachmentId" --output text --region "$AWS_REGION" 2>/dev/null || echo "None")
    DELETE_ON_TERM=$(aws ec2 describe-network-interfaces --network-interface-ids "$ENI" \
      --query "NetworkInterfaces[0].Attachment.DeleteOnTermination" --output text --region "$AWS_REGION" 2>/dev/null || echo "False")
    ASSOC_ID=$(aws ec2 describe-network-interfaces --network-interface-ids "$ENI" \
      --query "NetworkInterfaces[0].Association.AssociationId" --output text --region "$AWS_REGION" 2>/dev/null || echo "None")

    echo "ENI $ENI status=$STATUS attach=$ATTACH_ID primary=$DELETE_ON_TERM assoc=$ASSOC_ID"

    # Disassociate EIP first
    if [ "$ASSOC_ID" != "None" ]; then
      echo "Disassociating EIP from $ENI"
      aws ec2 disassociate-address --association-id "$ASSOC_ID" --region "$AWS_REGION" || true
    fi

    # Skip primary ENIs (auto-deleted)
    if [ "$ATTACH_ID" != "None" ] && [ "$DELETE_ON_TERM" = "True" ]; then
      echo "Primary ENI $ENI will be auto-deleted; skipping manual deletion."
      continue
    fi

    # Detach non-primary ENI
    if [ "$ATTACH_ID" != "None" ]; then
      echo "Detaching ENI $ENI"
      aws ec2 detach-network-interface --attachment-id "$ATTACH_ID" --region "$AWS_REGION" || true
    fi

    # Poll for available
    ATTEMPTS=0
    while [ $ATTEMPTS -lt 15 ]; do
      CUR=$(aws ec2 describe-network-interfaces --network-interface-ids "$ENI" \
        --query "NetworkInterfaces[0].Status" --output text --region "$AWS_REGION" 2>/dev/null || echo "gone")
      [ "$CUR" = "available" ] && break
      [ "$CUR" = "gone" ] && break
      sleep 2
      ATTEMPTS=$((ATTEMPTS+1))
    done

    # Delete if still present
    if aws ec2 delete-network-interface --network-interface-id "$ENI" --region "$AWS_REGION" 2>/dev/null; then
      echo "Deleted ENI $ENI"
    else
      echo "ENI $ENI still in use; will remain."
    fi
  done
else
  echo "No ENIs referencing emb0x-security-group."
fi

# Find SGs
SG_IDS=$(aws ec2 describe-security-groups \
  --filters "Name=group-name,Values=emb0x-security-group" \
  --query "SecurityGroups[].GroupId" \
  --output text --region "$AWS_REGION" || true)

if [ -n "$SG_IDS" ]; then
  echo "Processing SGs: $SG_IDS"
  for SG in $SG_IDS; do
    [ -z "$SG" ] && continue
    NAME=$(aws ec2 describe-security-groups --group-ids "$SG" --query "SecurityGroups[0].GroupName" --output text --region "$AWS_REGION")
    [ "$NAME" = "default" ] && { echo "Skip default $SG"; continue; }

    # Interface VPC endpoints referencing this SG
    VPCE_IDS=$(aws ec2 describe-vpc-endpoints \
      --filters "Name=vpc-endpoint-type,Values=Interface" \
      --query "VpcEndpoints[?contains(Groups[].GroupId, \`$SG\`)].VpcEndpointId" \
      --output text --region "$AWS_REGION" || true)

    if [ -n "$VPCE_IDS" ]; then
      echo "Deleting VPC interface endpoints using $SG: $VPCE_IDS"
      aws ec2 delete-vpc-endpoints --vpc-endpoint-ids $VPCE_IDS --region "$AWS_REGION" || echo "Failed deleting some endpoints."
    fi

    # ENIs using SG
    ENI_IDS=$(aws ec2 describe-network-interfaces \
      --filters "Name=group-id,Values=$SG" \
      --query "NetworkInterfaces[].NetworkInterfaceId" \
      --output text --region "$AWS_REGION" || true)

    if [ -n "$ENI_IDS" ]; then
      echo "Cleaning ENIs for $SG: $ENI_IDS"
      for ENI in $ENI_IDS; do
        [ -z "$ENI" ] && continue
        ASSOC=$(aws ec2 describe-network-interfaces --network-interface-ids "$ENI" \
          --query "NetworkInterfaces[0].Association.AssociationId" \
          --output text --region "$AWS_REGION" 2>/dev/null || echo "None")
        [ "$ASSOC" != "None" ] && aws ec2 disassociate-address --association-id "$ASSOC" --region "$AWS_REGION" || true

        ATTACH=$(aws ec2 describe-network-interfaces --network-interface-ids "$ENI" \
          --query "NetworkInterfaces[0].Attachment.AttachmentId" \
          --output text --region "$AWS_REGION" 2>/dev/null || echo "None")
        PRIMARY_FLAG=$(aws ec2 describe-network-interfaces --network-interface-ids "$ENI" \
          --query "NetworkInterfaces[0].Attachment.DeleteOnTermination" \
          --output text --region "$AWS_REGION" 2>/dev/null || echo "False")

        if [ "$ATTACH" != "None" ] && [ "$PRIMARY_FLAG" = "True" ]; then
          echo "Primary ENI $ENI waits for auto-delete."
        elif [ "$ATTACH" != "None" ]; then
          aws ec2 detach-network-interface --attachment-id "$ATTACH" --region "$AWS_REGION" || true
        fi

        for i in $(seq 1 15); do
          S=$(aws ec2 describe-network-interfaces --network-interface-ids "$ENI" \
            --query "NetworkInterfaces[0].Status" --output text --region "$AWS_REGION" 2>/dev/null || echo "gone")
            [ "$S" = "available" ] && break
            [ "$S" = "gone" ] && break
            sleep 2
        done
        aws ec2 delete-network-interface --network-interface-id "$ENI" --region "$AWS_REGION" 2>/dev/null || echo "ENI $ENI still in use."
      done
    fi

    if aws ec2 delete-security-group --group-id "$SG" --region "$AWS_REGION"; then
      echo "Deleted SG $SG"
    else
      echo "Retry delete after wait for $SG"
      sleep 5
      aws ec2 delete-security-group --group-id "$SG" --region "$AWS_REGION" || echo "Still in use: $SG"
    fi
  done
else
  echo "No emb0x-security-group groups."
fi

# Subnet teardown - this must happen prior to VPC teardown
SUBNET_IDS=$(aws ec2 describe-subnets \
  --filters "Name=tag:Name,Values=emb0x-subnet" \
  --query "Subnets[].SubnetId" \
  --output text \
  --region "$AWS_REGION")

if [ -n "$SUBNET_IDS" ]; then
  for SUBNET_ID in $SUBNET_IDS; do
    echo "Deleting subnet: $SUBNET_ID"
    aws ec2 delete-subnet --subnet-id "$SUBNET_ID" --region "$AWS_REGION" 2>/dev/null || echo "Could not delete subnet $SUBNET_ID."
  done
else
  echo "No subnets named emb0x-subnet found."
fi

# Delete all VPCs tagged emb0x-vpc
# Replace existing VPC teardown with this:
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