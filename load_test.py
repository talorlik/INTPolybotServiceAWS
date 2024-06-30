import boto3
from botocore import exceptions as boto_exceptions
import time
import json

def send_to_sqs(queue_name, message_body):
    try:
        sqs_client = boto3.client('sqs')
    except boto_exceptions.ProfileNotFound as e:
        print(f"Sending message to SQS failed. A ProfileNotFound has occurred.\n{str(e)}")
        return f"Sending message to SQS failed. A ProfileNotFound has occurred.", 500
    except boto_exceptions.EndpointConnectionError as e:
        print(f"Sending message to SQS failed. An EndpointConnectionError has occurred.\n{str(e)}")
        return f"Sending message to SQS failed. An EndpointConnectionError has occurred.", 500
    except boto_exceptions.NoCredentialsError as e:
        print(f"Sending message to SQS failed. A NoCredentialsError has occurred.\n{str(e)}")
        return f"Sending message to SQS failed. A NoCredentialsError has occurred.", 500
    except boto_exceptions.ClientError as e:
        print(f"Sending message to SQS failed. A ClientError has occurred.\n{str(e)}")
        return f"Sending message to SQS failed. A ClientError has occurred.", 500
    except Exception as e:
        print(f"Sending message to SQS failed. An Unknown {type(e).__name__} has occurred.\n{str(e)}")
        return f"Sending message to SQS failed. An Unknown {type(e).__name__} has occurred.", 500

    try:
        response = sqs_client.send_message(
            QueueUrl=queue_name,
            MessageBody=message_body
        )
    except boto_exceptions.ParamValidationError as e:
        print(f"Sending message to SQS failed. A ParamValidationError has occurred.\n{str(e)}")
        return f"Sending message to SQS failed. A ParamValidationError has occurred.", 500
    except boto_exceptions.ClientError as e:
        print(f"Sending message to SQS failed. A ClientError has occurred.\n{str(e)}")
        return f"Sending message to SQS failed. A ClientError has occurred.", 500
    except Exception as e:
        print(f"Sending message to SQS failed. An Unknown {type(e).__name__} has occurred.\n{str(e)}")
        return f"Sending message to SQS failed. An Unknown {type(e).__name__} has occurred.", 500

    print(f"Message sent successfully. Message ID: {response['MessageId']}")
    return f"Message sent successfully. Message ID: {response['MessageId']}", 200

image_list = [
    "image-1.jpg",
    "image-2.jpg",
    "image-3.jpg",
    "image-4.jpg",
    "image-5.jpg",
    "image-6.jpg",
    "image-7.jpg",
    "image-8.jpg",
    "image-9.jpg",
    "image-10.jpg",
    "image-11.jpg",
    "image-12.jpg",
    "image-13.jpg",
    "image-14.jpg",
    "image-15.jpg",
    "image-16.jpg",
    "image-17.jpg",
    "image-18.jpg",
    "image-19.jpg",
    "image-20.jpg",
    "image-21.jpg",
    "image-22.jpg",
    "image-23.jpg",
    "image-24.jpg",
    "image-25.jpg",
    "image-26.jpg",
    "image-27.jpg",
    "image-28.jpg",
    "image-29.jpg",
    "image-30.jpg",
    "image-31.jpg",
    "image-32.jpg",
    "image-33.jpg",
    "image-34.jpg",
    "image-35.jpg",
    "image-36.jpg",
    "image-37.jpg",
    "image-38.jpg",
    "image-39.jpg",
    "image-40.jpg",
    "image-41.jpg",
    "image-42.jpg",
    "image-43.jpg",
    "image-44.jpg",
    "image-45.jpg",
    "image-46.jpg",
    "image-47.jpg",
    "image-48.jpg",
    "image-49.jpg",
    "image-50.jpg",
]

for img in image_list:
    message_dict = {
        "chatId": str("7101922782"),
        "imgName": img
    }

    # Send message to the identify queue for the Yolo5 service to pick up
    response = send_to_sqs("talo-sqs-identify", json.dumps(message_dict))

    if int(response[1]) != 200:
        print(response[0])
        break

print("Complete!")