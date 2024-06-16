from flask import jsonify
from yolo_utils import identify, write_to_db, send_to_sqs
import boto3
import os
from loguru import logger

region_name = os.environ['AWS_DEFAULT_REGION']
queue_identify = os.environ['SQS_QUEUE_IDENTIFY']
queue_results = os.environ['SQS_QUEUE_RESULTS']

sqs_client = boto3.client('sqs', region_name=region_name)

def consume():
    while True:
        response = sqs_client.receive_message(QueueUrl=queue_identify, MaxNumberOfMessages=1, WaitTimeSeconds=5)

        if 'Messages' in response:
            message = response['Messages'][0]['Body']
            receipt_handle = response['Messages'][0]['ReceiptHandle']

            # Use the ReceiptHandle as a prediction UUID
            prediction_id = response['Messages'][0]['MessageId']

            # Receives a URL parameter representing the image to download from S3
            img_name = message.get('imgName')
            chat_id = message.get('chatId')

            # Execute the identification process on the image
            response = identify(img_name, prediction_id)

            message_response = {
                "message": {
                    "prediction_id": prediction_id,
                    "chat": {"id": chat_id},
                    "photo": True,
                    "caption": "prediction_result"
                }
            }

            if response[1] != 200:
                logger.exception(response[0])
            else:
                response = write_to_db(chat_id, response[0])

                if response[1] != 200:
                    logger.exception(response[0])

            # Delete the message from the queue as the job is considered as DONE
            sqs_client.delete_message(QueueUrl=queue_identify, ReceiptHandle=receipt_handle)

            message_response["message"]["status_code"] = response[1]
            message_response["message"]["text"] = jsonify(response[0])

            response = send_to_sqs(queue_results, message_response)

            if response[1] != 200:
                logger.exception(response[0])

if __name__ == "__main__":
    consume()
