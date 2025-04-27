#!/usr/bin/env python3

from prometheus_client import start_http_server, Counter, Gauge
from http.server import BaseHTTPRequestHandler, HTTPServer
import time
import os
import argparse

metrics = []

class Metric:
    def __init__(self, path, prefix):
        tup = path.removeprefix(prefix + "/").split("/")

        self.port = tup[0]
        self.metric_type = tup[1]
        self.metric_name = tup[2]
        self.path = path
        self.fd = open(path, "r")
        self.value = 0.0

        try:
            self.value = float(self.fd.read())
        except:
            self.fd.close()
            self.fd = open(path, "w")
            self.fd.write("0.0")
            self.fd.close()
            self.fd =open(path, "r")

        if self.metric_type == "counter":
            self.metric_obj = Counter("fnode_" + self.metric_name, "")
        elif self.metric_type == "gauge":
            self.metric_obj = Gauge("fnode_" + self.metric_name, "")
        else:
            print(f"ERROR unrecognized type {self.metric_type}")

    def update(self):
        self.fd.seek(0)
        if self.metric_type == "counter":
            value_now = float(self.fd.read())
            if value_now > self.value:
                self.value = value_now
        elif self.metric_type == "gauge":
            self.value = self.fd.read()

class MetricsHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/metrics':
            self.send_response(200)
            self.send_header('Content-Type', 'text/plain; version=0.0.4')
            self.end_headers()
            self.wfile.write(self.get_metrics_data().encode('utf-8'))
        else:
            self.send_response(404)
            self.end_headers()

    def get_metrics_data(self):
        for m in metrics:
            m.update()
            print(f'{m.metric_name} = {m.value}')
        from prometheus_client import generate_latest
        return generate_latest().decode('utf-8')

def check_arg(arg, args):
    if hasattr(args, arg):
        if getattr(args, arg) is not None:
            return 0
        else:
            print(f"Argument {arg} exists but was not provided.")
    else:
        print(f"Argument --{arg} does not exist.")

    return 1

def list_files_walk(dir):
    ret = []
    for root, dirs, files in os.walk(dir):
        for file in files:
            ret.append(os.path.join(root, file))
    return ret

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument("-a", "--address",)
    parser.add_argument("-p", "--port",)
    parser.add_argument("-d","--dir",)

    args = parser.parse_args()
    if check_arg("address", args) or check_arg("port", args) or check_arg("dir", args):
        exit(1)
   
    files = list_files_walk(getattr(args, "dir"))
    for f in files:
        metrics.append(Metric(f, getattr(args, "dir")))

    HTTPServer((getattr(args, "address"), int(getattr(args, "port"))), MetricsHandler).serve_forever()
