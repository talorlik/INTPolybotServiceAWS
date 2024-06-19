from threading import Thread
import queue

class ProcessMessages(Thread):
    def __init__(self, bot_factory):
        Thread.__init__(self)
        self.bot_factory = bot_factory
        # Create a queue for the ProcessMessages thread
        self.message_queue = queue.Queue()

    def run(self):
        while True:
            msg = self.message_queue.get()
            if msg:
                bot = self.bot_factory.get_bot(msg)
                bot.handle_message(msg)