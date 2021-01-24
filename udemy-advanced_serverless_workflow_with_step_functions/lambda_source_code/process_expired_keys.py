import boto3


iam_resource = boto3.resource("iam")
iam_client = boto3.client("iam")


def deactivate_user_key(user, key):
    # To-do: error handling if user has no tags
    for tag in iam_client.list_user_tags(UserName=user)["Tags"]:
        if tag["Key"].lower() in {"email", "e-mail"}:
            iam_client.update_access_key(
                UserName=user, AccessKeyId=key, Status="Inactive"
            )
        return tag["Value"]


def lambda_handler(event, context):
    if "UserName" in event and "AccessKey" in event:
        return deactivate_user_key(event["UserName"], event["AccessKey"])
