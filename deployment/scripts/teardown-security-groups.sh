#!/bin/bash

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