#!/ms/dist/python/PROJ/core/2.7.1/bin/python
#-*- coding:utf8 -*-

import sys
import os
import argparse
import tempfile
import time
import re
import getpass
import uuid

import subprocess
from subprocess import PIPE

from multiprocessing import Process
from multiprocessing import Queue

import ms.version
ms.version.addpkg("ms.log", "1.0.6")
ms.version.addpkg("ms.modulecmd", "1.0.4")
ms.version.addpkg("kazoo", "1.2.1")
ms.version.addpkg("zope.interface", "3.6.1")
ms.version.addpkg("paramiko", "1.7.6")
ms.version.addpkg("Crypto", "2.3")

import ms.log
import paramiko
from kazoo.client import KazooClient

VERSION = "0.1"
LOG = ms.log.Log(__name__)

SSH = "/ms/dist/sec/PROJ/openssh/prod/bin/ssh"
KEYTAB = "/ms/dist/aurora/bin/krb5_keytab"
ZK_CONN_STR = "hn805c2n2:2281,hzias1095:2281,ds975c1n16:2281"
LOG_DIR_PATTERN = "/var/zapplets/%s/root/zapplet*/logs/"


def setup_logger(args):
    """setup the configuration for logging."""
    if args.debug:
        level = ms.log.LogDebug
    elif args.quiet:
        level = ms.log.LogAlert
    else:
        level = ms.log.LogErr
    LOG.add_destination(ms.log.StderrDestination(), level)
    if args.log_file:
        LOG.add_destination(ms.log.FileDestination(file=args.log_file), level)


def setup_parser():
    """Set up the parser.

    Returns:
        argparse.ArgumentParser with all the arguments configured
    """

    description = ('This script can be used to search broker logs quickly with'
                   'given pattern. For example: \n\n'
                   "\n Find logs with request id 'd967619e-6237-45df-9def-8e27903bbc3b' in DEV DAL\n"
                   '\n$ log_finder_parallel.py --env dev d967619e-6237-45df-9def-8e27903bbc3b\n'
                   "\n Find all the occurrences of log lines matching 'chaoc' in qa:ln\n"
                   '\n$ log_finder_parallel.py --env qaln --all chaoc\n'
                   "\n Find the logs related with obliteration of TrendTrade on 20131125 in qa\n"
                   '\n$ log_finder_parallel.py --env qa --date 20131125 Obliterate.*TrendTrade\n'
                   '\nType log_finder_parallel.py -h or --help for more details.\n')

    parser = argparse.ArgumentParser(description=description, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('--debug', dest='debug', action='store_true', help='enable all debugging output in logs')
    parser.add_argument('-q', '--quiet', dest='quiet', action='store_true', help='disable all log messages ')
    parser.add_argument('--log-file', help='redirect the logs to the file specified (logs go to stderr by default)')
    parser.add_argument('--version', action='version', version='%(prog)s ' + VERSION)

    parser.add_argument('-a', '--all', action='store_true', help='find all the occurrences of the pattern in all log files')
    parser.add_argument('-e', '--env', default='dev', help='the DAL env with the format consistent with zkui(dev,devhk,prod2,qaln,...)')
    parser.add_argument('--host', dest='host', help="the broker host, it will only search the logs on the host if specified")
    parser.add_argument('-d', '--date', dest='date', help="with the format 'YYYYmmdd', it will only search the log files cover the given date")
    parser.add_argument('pattern', help='the pattern you want to search')

    return parser


def get_broker_hosts(env):
    zk = KazooClient(hosts=ZK_CONN_STR)
    zk.start()

    path = "/optimus/brokers/%s" % env
    if zk.exists(path):
        LOG.info("Getting broker nodes under %s" % path)
        nodes = zk.get_children(path)
        hosts = []
        for node in nodes:
            data, stat = zk.get("%s/%s" % (path, node))
            # the data is in "scheme://host:port" format
            hosts.append(data.split("//")[1].split(":")[0])
        return hosts
    else:
        LOG.error("No brokers registered under %s" % path)
        sys.exit(-1)


def search_pattern(res_queue, pattern, host, date, search_all=False):
    cmd = "find %s -name '*_broker*'" % (LOG_DIR_PATTERN % host)
    LOG.debug("Running cmd: [%s]@%s to get all the directories for broker logs." % (cmd, host))
    stdoutdata, stderrdata = subprocess.Popen([SSH, '-o', 'StrictHostKeyChecking=no', host, cmd], stdout=PIPE, stderr=PIPE).communicate()
    if not stderrdata:
        LOG.warning("Cmd [%s] failed, details: %s" % (cmd, stderrdata))

    log_dirs = filter(lambda v: v.strip(), map(str.strip, stdoutdata.split('\n')))

    if not log_dirs: LOG.debug("No broker log directories found, the provided host [%s] is not correct?" % host)

    # return a list of (log_file, greped lines)
    res = []
    for log_dir in log_dirs:
        LOG.debug("searhing in %s:%s" % (host, log_dir))
        if date:
            cmd = "cd %s; ls -1 -t *%s*.gz" % (log_dir, date)
        else:
            cmd = "cd %s; ls -1 -t *.gz *.log" % log_dir

        LOG.debug("Running cmd: [%s]@%s to get all the broker log files." % (cmd, host))
        stdoutdata, stderrdata = subprocess.Popen([SSH, '-o', 'StrictHostKeyChecking=no', host, cmd], stdout=PIPE, stderr=PIPE).communicate()
        if not stderrdata:
            LOG.warning("Cmd [%s] failed, details: %s" % (cmd, stderrdata))

        log_files = filter(lambda v: v.strip(), map(str.strip, stdoutdata.split('\n')))

        if not log_files: LOG.debug("No log files found in directory [%s] @ host [%s]" % (log_dir, host))

        for log_file in log_files:
            LOG.debug("the current log file is: " + log_file)
            if log_file.endswith("gz"):
                cmd = "zcat %s | grep -e %s" % (log_dir+ "/" + log_file, pattern)
            else:
                cmd = "grep -e %s %s" % (pattern, log_dir+ "/" + log_file)
            LOG.debug("Running cmd: [%s]@%s to search the pattern [%s] in log [%s]." % (cmd, host, pattern, log_file))
            # use a tmp file to store the matched lines, avoid consuming too much memory if the output is huge
            tf = tempfile.NamedTemporaryFile(delete=False)
            proc = subprocess.Popen([SSH, '-o', 'StrictHostKeyChecking=no', host, cmd], stdout=tf, stderr=PIPE)
            while proc.poll() is None:
                LOG.debug("still greping ... ")
                time.sleep(5)
            if proc.returncode == 0:
                LOG.info("Found a new matched log file [%s:%s], adding it into result" % (host, log_file))
                LOG.debug("Stored the matched log lines in the temp file: %s" % tf.name)
                res.append((host, log_dir + '/' + log_file, tf.name))
                if not search_all:
                    # return immediately after the first occurrence
                    res_queue.put(res)
                    return
    # an empty list will be put in when nothing found in the current process
    LOG.debug("Done with searching on %s, found %d log files matched, res = %s" % (host, len(res), res))
    res_queue.put(res)


def show_result(res_item):
    for host, log_file, content_file in res_item:
        print "host: %s, file: %s" % (host, log_file)
        print "-" * 80
        with open(content_file) as c:
            for line in c:
                print line.strip()
        # the content file is a NamedTempfile created earlier, it's useless after showing the content
        # delete it explicitly here to avoid the leak (although it will be cleanup on reboot)
        if os.path.isfile(content_file):
            os.remove(content_file)
            LOG.debug("Deleted the temp file: %s" % content_file)


def main():
    parser = setup_parser()
    args = parser.parse_args()
    setup_logger(args)

    # the element in the result_queue is a list of tuples like: [(host_name, log_file_name, tmp_file_name_for_matched_conent), ..., ]
    result_queue = Queue()

    hosts = [args.host] if (args.host) else get_broker_hosts(args.env)
    processes = []
    for host in hosts:
        proc = Process(target=search_pattern, name="Searcher-%s-%s-%s" % (host, args.pattern, uuid.uuid4()), args=(result_queue, args.pattern, host, args.date, args.all))
        processes.append(proc)
        proc.daemon = True
        proc.start()
        LOG.debug("Daemon process [%s] started" % proc.name)


    return_code = 0
    if args.all:
        # wait for all the processes to finished
        num_items_expected = len(processes)
        num_received = 0
        found = False
        while num_received < num_items_expected:
            cur_res_item = result_queue.get()
            num_received += 1
            if cur_res_item:
                found = True
                show_result(cur_res_item)
            time.sleep(5)
        if not found:
            print "Pattern [%s] not found" % args.pattern
            return_code = 1
    else:
        num_done = 0
        while True:
            res_item = result_queue.get()
            num_done += 1
            if res_item:
                # finish searching when there is any res in the queue
                show_result(res_item)
                break
            # when all the processes are done and nothing found
            if num_done == len(processes):
                print "Pattern [%s] not found" % args.pattern
                return_code = 1
                break

    # FIXME:
    # clean up temp files in the result queue if there are still any
    while (not result_queue.empty()):
        item = result_queue.get_nowait()
        for (_, _, content_file) in item:
            if os.path.isfile(content_file):
                os.remove(content_file)
                LOG.debug("Deleted the temp file: %s" % content_file)

    return return_code


if __name__ == '__main__':
    main()
