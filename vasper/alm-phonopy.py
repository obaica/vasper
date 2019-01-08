#!/usr/bin/env python
# -*- coding: utf-8 -*-

###############################################################################
# use alm
###############################################################################

### import modules
import sys
# from alm import ALM
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
parser.add_argument('--fs', type=str, default=None,
                    help="FORCE_SETS file path")
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
                          ex) --vasprun="`echo disp-{001..002}/vasprun.xml`" \
                          ex) --vasprun="`echo disp-*/vasprun.xml`"')

parser.add_argument('-bd', '--band_difference', action='store_true',
                    help='~~~evoke band difference mode~~~')
parser.add_argument('--mesh1', type=str,
                    help='mesh.hdf5 filename')
parser.add_argument('--mesh2', type=str,
                    help='mesh.hdf5 filename')
args = parser.parse_args()

### import phonopy
if args.make_disp:
    # sys.path.append(args.phonopy_path)
    import phonopy
    from phonopy.phonon.random_displacements import RandomDisplacements
    from phonopy.interface.vasp import write_vasp

    if args.fs is None:
        raise ValueError("You have to specify FORCE_SETS file")
    else:
        print("FORCE_SETS path : %s" % args.fs)

    num = args.num
    T = args.temperature
    seed = args.seed
    # number of supercells generated
    # Temperature [K]
    # Random seed
    dim = list(map(int, args.dim.split()))
    print(args.fs)
    phonon = phonopy.load(supercell_matrix=dim,
                          born_filename="BORN",
                          unitcell_filename="POSCAR-unitcell",
                          force_sets_filename=args.fs,
                          use_alm=True)
    lat = phonon.supercell.get_cell()
    phonon.set_random_displacements(T, number_of_snapshots=num, seed=seed)
    u = phonon.get_random_displacements()

    ### by mizo start
    import os
    exist_disp_num = len([ i for i in os.listdir(os.getcwd()) if 'disp-' in i ])
    if exist_disp_num != 0:
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
    displacements = np.dot(diff, lattice)

    with open("FORCE_SETS", 'w') as w:
        for d_set, f_set in zip(displacements, forces_minus_f0):
            for d_vec, f_vec in zip(d_set, f_set):
                w.write(("%15.8f" * 6 + "\n") % (tuple(d_vec) + tuple(f_vec)))

if args.band_difference:
    import h5py
    def get_band_data(filename):
        h5file = h5py.File(filename, "r")
        freq = np.array(h5file['frequency'])
        qpoint = np.array(h5file['qpoint'])
        weight = np.array(h5file['weight'])
        weight = weight.reshape(weight.shape[0], 1)
        h5file.close()
        return freq, qpoint, weight
    freq_1, qpoint_1, weight_1 = get_band_data(args.mesh1)
    freq_2, qpoint_2, weight_2 = get_band_data(args.mesh2)
    # check
    if not np.allclose(np.round(qpoint_1, 4), np.round(qpoint_2, 4)):
        raise ValueError("qpoints are different between two files")
    else:
        print("check : the qpoints of the two files are the same")
    diff = np.dot(np.abs(freq_1.T-freq_2.T), weight_1).sum() / \
            (weight_1.sum() * freq_1.shape[1])
    print("average frequency difference per one mode (THz) : %s" % str(diff))
