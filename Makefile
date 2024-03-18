#Create SafeSquid DEB file
####User Defined Variables####
_USER_=ssquid
_GROUP_=root
APPLICATION=safesquid
TMP_DIR=_mkappliance
BIN=safesquid/opt/safesquid/bin/safesquid
DEPEN_FILE=${TMP_DIR}/installation/dependencies.lst
SS_LATEST="https://downloads.safesquid.com/appliance/binary/safesquid_latest.tar.gz"
VERSION=$$(ls -lrt ${BIN} | awk '{print $$11}' | awk -F "-" '{print $$2}')
SECTION=$$(ls -lrt ${BIN} | awk '{print $$11}' | awk -F "-" '{print $$4}')
DEBIAN=${APPLICATION}/DEBIAN
DEPENDENCIES=$$( sed -n "H;1h;\$${g;s/\n/, /g;p}" ${DEPEN_FILE})
CONTROL_FILE=${TMP_DIR}/tmp/control_file
CONTROL=${DEBIAN}/control
OWNER=${_USER_}:${_GROUP_}
TAR_FILE=${APPLICATION}*.tar.gz
####User Defined Variables####

#Default target to execute.
DEFAULT_GOAL: ${APPLICATION}.deb

# make install -- to install.
install:
	@echo "install: ./${APPLICATION}.deb"
	@apt install ./${APPLICATION}.deb -y 

# make -- to create DEB.
${APPLICATION}.deb: ${DEBIAN}
	@echo "deb: creating ${APPLICATION}.deb"
	@dpkg-deb --build ${APPLICATION}/
	@echo "deb: copy $@ -> ${APPLICATION}_${VERSION}.deb"
	@cp $@ ${APPLICATION}_${VERSION}.deb

#Populate DEBIAN directory.
${DEBIAN}: control
	@rsync -avz postinst ${DEBIAN}/
	@rsync -avz preinst ${DEBIAN}/
	@chmod 755 ${DEBIAN}/preinst
	@chmod 755 ${DEBIAN}/postinst

#Create control file.
control: ${APPLICATION}
	@echo Source: safesquid_latest.tar.gz > ${CONTROL_FILE}
	@echo Section: net >> ${CONTROL_FILE}
	@echo Priority: optional >> ${CONTROL_FILE}
	@echo Maintainer: SafeSquid Labs  \<support@safesquid.net\> >> ${CONTROL_FILE}
	@echo Depends: dependencies >> ${CONTROL_FILE}
	@echo Version: ${APPLICATION}_version >> ${CONTROL_FILE}
	@echo Release: '${APPLICATION}_release' >> ${CONTROL_FILE}
	@echo Homepage: https://safesquid.com >> ${CONTROL_FILE}
	@echo Package: ${APPLICATION} >> ${CONTROL_FILE}
	@echo Architecture: amd64 >> ${CONTROL_FILE}
	@echo Description: World\'s Most Advanced Web Proxy Solution >> ${CONTROL_FILE}
	@sed -r 's/'"${APPLICATION}"'_version/'"${VERSION}"'/' ${CONTROL_FILE} > ${CONTROL}
	@sed -i 's/${APPLICATION}_release/'"${SECTION}"'/' ${CONTROL}
	@sed -i 's/dependencies/'"${DEPENDENCIES}"'/' ${CONTROL}

#Create directory structure 
#Check for user ssquid and update directory ownership.
${APPLICATION}: sanity_check
	@if [ ! -d $@ ]; then mkdir $@; fi
	@if [ ! -d  ${DEBIAN} ]; then mkdir ${DEBIAN}; fi
	@rsync -avz ${TMP_DIR}/etc $@
	@rm $@/etc/sysctl.conf
	@rsync -avz ${TMP_DIR}/opt $@
	@rsync -avz ${TMP_DIR}/tmp $@
	@rsync -avz ${TMP_DIR}/usr $@
	@rsync -avz ${TMP_DIR}/var $@
	@if [ ! $$(cat /etc/shadow | grep ${_USER_}) ]; then useradd ${_USER_}; fi
	@chown -Rv --changes ${OWNER} $@

#Check for existing APPLICATION directory.
#Check if preinst and postinst file exists
sanity_check: ${TMP_DIR}
	@if [ ! -e preinst ]; then echo "preinst: file not found"; false;  fi
	@if [ ! -e postinst ]; then echo "postinst: file not found"; false; fi  

#Check for TMP directory
${TMP_DIR}: ${TAR_FILE}
	@tar -xzvf ${TAR_FILE}

#If TMP directory is not present download source file	
${TAR_FILE}: 
	@wget ${SS_LATEST}

# make clean -- for fresh start. 	
clean:
	@rm -rf ${TMP_DIR}
	@rm -rf ${APPLICATION}
	@rm -rf ${TAR_FILE}
	@rm ${APPLICATION}*.deb