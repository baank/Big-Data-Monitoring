#!/usr/bin/env python

import argparse
import json
import requests
import sys


class CheckRegionBalance(object):
    def __init__(self):
        ap = argparse.ArgumentParser()
        ap.add_argument('--host', type=str, required=True, help='NameNode hostname')
        ap.add_argument('--c', type=float, default=0.75, required=True,
                        help='Critical threshold (expressed as float between 0 and 1')
        args = ap.parse_args()
        self.master = args.host
        self.threshold = args.c
        self.status = 0
        if self.is_active():
            self.regionservers = self.get_regionservers()
            self.region_counts = self.get_regions()
            self.avg = self.get_avg()
            self.check_counts()
        else:
            print 'OK - Host is standby.'
        sys.exit(self.status)

    def get_json(self, url):
        try:
            req = requests.get(url)
            return json.loads(req.text)
        except Exception as err:
            print 'UNKNOWN - Could not connect to %s' % url
            sys.exit(3)

    def is_active(self):
        ret = self.get_json('http://%s:60010/jmx' % self.master)
        for bean in ret['beans']:
            if 'Hadoop:service=HBase,name=Master,sub=Server' in bean['name']:
                if 'true' in bean['tag.isActiveMaster']:
                    return True
                else:
                    return False

    def get_regionservers(self):
        ret = self.get_json('http://%s:60010/jmx' % self.master)
        regionservers = []
        for bean in ret['beans']:
            if 'Hadoop:service=HBase,name=Master,sub=Server' in bean['name']:
                rs_raw = bean['tag.liveRegionServers'].split(';')
                for rs in rs_raw:
                    regionservers.append(rs.split(',')[0])
        return regionservers

    def get_regions(self):
        counts = {}
        for rs in self.regionservers:
            req = requests.get('http://%s:60030/jmx' % rs)
            ret = json.loads(req.text)
            for bean in ret['beans']:
                if 'Hadoop:service=HBase,name=RegionServer,sub=Server' in bean['name']:
                    counts[rs] = bean['regionCount']
        return counts

    def get_avg(self):
        nums = []
        for rs in self.region_counts:
            nums.append(self.region_counts[rs])
        return float(sum(nums) / len(nums))

    def check_counts(self):
        for rs in self.region_counts:
            if (self.region_counts[rs] / self.avg) < self.threshold:
                print 'CRITICAL - %s is below region threshold.  Value: %s' % (rs, self.region_counts[rs])
                self.status = 2
            else:
                print 'OK - %s is: %s' % (rs, self.region_counts[rs])


crb = CheckRegionBalance()
