# .bashrc


function compileFMS {
        folder=$(pwd)
        cd ~/MOM6-examples
        (cd build/intel/shared/repro/; rm -f path_names; \
        ../../../../src/mkmf/bin/list_paths -l ../../../../src/FMS; \
        ../../../../src/mkmf/bin/mkmf -t ../../../../src/mkmf/templates/perlmutter.mk -p libfms.a -c "-Duse_libMPI -Duse_netCDF" path_names)
        (cd build/intel/shared/repro/; source ../../env; time make NETCDF=3 REPRO=1 libfms.a)
        cd $folder
}

function makeMOM {
        folder=$(pwd)
        cd ~/MOM6-examples
        (cd build/intel/ocean_only/repro/; rm -f path_names; \
../../../../src/mkmf/bin/list_paths -l ./ ../../../../src/MOM6/{config_src/infra/FMS1,config_src/memory/dynamic_symmetric,config_src/drivers/solo_driver,config_src/external,src/{,/*}}/ ; \
../../../../src/mkmf/bin/mkmf -t ../../../../src/mkmf/templates/perlmutter.mk -o '-I../../shared/repro' -p MOM6 -l '-L../../shared/repro -lfms' path_names)
        (cd build/intel/ocean_only/repro/; source ../../env; time make NETCDF=3 REPRO=1 MOM6)
        cd $folder
}
