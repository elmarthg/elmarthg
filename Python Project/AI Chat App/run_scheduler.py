
import threading
import time
from utils.scheduler import send_reminder

def run_scheduler():
    while True:
        send_reminder()
        time.sleep(60)  # Check reminders every minute

if __name__ == '__main__':
    scheduler_thread = threading.Thread(target=run_scheduler)
    scheduler_thread.start()
