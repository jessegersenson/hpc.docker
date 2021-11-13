FROM debian:latest
RUN apt-get update && \
 	apt-get install -y git mpich make gcc curl g++
  
ENV USER mpirun 
ENV DEBIAN_FRONTEND=noninteractive 
ENV HOME=/home/${USER}
ENV NOTVISIBLE "in users profile"

RUN apt-get update -y && \
    apt-get install -y --no-install-recommends sudo apt-utils && \
    apt-get install -y --no-install-recommends openssh-server \
        gfortran libopenmpi-dev openmpi-bin openmpi-common openmpi-doc binutils 
#    apt-get clean && apt-get purge && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN mkdir /var/run/sshd && \
    echo 'root:${USER}' | chpasswd && \
    sed -i 's/PermitRootLogin without-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd && \
    echo "export VISIBLE=now" >> /etc/profile && \
    adduser --disabled-password --gecos "" mpirun && \
    echo "${USER} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
# SSH login fix. Otherwise user is kicked off after login


# ------------------------------------------------------------
# Set-Up SSH
# ------------------------------------------------------------

ENV SSHDIR ${HOME}/.ssh/
RUN mkdir -p ${SSHDIR}

ADD ssh/config ${SSHDIR}/config
ADD ssh/id_rsa.mpi ${SSHDIR}/id_rsa
ADD ssh/id_rsa.mpi.pub ${SSHDIR}/id_rsa.pub
ADD ssh/id_rsa.mpi.pub ${SSHDIR}/authorized_keys

RUN chmod -R 600 ${SSHDIR}* && \
    chown -R ${USER}:${USER} ${SSHDIR}

# ------------------------------------------------------------
# Configure OpenMPI
# ------------------------------------------------------------

USER root

RUN rm -fr ${HOME}/.openmpi && mkdir -p ${HOME}/.openmpi
ADD default-mca-params.conf ${HOME}/.openmpi/mca-params.conf
RUN chown -R ${USER}:${USER} ${HOME}/.openmpi

# ------------------------------------------------------------
# FINALS
# ------------------------------------------------------------

ENV TRIGGER 1

EXPOSE 22

#### compile stockfish ####
RUN	git clone https://github.com/official-stockfish/Stockfish.git && \
	cd Stockfish/src/ && \
	git checkout cluster && \
	make -j10 ARCH=x86-64-avx2 clean profile-build COMPILER=mpicxx mpi=yes && \
	mkdir /app && \
	cp stockfish /app/stockfish-cluster
#COPY --from=stockfish /app/stockfish-cluster /tmp/stockfish-cluster
 
CMD ["/usr/sbin/sshd", "-D"]
