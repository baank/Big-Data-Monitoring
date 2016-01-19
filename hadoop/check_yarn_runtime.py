#!/usr/bin/env python

import argparse
import json
import logging
import requests
import sys


class YARNTime(object):
    def __init__(self):
        self.args = self.get_args()
        self.warn = self.args.warn
        self.crit = self.args.crit
        self.queue = self.args.queue
        if self.args.debug:
            logging.basicConfig(level=logging.DEBUG)
            logging.debug('Debugging enabled...')
        try:
            if self.args.ha and self.is_standby():
                print 'OK: Host is standby.'
                sys.exit(0)
            apps = self.get_metrics()['apps']['app']
            runtimes = self.get_app_runtime(apps)
        except requests.exceptions.ConnectionError as err:
            print 'WARNING: Could not connect to host.'
            sys.exit(3)
        runtime_map = self.get_runtime_map(runtimes)
        self.print_and_exit(runtime_map)

    def get_app_runtime(self, apps):
        apptimes = {}
        for app in apps:
            if not app['finishedTime'] and self.queue in app['queue']:
                logging.debug('Found app in queue: %s' % app)
                apptimes[app['id']] = app['elapsedTime']
            else:
                logging.debug('Skipping app not in queue: %s' % app)
        logging.debug(apptimes)
        return apptimes

    def get_metrics(self):
        url = '%s/ws/v1/cluster/apps' % self.args.url
        req = requests.get(url)
        logging.debug(json.loads(req.text)['apps']['app'])
        return json.loads(req.text)

    def get_runtime_map(self, runtimes):
        app_list = {'crit_list': {}, 'warn_list': {}}
        for app in runtimes:
            if runtimes[app] >= self.crit:
                app_list['crit_list'][app] = runtimes[app]
            elif runtimes[app] >= self.warn:
                app_list['warn_list'][app] = runtimes[app]
        logging.debug(app_list)
        return app_list

    def is_standby(self):
        req = requests.get('%s/ws/v1/cluster/info' % self.args.url)
        resp = json.loads(req.text)
        if 'ACTIVE' not in resp['clusterInfo']['haState']:
            return True
        else:
            return False

    def print_and_exit(self, runtime_map):
        exit_code = self.get_exit_code(runtime_map)
        exit_map = {
            0: ['OK', 'Jobs are running properly'],
            1: ['WARNING', 'Jobs have exceeded the warning duration threshold.'],
            2: ['CRITICAL', 'Jobs have exceeded the critical duration threshold.'],
            3: 'UNKNOWN',
        }
        print '%s: %s  Critical = %s, Warning = %s, Queue = %s' % (
            exit_map[exit_code][0], exit_map[exit_code][1], self.crit, self.warn, self.queue)
        for app in runtime_map['crit_list']:
            print 'CRITICAL - %s: %s' % (app, runtime_map['crit_list'][app])
        for app in runtime_map['warn_list']:
            print 'WARNING - %s: %s' % (app, runtime_map['warn_list'][app])
        sys.exit(exit_code)

    @staticmethod
    def get_args():
        parser = argparse.ArgumentParser()
        parser.add_argument('--url', type=str, required=True, help='ResourceManager URL')
        parser.add_argument('--queue', type=str, required=True, help='Queue to monitor')
        parser.add_argument('--warn', type=int, required=True, help='Warning threshold (milliseconds)')
        parser.add_argument('--crit', type=int, required=True, help='Critical threshold (milliseconds)')
        parser.add_argument('--ha', action='store_true', help='ResourceManager is HA')
        parser.add_argument('--debug', action='store_true', help='Enable debugging')
        return parser.parse_args()

    @staticmethod
    def get_exit_code(runtime_map):
        if len(runtime_map['crit_list']) > 0:
            return 2
        elif len(runtime_map['warn_list']) > 0:
            return 1
        return 0


mrr = YARNTime()
