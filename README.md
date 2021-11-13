# Cluster stockfish: docker-compose MPI and OpenMP
this documentation is incomplete.

start the cluster
```docker-compose scale mpi_head=1 mpi_node=3```

ssh into the master node (find IP and PORT via: docker ps -a | grep hpcdocker_mpi_head)
```
ssh -i ssh/id_rsa.mpi -p ${hpcdocker_mpi_head_PORT} mpirun@${hpcdocker_mpi_head_IP}
```

run stockfish from mpi_head
```mpirun -np 4 /tmp/stockfish bench```
