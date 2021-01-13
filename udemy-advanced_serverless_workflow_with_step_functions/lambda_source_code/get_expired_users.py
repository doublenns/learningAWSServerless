import boto3
from datetime import datetime, timezone


# boto3.setup_default_session(profile_name="default")

iam_resource = boto3.resource("iam")
iam_client = boto3.client("iam")


def _time_diff(datekeycreated):
    now = datetime.now(timezone.utc)
    diff = now - datekeycreated
    return diff.days


def get_iam_accounts():
    iam_accounts = {}
    for user in iam_resource.users.all():
        user_data = iam_client.get_user(UserName=user.name)["User"]
        iam_accounts[user_data["UserName"]] = user_data["Path"]
    return iam_accounts


def get_expired_keys(event, context):
    result = {}
    expired_keys = []

    for username, path in get_iam_accounts().items():
        if path == event["UserPath"]:
        # if path == "/test_users/":
            metadata = iam_client.list_access_keys(UserName=username)
            if metadata["AccessKeyMetadata"]:
                for key in metadata["AccessKeyMetadata"]:
                    key_age = _time_diff(key["CreateDate"])
                    if key["Status"] == "Active" and (
                        # key_age > 30
                        key_age > event["MaxKeyAge"]
                    ):
                        expired_keys.append(
                            {
                                "UserName": username,
                                "AccessKey": key["AccessKeyId"],
                                "KeyAge": key_age,
                                "UserPath": path
                            }
                        )
    result["Users"] = expired_keys
    return result


def main():
    print(get_expired_keys("event", "context"))


if __name__ == "__main__":
    main()
