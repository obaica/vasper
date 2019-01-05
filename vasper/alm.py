#!/usr/bin/env python
# -*- coding: utf-8 -*-

###############################################################################
# use alm
###############################################################################

### import modules
import sys
import numpy as np
import argparse

### Arg-parser
parser = argparse.ArgumentParser(
    description="")
parser.add_argument('-d', '--make_disp', action='store_true',
                    help='~~~evoke displacement mode~~~')
# parser.add_argument('--phonopy_path', type=str, default=None,
#                     help='path to phonopy package for alm')
parser.add_argument('--dim', type=str, default=None,
                    help="dimension ex) '2 2 2'")
parser.add_argument('--temperature', type=float, default=300.0,
                    help='Temperature to output data at')
parser.add_argument('--num', type=int, default=100,
                    help='sampling number')
parser.add_argument('--seed', type=int, default=123456,
                    help='seed')

parser.add_argument('-f', '--make_force', action='store_true',
                    help='~~~evoke FORCE_SETS mode~~~')
parser.add_argument('--vaspruns', type=str,
                    help='vasprun files \
                          ex) --vasprun=`echo disp-{001..002}/vasprun.xml`')
args = parser.parse_args()

### import phonopy
if args.make_disp:
    # sys.path.append(args.phonopy_path)
    import phonopy
    from phonopy.phonon.random_displacements import RandomDisplacements
    from phonopy.interface.vasp import write_vasp

    num = args.num
    T = args.temperature
    seed = args.seed
    # number of supercells generated
    # Temperature [K]
    # Random seed
    dim = list(map(int, args.dim.split()))
    phonon = phonopy.load(dim,
    born_filename="BORN",
    unitcell_filename="POSCAR-unitcell",
    use_alm=True)
    lat = phonon.supercell.get_cell()
    phonon.set_random_displacements(T, number_of_snapshots=num, seed=seed)
    u = phonon.get_random_displacements()

    ### by mizo start
    import os
    exist_disp_num = len([ i for i in os.listdir(os.getcwd()) if 'disp-' in i ])
    print("from disp-0001 to disp-%04d are already exist" % exist_disp_num)
    disp_start = "{0:04d}".format(exist_disp_num+1)
    disp_stop = "{0:04d}".format(exist_disp_num+args.num)
    print("making displacement from disp-{0} to disp-{1}".format(disp_start, disp_stop))
    ### by mizo end


    for i, u_red in enumerate(np.dot(u, np.linalg.inv(lat))):
        cell = phonon.supercell.copy()
        pos = cell.get_scaled_positions()
        pos += u_red
        cell.set_scaled_positions(pos)
        # write_vasp("POSCAR-rd.%04d" % (i + 1), cell)

        ### by mizo start
        write_vasp("POSCAR-rd.%04d" % (exist_disp_num + i + 1), cell)
        ### by mizo end

if args.make_force:
    import io
    from phonopy.interface.vasp import VasprunxmlExpat
    forces = []
    points = []
    lattice = None

    vasprun_files = args.vaspruns.split()
    for filename in vasprun_files:
        with io.open(filename, "rb") as fp:
            vasprun = VasprunxmlExpat(fp)
            vasprun.parse()
            if lattice is None:
                lattice = vasprun.lattice[0]
            forces += [f for f in vasprun.forces]
            points += [p for p in vasprun.points]

    forces_minus_f0 = np.array([f - forces[0] for f in forces[1:]])
    diff = [p - points[0] for p in points[1:]]
    diff -= np.rint(diff)
    displacements = np.dot(diff, lattice)

    with open("FORCE_SETS", 'w') as w:
        for d_set, f_set in zip(displacements, forces_minus_f0):
            for d_vec, f_vec in zip(d_set, f_set):
                w.write(("%15.8f" * 6 + "\n") % (tuple(d_vec) + tuple(f_vec)))
