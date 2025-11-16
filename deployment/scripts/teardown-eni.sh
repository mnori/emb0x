#!/bin/bash

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