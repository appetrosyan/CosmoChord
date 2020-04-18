===================
CosmoChord
===================
:CosmoChord:  PolyChord + CosmoMC for cosmological parameter estimation and evidence calculation
:Author: Will Handley
:ForkedFrom: https://github.com/cmbant/CosmoMC
:Homepage: http://polychord.co.uk

.. image:: https://travis-ci.org/williamjameshandley/CosmoChord.svg?branch=master
    :target: https://travis-ci.org/williamjameshandley/CosmoChord
.. image:: https://zenodo.org/badge/158467573.svg
   :target: https://zenodo.org/badge/latestdoi/158467573


Description and installation
=============================

CosmoChord is a fork of `CosmoMC <https://github.com/cmbant/CosmoMC>`__, which
adds nested sampling provided by PolyChord.

Installation procedure:

.. bash::
   
   git clone --recursive https://github.com/williamjameshandley/CosmoChord
   cd CosmoChord
   make
   export OMP_NUM_THREADS=1
   ./cosmomc test.ini

To run, you should add ``action=5``  to your ini file, and include
``batch3/polychord.ini``. Consider modifying ``test.ini``

If you wish to use Planck data, you should follow the `CosmoMC planck instructions <https://cosmologist.info/cosmomc/readme_planck.html>`__, and then run ``make clean; make`` after ``source bin/clik_profile.sh`` 



Changes
=======
You can see the key changes by running:

.. bash::
   git remote add upstream https://github.com/cmbant/CosmoMC
   git fetch upstream
   git diff --stat upstream/master
   git diff  upstream/master source 


The changes to CosmoMC are minor:

- Nested sampling heavily samples the tails of the posterior. This means that
  there need to be more corrections for these regions that are typically
  unexplored by the default metropolis hastings tool. This is now implemented
  by separate CAMB git submodule
- You should **not** use openmp parallelisation, as this in inefficient when
  using PolyChord. Instead, you should use pure MPI parallelisation, and you
  may use as many cores as you have live points.
  
Planck Likelihoods
==================
As this is a fork of CosmoMC the process of installing the Planck lieklihoods is identical: 
- install prerequisites of Planck Code: 
.. bash::
   pip install cython astropy 
   sudo pacman -S cfitsio
   
- Obtain from the `Planck Legacy archive <https://wiki.cosmos.esa.int/planck-legacy-archive/index.php/Main_Page>` the following the `COM_Likelihood_Code-*.tar.gz` and `COM-Likelihood_Data-*.tar.gz`.
- Untar the code
.. bash::
   tar xvfz COM_likelihood_Code*.tar.gz 
   cd plc-3.0/plc-3.01/ 
   
- install with
.. bash::
   ./waf configure --install_all_deps install
   
- make sure that all packages are pulled in correctly. Any missing packages may not prevent the code from building, but `CosmoChord` may not have all of its dependencies. 
- source the environment variables using a `bash`-compatible shell. e.g. 
.. bash::
   echo echo -e "\nsource $(pwd)/bin/clik_profile.sh" >> ~/.bashrc

- untar the Data
.. bash:: 
   tar xvfz COM_Likelihood_Data-*.tar.gz

- symlink into `CosmoChord/data`. 
.. bash::
   ln -s baseline/plc3-0 CosmoChord/data/clik_14.0
   
- (re)-build CosmoChord
.. bash::
   make rebuild
