aws_sec_group_description n="0":
  aws ec2 describe-security-groups --query "SecurityGroups[{{ n }}]" | jq

aws_sec_groups:
  aws ec2 describe-security-groups --query "SecurityGroups[*].[GroupId,GroupName,VpcId]" --output table

aws_ec2_instance_description n="0":
  aws ec2 describe-instances --query "Reservations[0].Instances[{{ n }}]" | jq

aws_ec2_instances:
  aws ec2 describe-instances \
  --query "Reservations[*].Instances[*].{\
      ID: InstanceId,\
      Name: Tags[?Key=='Name'].Value | [0],\
      Type: InstanceType,\
      State: State.Name,\
      PublicIP: PublicIpAddress,\
      SecurityGroups: SecurityGroups[*].GroupName | join(', ', @)\
    }" \
  --output table

aws_ec2_instance_name_2_id name:
    aws ec2 describe-instances \
      --filters "Name=tag:Name,Values={{ name }}" \
      --query "Reservations[*].Instances[*].InstanceId" \
      --output text

aws_ec2_start name:
  aws ec2 start-instances --instance-ids $(just aws_ec2_instance_name_2_id {{ name }} )
aws_ec2_stop name:
  aws ec2 stop-instances --instance-ids $(just aws_ec2_instance_name_2_id {{ name }} )
