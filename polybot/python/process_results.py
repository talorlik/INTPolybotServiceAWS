from threading import Thread
import boto3
import os

class ProcessResults(Thread):
    def __init__(self, bot_factory):
        Thread.__init__(self)
        self.bot_factory = bot_factory
        self.sqs_client = boto3.client('sqs', region_name=os.environ['AWS_DEFAULT_REGION'])
        self.queue_name = os.environ['SQS_QUEUE_RESULTS']

    def run(self):
        while True:
            response = self.sqs_client.receive_message(QueueUrl=self.queue_name, MaxNumberOfMessages=1, WaitTimeSeconds=5)

            if 'Messages' in response:
                message = response['Messages'][0]['Body']
                receipt_handle = response['Messages'][0]['ReceiptHandle']

                # Process the message here, you may need to adapt this part
                # Assuming you have a way to get a bot and a prediction_id from the message
                msg = message.get("message")
                bot = self.bot_factory.get_bot(msg)

                # Handle the message with the bot
                bot.handle_message(msg)

                # Delete the message from the queue as the job is considered as DONE
                self.sqs_client.delete_message(QueueUrl=self.queue_name, ReceiptHandle=receipt_handle)
