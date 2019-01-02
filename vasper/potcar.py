#!/usr/bin/env python
# -*- coding: utf-8 -*-

###############################################################################
# deal with potcar
###############################################################################

"""
This script is about POTCAR
"""

### import modules
import os
from pprint import pprint
import argparse
import numpy as np
from pymatgen.io import vasp as pmgvasp

class Potcar():
    """
    deals with POTCAR file

        Attributes
        ----------
        Attribute1 : int
            description
        Attribute2 : int, default var
            description

        Methods
        -------

        Notes
        -----
    """
    def __init__(self, potfile):
        """
        init

            Parameters
            ----------
            potfile : str
                POTCAR file path
        """
        self.pot = pmgvasp.Potcar.from_file(potfile)

    def nbands_for_lobster(self, posfile):
        """
        return nbands num necessary for calculation pCOHP

            Parameters
            ----------
            posfile : str
                POSCAR file path

            Returns
            -------
            nbands : int
                nbands num necessary for calculation pCOHP
        """
        def _get_wave_num(orbital):
            if orbital == 's':
                num = 1
            elif orbital == 'p':
                num = 3
            elif orbital == 'd':
                num = 5
            elif orbital == 'f':
                num = 7
            else:
                print("orbital : %s" % orbital)
                raise ValueError("could not specify orbital")
            return num

        def _considering_wavefunction_num(single_pot):
            wave_num = 0
            for electron in single_pot.electron_configuration:
                wave_num += _get_wave_num(electron[1])
            return wave_num

        poscar = pmgvasp.inputs.Poscar.from_file(posfile)
        nbands = 0
        for i in range(len(self.pot)):
            single_pot = self.pot[i]
            wave_per_atom = _considering_wavefunction_num(single_pot)
            nbands += wave_per_atom * poscar.natoms[i]
        return nbands

    def considering_orbitals(self):
        all_orbitals = {}
        for single_pot in self.pot:
            element = single_pot.element
            ele_config = single_pot.electron_configuration
            orbitals =  [ str(orb[0])+orb[1] for orb in ele_config ]
            electrons =  [ str(orb[2]) for orb in ele_config ]
            all_orbitals[element] = {'orbitals' : orbitals,
                                     'electrons' : electrons}
        return all_orbitals

if __name__ == "__main__":
    ### Arg-parser
    parser = argparse.ArgumentParser(
        description="This script deals with POTCAR")

    parser.add_argument('-o', '--orbital', action='store_true',
                        help="orbital information")
    parser.add_argument('-l', '--log', action='store_true',
                        help="various information")
    parser.add_argument('-n', '--nbands', action='store_true',
                        help="NBANDS necessary for pCOHP")
    parser.add_argument('-p', '--potfile', type=str,
                        help="POTCAR file")
    parser.add_argument('-c', '--posfile', type=str, default=None,
                        help="POSCAR file")
    args = parser.parse_args()

    ### main
    potcar = Potcar(args.potfile)
    orbs = potcar.considering_orbitals()
    if args.orbital:
        for ele in orbs.keys():
            print('basisfunctions'+' '+ele+' '+' '.join(orbs[ele]['orbitals']))

    if args.log:
        print("Orbital infomation")
        for ele in orbs.keys():
            print(ele)
            print("orbital : %s" % ' '.join(orbs[ele]['orbitals']))
            print("electron : %s" % ' '.join(map(str, orbs[ele]['electrons'])))
        print("")

        if args.posfile is not None:
            print("The number of NBANDS necessary for pCOHP")
            print(str(potcar.nbands_for_lobster(args.posfile)))

    if args.nbands:
        print(str(potcar.nbands_for_lobster(args.posfile)))
