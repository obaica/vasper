#!/usr/bin/env python
# -*- coding: utf-8 -*-

###############################################################################
# plot vasp results
###############################################################################

### import modules
import os
import argparse
from matplotlib import pyplot as plt
from pymatgen.io import lobster as pmglobster
from pymatgen.io import vasp as pmgvasp
from pymatgen.electronic_structure import plotter as pmgplotter

def print_runmode():
    print("---------------")
    print("argparse inputs")
    print("---------------")
    print("run mode : 'ele_band'                  filenames : 'vasprun.xml'                       keys : None")
    print("run mode : 'ele_dos'                   filenames : 'vasprun.xml'                       keys : None")
    print("run mode : 'ele_element_dos'           filenames : 'vasprun.xml'                       keys : None")
    print("run mode : 'lobster_dos'               filenames : 'vasprun.xml' 'DOSCAR.lobster'      keys : None")
    print("run mode : 'lobster_element_dos'       filenames : 'vasprun.xml' 'DOSCAR.lobster'      keys : None")
    print("run mode : 'lobster_element_spd_dos'   filenames : 'vasprun.xml' 'DOSCAR.lobster'      keys : element")
    print("run mode : 'lobster_spd_dos'           filenames : 'vasprun.xml' 'DOSCAR.lobster'      keys : None")

### Arg-parser
parser = argparse.ArgumentParser(
    description="This script plots various figures")
parser.add_argument('-r', '--runmode', type=str, help=print_runmode())
parser.add_argument('-f', '--filenames', type=str,
                    help="input filenames")
parser.add_argument('-k', '--keys', type=str, default=None,
                    help="additional parse keys")
parser.add_argument('--xlim', type=str, default='None None',
                    help="figure xlimit, don't use colon \
                          ex) '-10 20', 'None 20'")
parser.add_argument('--ylim', type=str, default='None None',
                    help="figure ylimit, don't use colon \
                          ex) '-10 20', 'None 20'")
args = parser.parse_args()

### analysis parser
def reshape_parser(parser, objtype=str):
    """
    from 'None 3.5' to (None, 3.5)
    """
    split = parser.split()
    for i in range(len(split)):
        if split[i] == 'None':
            split[i] = None
        else:
            split[i] = objtype(split[i])
    return tuple(split)

### read data from file
def read_data(runmode, filenames, keys=None):
    """
    read necessary data from file
    """
    if runmode == 'ele_dos':
        vasprun = pmgvasp.outputs.Vasprun(filenames)
        tdos = vasprun.tdos
        return tdos
    elif runmode == 'ele_element_dos':
        vasprun = pmgvasp.outputs.Vasprun(filenames)
        cdos = vasprun.complete_dos
        element_dos = cdos.get_element_dos()
        return element_dos
    elif runmode == 'ele_band':
        vasprun = pmgvasp.outputs.BSVasprun(filenames)
        band = vasprun.get_band_structure(line_mode=True)
        return band
    elif runmode == 'lobster_dos':
        filenames = reshape_parser(filenames)
        doscar = pmglobster.Doscar(vasprun=filenames[0], doscar=filenames[1])
        tdos = doscar.tdos
        return tdos
    elif runmode == 'lobster_element_dos':
        filenames = reshape_parser(filenames)
        doscar = pmglobster.Doscar(vasprun=filenames[0], doscar=filenames[1])
        cdos = doscar.completedos
        element_dos = cdos.get_element_dos()
        return element_dos
    elif runmode == 'lobster_element_spd_dos':
        filenames = reshape_parser(filenames)
        doscar = pmglobster.Doscar(vasprun=filenames[0], doscar=filenames[1])
        cdos = doscar.completedos
        element_dos = cdos.get_element_spd_dos(el=keys)
        return element_dos
    elif runmode == 'lobster_spd_dos':
        filenames = reshape_parser(filenames)
        doscar = pmglobster.Doscar(vasprun=filenames[0], doscar=filenames[1])
        cdos = doscar.completedos
        element_dos = cdos.get_spd_dos()
        return element_dos
    else:
        raise ValueError("runmode : %s is not supported" % runmode)

def make_plot(runmode, data, xlim, ylim):
    """
    plot
    """
    if runmode == 'ele_dos' or runmode == 'lobster_dos':
        plotter = pmgplotter.DosPlotter()
        plotter.add_dos("Total DOS", data)
        plotter.show(xlim=xlim, ylim=ylim)
    elif runmode == 'ele_element_dos' or \
         runmode == 'lobster_element_dos' or \
         runmode == 'lobster_element_spd_dos' or \
         runmode == 'lobster_spd_dos':
        plotter = pmgplotter.DosPlotter()
        plotter.add_dos_dict(data)
        plotter.show(xlim=xlim, ylim=ylim)
    elif runmode == 'ele_band':
        #plotter = pmgplotter.BSPlotter(bandstr)
        plotter = pmgplotter.BSPlotter(data)
        plotter.get_plot(ylim=ylim).show()
    else:
        raise ValueError("runmode : %s is not supported" % args.runmode)

xlim = reshape_parser(args.xlim, objtype=float)
ylim = reshape_parser(args.ylim, objtype=float)
data = read_data(args.runmode, args.filenames, args.keys)
make_plot(args.runmode, data, xlim, ylim)
