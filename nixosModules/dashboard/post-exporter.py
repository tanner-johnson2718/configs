#!/usr/bin/env python3

from prometheus_client import start_http_server, Counter, Gauge, generate_latest
from http.server import BaseHTTPRequestHandler, HTTPServer
import time
import os
import argparse

metrics = []

class Metric:
    def __init__(self, path, path_prefix, metric_prefix):
        tup = path.removeprefix(path_prefix + "/").split("/")

        self.metric_type = tup[0]
        self.metric_name = tup[1]
        self.path = path

        if self.metric_type == "counter":
            self.metric_obj = Counter(metric_prefix + "_" + self.metric_name, "")
        elif self.metric_type == "gauge":
            self.metric_obj = Gauge(metric_prefix + "_" + self.metric_name, "")
        else:
            print(f"ERROR unrecognized type {self.metric_type}")
            exit(1)

        with open(path, "r") as fd:
            val = fd.read()
        
        try:
            val = float(val)
        except:
            val = 0.0
        self.update(val)
    
    def update(self, val):
        if self.metric_type == "counter":
            self.metric_obj.inc(val)
        elif self.metric_type == "gauge":
            self.metric_obj.set(val)

        with open(self.path, "w") as fd:
                fd.write(str(self.metric_obj._value.get()))
                print(f'{self.metric_name}.collect()[0] = {self.metric_obj._value.get()}')

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

    def do_POST(self):
        try:
            content_length = int(self.headers['Content-Length'])
            post_data = self.rfile.read(content_length)
        except:
            self.send_response(404)
            self.end_headers()
            return

        tup = self.path.removeprefix("/").split("/")

        if  (len(tup) != 2) or (tup[0] != "metrics"):
            self.send_response(404)
            self.end_headers()
            return
        
        for m in metrics:
            if m.metric_name == tup[1]:
                name = m.metric_name
                m.update(float(post_data))
                self.send_response(200)
                self.send_header('Content-type', 'text/plain')
                self.end_headers()
                return

        self.send_response(404)
        self.end_headers()

        
    def get_metrics_data(self):
        
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
    parser.add_argument("-d", "--dir",)
    parser.add_argument("-r", "--prefix",)

    args = parser.parse_args()
    if check_arg("address", args) or check_arg("port", args) or check_arg("dir", args) or check_arg("prefix", args):
        exit(1)
   
    files = list_files_walk(getattr(args, "dir"))
    for f in files:
        metrics.append(Metric(f, getattr(args, "dir"), getattr(args, "prefix")))

    HTTPServer((getattr(args, "address"), int(getattr(args, "port"))), MetricsHandler).serve_forever()
