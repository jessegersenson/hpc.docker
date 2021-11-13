# Cluster stockfish: docker-compose MPI and OpenMP
enables running UCI chess engine stockfish across multiple hosts

## start the cluster
    docker-compose scale mpi_head=1 mpi_node=3

## ssh into the master node
    ssh -i ssh/id_rsa.mpi -p ${hpcdocker_mpi_head_PORT} mpirun@${hpcdocker_mpi_head_IP}

## run stockfish from mpi_head
    mpirun -np 4 /tmp/stockfish bench
