#!/usr/bin/env python
# -*- coding: utf-8 -*-

###############################################################################
# deal with kpoints
###############################################################################

"""
This script is about KPOINTS
"""

### import modules
import os
from pprint import pprint
import argparse
from pymatgen.io import vasp as pmg_vasp

### Arg-parser
parser = argparse.ArgumentParser(
    description="This script shows log of vasprun. \
                 If you don't specify file path, \
                 this script reads files in the current directory")

### input files
parser.add_argument('-c', '--posfile', type=str, default='POSCAR',
                    help="input POSCAR file")

### output option
parser.add_argument('-wk', '--write_kpoints', action='store_true',
                    help="write out KPOINTS file")

args = parser.parse_args()

### definitions
def check_file_exist(filepath, reverse=False):
    if not reverse:
        if not os.path.isfile(filepath):
            raise ValueError("%s does not exist" % filepath)
        else:
            print("reading : %s" % filepath)
    if reverse:
        if os.path.isfile(filepath):
            raise ValueError("%s does exist" % filepath)

def write_kpoints(structure):
    # First brillouin zone
    from pymatgen.symmetry.bandstructure import HighSymmKpath
    ibz = HighSymmKpath(structure)
    print("ibz type     : {0}".format(ibz.name))

    # suggested path
    print("paths in first brillouin zone :")
    for path in ibz.kpath["path"]:
        print(path)

    kpoints = list()
    labels = list()
    for path in ibz.kpath["path"]:
        for kpts in path:
            kpoints.append(ibz.kpath["kpoints"][kpts])
            labels.append(kpts)
    # print kpoints file
    pmg_vasp.inputs.Kpoints(
            comment = "band diagram for monoclinic cell, unique axes a",
            num_kpts = 100,
            style = pmg_vasp.inputs.Kpoints.supported_modes.Line_mode,
            coord_type = "Reciprocal",
            kpts = kpoints,
            labels = labels,
            ).write_file("KPOINTS")


### make structure from POSCAR
check_file_exist(args.posfile)
pos = pmg_vasp.inputs.Poscar.from_file(args.posfile)

if args.write_kpoints:
    check_file_exist('KPOINTS', reverse=True)
    write_kpoints(structure=pos.structure)
