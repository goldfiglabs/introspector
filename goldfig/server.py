from flask import Flask
from werkzeug.serving import run_simple

app = Flask(__name__)


@app.route('/')
def hello_world() -> str:
  return 'Hello world'


def run_webserver():
  run_simple('localhost', 5000, app)