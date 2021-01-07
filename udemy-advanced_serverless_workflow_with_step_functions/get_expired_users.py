import boto3

iam_resource = boto3.resource("iam")
iam_client = boto3.client("iam")

def get_iam_accounts():
    iam_accounts = {}
    for user in iam_resource.users.all():
        user_data = iam_client.get_user(UserName=user.name)["User"]
        iam_accounts[user_data["UserName"]] = user_data["Path"]
    return iam_accounts

def main():
    get_iam_accounts()
    print(get_iam_accounts())


if __name__ == "__main__":
    main()