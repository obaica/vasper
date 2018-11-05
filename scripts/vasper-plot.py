#!/usr/bin/env python
# -*- coding: utf-8 -*-

###############################################################################
# plot vasp results
###############################################################################

### import modules
import argparse
from matplotlib import pyplot as plt
from pymatgen.io.vasp import Vasprun
from pymatgen.electronic_structure import DosPlotter

### Arg-parser
parser = argparse.ArgumentParser(
    description="")
parser.add_argument('--vasprun', type=str,
                    help="input vasprun.xml file")
args = parser.parse_args()

### density of states
def PlotDos(ax, vasprun):

