#!/usr/bin/env python
# -*- coding: utf-8 -*-

###############################################################################
# plot vasp results
###############################################################################

### import modules
import os
import argparse
from matplotlib import pyplot as plt
from pymatgen.io import vasp as pmg_vasp
from pymatgen.electronic_structure import plotter as pmgplotter

### Arg-parser
parser = argparse.ArgumentParser(
    description="This script plots various figures")
parser.add_argument('-vf', '--vasprun_file', type=str, default='vasprun.xml',
                    help="input vasprun.xml file")
parser.add_argument('-r', '--runmode', type=str,
                    help="choose : 'dos' or 'pdos'")
parser.add_argument('--xlim', type=str, default='None None',
                    help="figure xlimit, don't use colon \
                          ex) '-10 20', 'None 20'")
parser.add_argument('--ylim', type=str, default='None None',
                    help="figure ylimit, don't use colon \
                          ex) '-10 20', 'None 20'")
args = parser.parse_args()

### file check
def check_file_exist(filepath):
    if not os.path.isfile(filepath):
        ValueError("%s does not exist" % filepath)
    else:
        print("reading : %s" % filepath)

### analysis parser
def shape_parser(parser):
    """
    from 'None 3.5' to (None, 3.5)
    retrun list object
    """
    split = parser.split()
    for i in range(len(split)):
        if split[i] == 'None':
            split[i] = None
        else:
            split[i] = float(split[i])
    return tuple(split)

### density of states
def PlotDos(tdos, xlim, ylim):
    plotter = pmgplotter.DosPlotter()
    plotter.add_dos("Total DOS", tdos)
    plotter.show(xlim=xlim, ylim=ylim)

def PlotPdos(element_dos, xlim, ylim):
    plotter = pmgplotter.DosPlotter()
    plotter.add_dos_dict(element_dos)
    plotter.show(xlim=xlim, ylim=ylim)



check_file_exist(args.vasprun_file)
vasprun = pmg_vasp.Vasprun(args.vasprun_file)

xlim = shape_parser(args.xlim)
ylim = shape_parser(args.ylim)

if args.runmode == 'dos':
    tdos = vasprun.tdos
    PlotDos(tdos, xlim, ylim)

if args.runmode == 'pdos':
    cdos = vasprun.complete_dos
    element_dos = cdos.get_element_dos()
    PlotPdos(element_dos, xlim, ylim)
