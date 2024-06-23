from threading import Thread
import queue
from loguru import logger

class ProcessMessages(Thread):
    def __init__(self, bot_factory):
        Thread.__init__(self)
        self.bot_factory = bot_factory
        # Create a queue for the ProcessMessages thread
        logger.info("Queue initiated.")
        self.message_queue = queue.Queue()

    def run(self):
        logger.info("Queue is running.")
        while True:
            msg = self.message_queue.get()
            if msg:
                logger.info(f"Message received from queue:\n{msg}")
                bot = self.bot_factory.get_bot(msg)
                bot.handle_message(msg)