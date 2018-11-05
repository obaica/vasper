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
from pymatgen.io import vasp as pmg_vasp

### Arg-parser
parser = argparse.ArgumentParser(
    description="This script shows log of vasprun. \
                 If you don't specify file path, \
                 this script reads files in the current directory")

### input files
parser.add_argument('-vf', '--vasprun_file', type=str, default='vasprun.xml',
                    help="input vasprun.xml file")

### output option
parser.add_argument('-pr', '--params', action='store_true',
                    help="show vasp run all parameters, \
                          not just parameters written in INCAR")
parser.add_argument('-kp', '--kpoints', action='store_true',
                    help="show infomations about kpoints")


args = parser.parse_args()

### definitions
def check_file_exist(filepath):
    if not os.path.isfile(filepath):
        ValueError("%s does not exist" % filepath)
    else:
        print("reading : %s" % filepath)


### vasprun.xml
check_file_exist(args.vasprun_file)
vasprun = pmg_vasp.Vasprun(args.vasprun_file)

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
