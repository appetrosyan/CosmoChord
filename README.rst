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

.. code:: bash
   
   git clone --recursive https://github.com/williamjameshandley/CosmoChord
   cd CosmoChord
   make
   export OMP_NUM_THREADS=1
   ./cosmomc test.ini

To run, you should add ``action=5``  to your ini file, and include
``batch3/polychord.ini``. Consider modifying ``test.ini``

If you wish to use Planck data, you should follow the `CosmoMC planck instructions <https://cosmologist.info/cosmomc/readme_planck.html>`__, and then run ``make clean; make`` after ``source bin/clik_profile.sh`` 

Changes from CosmoMC
====================
You can see the key changes by running:

.. code:: bash

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
As this is a fork of CosmoMC, the process of installing the Planck likelihoods is identical: 
- install prerequisites of Planck Code: 

.. code:: bash

   pip install cython astropy 

- install ``cfitsio`` and ``astropy``. Most Linux distributions will have ``cfitsio`` in the official repositories.
   
- Obtain the likelihood code and the baseline data from the `Planck Legacy archive <http://pla.esac.esa.int/pla/#home>`__:

.. code:: bash

    curl "http://pla.esac.esa.int/pla-sl/data-action?COSMOLOGY.COSMOLOGY_OID=151912" --output "COM_Likelihood_CODE-v3.0_R3.01.tar.gz"
    curl "http://pla.esac.esa.int/pla-sl/data-action?COSMOLOGY.COSMOLOGY_OID=151902" --output "COM_Likelihood_Data-baseline_R3.00.tar.gz"
    

- Alternatively, manually download ``COM_Likelihood_Code-*.tar.gz`` and ``COM-Likelihood_Data-*.tar.gz``.
- Unpack the code

.. code:: bash

   tar xvfz COM_likelihood_Code*.tar.gz 
   cd plc-3.0/plc-3.01/ 
   
- install planck likelihood code with:

.. code:: bash

   ./waf configure --install_all_deps install
   
note that if this fails, the ``waf`` script will attempt to pull the dependencies from obsolete hardcoded locations. 
If this is the case, interrupt (``Ctrl+c``) and install the dependencies manually. See your linux distribution's package catalogue to find the required libraries. 
   
- Set-up the environment variables. An example profile for ``bash`` is given in ``bin/clik_profile.sh``. To avoid frustration, you may wish to source the profile at login, e.g. by adding ``source $(pwd)/bin/clik_profile.sh`` to your ``.bashrc``. 

- untar the baseline data

.. code:: bash

   tar xvfz COM_Likelihood_Data-*.tar.gz

- symlink into  baseline data into ``CosmoChord/data``. 

.. code:: bash

   ln -s baseline/plc3-0 CosmoChord/data/clik_14.0
   
- (re)-build CosmoChord

.. code:: bash

   make rebuild
