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
import numpy as np
from pymatgen.io import vasp as pmgvasp
from pymatgen.symmetry.bandstructure import HighSymmKpath

def find_bandpath(structure):
    # First brillouin zone
    ibz = HighSymmKpath(structure)
    print("ibz type     : {0}".format(ibz.name))

    # suggested path
    print("paths in first brillouin zone :")
    for path in ibz.kpath["path"]:
        print(path)

    kpoints = list()
    labels = list()
    for path in ibz.kpath["path"]:
        for i, kpts in enumerate(path):
            kpoints.append(ibz.kpath["kpoints"][kpts])
            labels.append(kpts)
            if i != 0 and i != len(path)-1:
                kpoints.append(ibz.kpath["kpoints"][kpts])
                labels.append(kpts)
    return kpoints, labels

def write_bandkpoints(knum, kpoints, labels):
    # print kpoints file
    pmgvasp.inputs.Kpoints(
            comment = "output from vasper.kpoints.write_bandkpoints",
            num_kpts = knum,
            style = pmgvasp.inputs.Kpoints.supported_modes.Line_mode,
            coord_type = "Reciprocal",
            kpts = kpoints,
            labels = labels,
            ).write_file("KPOINTS")

def write_kpoints(style, kpts, shift=(0.,0.,0.)):
    ### style, kpts => see pymatgen.io.vasp.Kpoints
    ### style => 'Monkhorst' or 'Gamma'
    ### kpts = (6, 6, 6)
    if style == 'Monkhorst':
        pmgvasp.inputs.Kpoints(
                comment = "output from vasper.kpoints.write_kpoints",
                kpts = (kpts,),
                style = pmgvasp.inputs.Kpoints.supported_modes.Monkhorst,
                kpts_shift=shift,
                ).write_file("KPOINTS")
    elif style == 'Gamma':
        pmgvasp.inputs.Kpoints(
                comment = "output from vasper.kpoints.write_kpoints",
                kpts = (kpts,),
                style = pmgvasp.inputs.Kpoints.supported_modes.Gamma,
                kpts_shift=shift,
                ).write_file("KPOINTS")
    else:
        raise ValueError("style : %s is not supported" % style)

def multiply_orig_kpts(kptfile, multiply):
    ### kptfile => KPOINTS file
    ### style => multiply
    kpoints = pmgvasp.inputs.Kpoints.from_file(kptfile)
    # kpoints.kpts = list(map(int, list(np.array(kpoints.kpts) * multiply)))
    # kpoints.kpts = list(map(int, list(np.array(kpoints.kpts) * multiply)))
    new_kpts = np.array(kpoints.kpts) * multiply
    new_kpts = new_kpts.astype(int).tolist()
    kpoints.kpts = new_kpts
    kpoints.write_file("KPOINTS")

if __name__ == "__main__":
    ### Arg-parser
    parser = argparse.ArgumentParser(
        description="This script deals with KPOINTS")

    parser.add_argument('-st', '--style', type=str,
                        help="'band' or 'Monkhorst' or 'Gamma' or 'revise'")
    parser.add_argument('-c', '--posfile', type=str, default='POSCAR',
                        help="POSCAR file for 'band' mode")
    parser.add_argument('-k', '--kptfile', type=str, default='KPOINTS',
                        help="KPOINTS file for 'revise' mode")
    parser.add_argument('--knum', type=int,
                        help="knum for each band path, ex. 100")
    parser.add_argument('--kpts', type=str,
                        help="kpoints for 'Monkhorst' or 'Gamma' mode \
                              ex. '6 6 6'")
    parser.add_argument('--multiply', type=float,
                        help="multiply kpoints for 'revise' mode")
    parser.add_argument('--shift', type=str, default='0 0 0',
                        help="kpoints shift for 'Monkhorst' or 'Gamma' mode \
                              default '0 0 0'")
    args = parser.parse_args()

    ### main
    if args.style == 'revise':
        multiply_orig_kpts(args.kptfile, args.multiply)
    elif args.style == 'band':
        pos = pmgvasp.inputs.Poscar.from_file(args.posfile)
        kp, label = find_bandpath(structure=pos.structure)
        write_bandkpoints(args.knum, kp, label)
    else:
        kpts = tuple(map(int, args.kpts.split()))
        shift = tuple(map(float, args.shift.split()))
        write_kpoints(args.style, kpts, shift)
