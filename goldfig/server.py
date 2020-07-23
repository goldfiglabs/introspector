import os

from flask import Flask, request, redirect, url_for, send_from_directory

app = Flask(__name__, static_url_path='', static_folder='../schema-docs/')


@app.route('/')
def root():
  return app.send_static_file('index.html')


@app.route('/<path:path>')
def static_file(path):
  return app.send_static_file(path)


def run_webserver():
  app.run(host='0.0.0.0')
