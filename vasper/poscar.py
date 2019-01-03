#!/usr/bin/env python
# -*- coding: utf-8 -*-

###############################################################################
# deal with kpoints
###############################################################################

"""
This script is about POSCAR
"""

### import modules
import os
import argparse
import numpy as np
from crystal import crystal, file_io

if __name__ == "__main__":
    ### Arg-parser
    parser = argparse.ArgumentParser(
        description="This script deals with KPOINTS")
    parser.add_argument('-b', '--bravais', action='store_true',
                        help="get bravais lattice")
    parser.add_argument('-c', '--posfile', type=str, default='POSCAR',
                        help="POSCAR file for 'band' mode")
    parser.add_argument('-d', '--distance', action='store_true',
                        help="distances between two atoms")
    args = parser.parse_args()

    ### main
    poscar = file_io.Poscar(args.posfile)
    structure = crystal.Structure(poscar.get_structure())

    if args.bravais:
        spganalyzer = structure.get_spacegroupanalyzer()
        print(spganalyzer.get_lattice_type())

    if args.distance:
        distances = structure.get_neighbor_distances()
        print(' '.join(list(map(str, distances))))
