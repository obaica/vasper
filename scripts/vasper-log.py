#!/usr/bin/env python
# -*- coding: utf-8 -*-

###############################################################################
# show vasprun log
###############################################################################

### import modules
import os
from pprint import pprint
import argparse
import pandas as pd
from pymatgen.io import vasp as pmgvasp
import numpy as np
from vasper import vasp_io
import yaml

### Arg-parser
parser = argparse.ArgumentParser(
    description="This script shows log of vasprun. \
                 If you don't specify file path, \
                 this script reads files in the current directory")

### input files
parser.add_argument('-vf', '--vasprun_file', type=str, default='vasprun.xml',
                    help="input vasprun.xml file")
parser.add_argument('-os', '--oszicar_file', type=str, default='OSZICAR',
                    help="input oszicar file")
parser.add_argument('-log', '--vasper_file', type=str, default='vasper-log.yaml',
                    help="input vasper-log.yaml file")

### output option
parser.add_argument('-all', '--all_sum', action='store_true',
                    help="show all summary output from vasper-log.yaml")
parser.add_argument('-pr', '--params', action='store_true',
                    help="show vasp run all parameters, \
                          not just parameters written in INCAR")
parser.add_argument('-kp', '--kpoints', action='store_true',
                    help="show infomations about kpoints")
parser.add_argument('-ym', '--yaml', action='store_true',
                    help="make log file")
args = parser.parse_args()

### definitions
# def check_file_exist(filepath):
#     if not os.path.isfile(filepath):
#         raise ValueError("%s does not exist" % filepath)
#     else:
#         print("reading : %s" % filepath)
#
def export_log(data):
    """
    make 'vasper-log.yaml'
    """
    import yaml

    with open('vasper-log.yaml', 'w') as file:
        yaml.dump(data, file)

def read_files(filepath):
    """
    read file if possible
    """
    fname = os.path.basename(filepath)
    try:
        if fname == 'vasprun.xml':
            outobj = pmgvasp.outputs.Vasprun(filepath)
        if fname == 'OSZICAR':
            outobj = pmgvasp.outputs.Oszicar(filepath)
        if fname == 'vasper-log.yaml':
            with open(filepath) as f:
                outobj = yaml.load(f)
        print("read : %s" % filepath)
    except:
        outobj = None
        print("not read : %s" % filepath)
    return outobj

### main
if __name__ == "__main__":
    # check_file_exist(args.vasprun_file)
    vasprun = read_files(args.vasprun_file)
    oszicar = read_files(args.oszicar_file)
    vlog = read_files(args.vasper_file)

    if args.all_sum:
        print("")
        print("### vasper-log.yaml all summary")
        for key in vlog['all_summary'].keys():
            print(key + ' : ' + str(vlog['all_summary'][key]))

    if args.params:
        print("")
        print("")
        print("### VASP parameters")
        print("")
        pprint(vasprun.as_dict()['input']['parameters'])

    if args.kpoints:
        print("")
        print("")
        print("### kpoint infomations")
        print("")
        kpt = vasprun.as_dict()['input']['kpoints']['kpoints'][0]
        total_kpt = kpt[0] * kpt[1] * kpt[2]

        info = {}
        info['kpoints'] = vasprun.as_dict()['input']['kpoints']['kpoints']
        info['generation_style'] = vasprun.as_dict()['input'] \
                                       ['kpoints']['generation_style']
        info['shift'] = vasprun.as_dict()['input']['kpoints']['shift']
        info['usershift'] = vasprun.as_dict()['input']['kpoints']['usershift']
        info['total_kpoints'] = total_kpt
        info['nkpoints'] = vasprun.as_dict()['input']['nkpoints']
        pprint(info)
        print("'actual_points'")
        each_kpt = pd.DataFrame(
                       vasprun.as_dict()['input']['kpoints']['actual_points'])
        each_kpt['num'] = list(map(int, round(each_kpt['weight'] * total_kpt)))
        pprint(each_kpt)

    if args.yaml:
        if vasprun is None or oszicar is None:
            raise ValueError("You have to set both vasprun.xml and oszicar")
        summary = vasp_io.get_all_data(vasprun, oszicar)
        export_log(summary)
