FROM debian:latest as stockfish
RUN apt-get update && \
	apt-get install -y git mpich make gcc curl g++ && \
	git clone https://github.com/official-stockfish/Stockfish.git && \
	cd Stockfish/src/ && \
	git checkout cluster && \
	make -j10 ARCH=x86-64-avx2 clean build COMPILER=mpicxx mpi=yes && \
	mkdir /app && \
	cp stockfish /app/stockfish-cluster
   
FROM ubuntu:20.04
COPY --from=stockfish /app/stockfish-cluster /tmp/stockfish-cluster
ENV USER mpirun \
    DEBIAN_FRONTEND=noninteractive \
    HOME=/home/${USER} \
    NOTVISIBLE "in users profile"

RUN apt-get update -y && \
	apt-get install -y git curl make gcc g++ && \
    apt-get install -y --no-install-recommends sudo apt-utils && \
    apt-get install -y --no-install-recommends openssh-server \
        gcc gfortran libopenmpi-dev openmpi-bin openmpi-common openmpi-doc binutils 
#    apt-get clean && apt-get purge && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN mkdir /var/run/sshd && \
    echo 'root:${USER}' | chpasswd && \
    sed -i 's/PermitRootLogin without-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd && \
    echo "export VISIBLE=now" >> /etc/profile && \
    adduser --disabled-password --gecos "" ${USER} && \
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
CMD ["/usr/sbin/sshd", "-D"]
