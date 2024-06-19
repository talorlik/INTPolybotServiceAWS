from flask import Flask, request, jsonify
from threading import Thread
import os
from bot import BotFactory
from bot_utils import get_secret, create_certificate_from_secret
import boto3
from process_results import ProcessResults

app = Flask(__name__, static_url_path='')
app.config['UPLOAD_FOLDER'] = 'static/uploads'

response = get_secret('talo/telegram/token', 'us-east-1')
if response[1] != 200:
    raise ValueError(response[0])

TELEGRAM_TOKEN = response[0]
TELEGRAM_APP_URL = os.environ['TELEGRAM_APP_URL']

response = create_certificate_from_secret('talo-polybot.pem', 'talo/domain/certificate', 'us-east-1')
if response[1] != 200:
    raise ValueError(response[0])

DOMAIN_CERTIFICATE = response[0]

queue_results = os.environ['SQS_QUEUE_RESULTS']

bot_factory = BotFactory(TELEGRAM_TOKEN, TELEGRAM_APP_URL, DOMAIN_CERTIFICATE)

# Start the consume thread when the application starts
process_results_thread = ProcessResults(bot_factory, queue_results)
process_results_thread.start()

class Compute(Thread):
    def __init__(self, bot, msg):
        Thread.__init__(self)
        self.bot = bot
        self.msg = msg

    def run(self):
        self.bot.handle_message(self.msg)

@app.route('/', methods=['GET'])
def index():
    return 'Ok', 200

@app.route('/health', methods=['GET'])
def health():
    return jsonify({"status": "healthy", "message": "Service is up and running!"}), 200

@app.route(f'/{TELEGRAM_TOKEN}/', methods=['POST'])
def webhook():
    req = request.get_json()
    if "message" in req:
        msg = req['message']
    elif "edited_message" in req:
        msg = req['edited_message']
    else:
        return 'No message', 400

    bot = bot_factory.get_bot(msg)

    msg_thread = Compute(bot, msg)
    msg_thread.start()
    return 'Ok', 200

@app.route(f'/loadTest/', methods=['POST'])
def load_test():
    req = request.get_json()
    if "message" in req:
        msg = req['message']
    elif "edited_message" in req:
        msg = req['edited_message']
    else:
        return 'No message', 400

    bot = bot_factory.get_bot(msg)

    msg_thread = Compute(bot, msg)
    msg_thread.start()
    return 'Ok', 200

if __name__ == "__main__":
    app.run(host='0.0.0.0', port=8443)
