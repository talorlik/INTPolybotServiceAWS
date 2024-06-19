from flask import Flask, request, jsonify
import os
from bot import BotFactory
from bot_utils import get_secret_value
from process_results import ProcessResults
from process_messages import ProcessMessages

app = Flask(__name__, static_url_path='')
app.config['UPLOAD_FOLDER'] = 'static/uploads'

response = get_secret_value('us-east-1', 'talo/telegram/token', 'TELEGRAM_TOKEN')
if response[1] != 200:
    raise ValueError(response[0])

TELEGRAM_TOKEN = response[0]
TELEGRAM_APP_URL = os.environ['TELEGRAM_APP_URL']

response = get_secret_value('us-east-1', 'talo/domain/certificate', 'DOMAIN_CERTIFICATE')
if response[1] != 200:
    raise ValueError(response[0])

DOMAIN_CERTIFICATE = response[0]

bot_factory = BotFactory(TELEGRAM_TOKEN, TELEGRAM_APP_URL, DOMAIN_CERTIFICATE)

# Start the consume thread when the application starts
process_results_thread = ProcessResults(bot_factory)
process_results_thread.start()

process_messages_thread = ProcessMessages(bot_factory)
process_messages_thread.start()

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

    process_messages_thread.message_queue.put(msg)

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

    process_messages_thread.message_queue.put(msg)

    return 'Ok', 200

if __name__ == "__main__":
    app.run(host='0.0.0.0', port=8443)
