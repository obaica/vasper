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
import numpy as np

### Arg-parser
parser = argparse.ArgumentParser(
    description="This script shows convergence such as relax and energy.")

### input files
parser.add_argument('-vf', '--vasprun_file', type=str, default='vasprun.xml',
                    help="you can specify multple vasprun.xml file")

### output option
parser.add_argument('--E_step', action='store_true',
                    help="make log file")
args = parser.parse_args()

### definitions
def _check_single_vasprun_file(vasprun_files):
    """
    check the number of vasprun files
    """
    if len(vasprun_files) != 1:
        raise ValueError("In this mode, you cannot specify multi vasprun files")

def check_file_exist(filepath):
    if not os.path.isfile(filepath):
        raise ValueError("%s does not exist" % filepath)
    else:
        print("reading : %s" % filepath)

def get_data(vasprun):
    """
    get various data from vasprun.xml

        Parameters
        ----------
        vasprun : pymatgen.io.vasp.Vasprun class object
    """
    summary = {}
    summary['final_energy'] = float(vasprun['output']['final_energy'])
    summary['final_energy_per_atom'] = float(vasprun['output']['final_energy_per_atom'])
    summary['volume'] = vasprun['output']['crystal']['lattice']['volume']
    kpt = vasprun['input']['kpoints']['kpoints'][0]
    summary['total_kpoints'] = kpt[0] * kpt[1] * kpt[2]
    summary['kpoints'] = [kpt[0], kpt[1], kpt[2]]
    summary['nkpoints'] = vasprun['input']['nkpoints']
    summary['encut'] = vasprun['input']['parameters']['ENCUT']
    summary['correlation_function'] = vasprun['run_type']

    ion_steps = []




### vasprun.xml
vasprun_files = args.vasprun_file.split()
vaspruns = []
for vasprun_file in vasprun_files:
    check_file_exist(vasprun_file)
    vasprun = pmg_vasp.Vasprun(vasprun_file)
    vaspruns.append(vasprun)

_check_single_vasprun_file(vasprun_files)
