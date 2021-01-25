{
    "Comment":  "Access keys rotation workflow",
    "StartAt":  "Get Expired Keys",
    "States":   {
        "Get Expired Keys": {
            "Type": "Parallel",
            "End": true,
            "Branches": [
                {
                    "StartAt": "GetUserKeys",
                    "States": {
                        "GetUserKeys": {
                            "Type": "Task",
                            "Resource": "${get_expired_keys_lambda}",
                            "Parameters": {
                                "UserPath": "/test_users/",
                                "MaxKeyAge": 1
                            },
                            "Next": "ProcessExpiredUserKeys"
                        },
                        "ProcessExpiredUserKeys": {
                            "Type": "Map",
                            "ItemsPath": "$.Users",
                            "MaxConcurrency": 0,
                            "Iterator": {
                                "StartAt": "DisableUserKeys",
                                "States": {
                                    "DisableUserKeys": {
                                        "Type": "Task",
                                        "End": true
                                        "Resource": "${process_expired_keys_lambda}"
                                    }
                                }
                            }
                            "End": true
                        }
                    }
                },
                {
                    "StartAt": "GetServiceAccountsKeys",
                    "States": {
                        "GetServiceAccountsKeys": {
                            "Type": "Task",
                            "Resource": "${get_expired_keys_lambda}",
                            "Parameters": {
                                "UserPath": "/service_accounts/",
                                "MaxKeyAge": 1
                            },
                            "End": true
                        }
                    }
                }
            ]
        }
    }
}