# skibd
DB Karate Shotokan

Il file DDL genera la struttura e le funzioni
Gli insert avvengono sulla tabelle nello schema Staging, che triggera il meccanismo di update ed insert sulle tabelle in ski

es connessione: ./cloud-sql-proxy.exe --address 127.0.0.1 --port 5432 eng-hangar-343507:europe-west12:pg-mgion 


    1  sudo curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
    2  cd rustapi
    3  git clone https://github.com/MGFornasiero/rustapi.git
    4  cd rustapi/
    5  cargo run
    6  . "$HOME/.cargo/env"


    9  export SKIURI=postgresql://postgres:Gion.1982@10.35.144.3:5432/postgres
   31  export PG_URI=postgresql://postgres:Gion.1982@10.35.144.3:5432/postgres

  166  git config --global user.name "MGFornasiero"
  167  git config --global user.email "mg.fornasiero@gmail.com"
  168  
  259  cargo run
  260  psql -h 10.35.144.3 -p 5432 -d postgres -U postgres
  261  sudo apt update
  262  sudo apt install postgresql-client
  263  psql -h 10.35.144.3 -p 5432 -d postgres -U postgres
  264  cd..
  310  cd skiiapi/
  311  cd app/
  312  fastapi dev main.py
  313  pip install "fastapi[standard]"
  314  fastapi dev main.py
  315  pip install psycopg2
  316  sqlalchemy
  317  pip install sqlalchemy
  318  sudo apt-get install libpq-dev python-dev
  319  pip install psycopg2
  320  fastapi dev main.py
  321  fastapi dev main.py
  322  cd skiiapi/
  323  git pull
  324  git status
  325  docker build -t skiiapi
  326  docker build -t skiiapi .
  327  docker tag skiiapi:latest europe-west12-docker.pkg.dev/eng-hangar-343507/cloud-run-source-deploy/skiiapi:latest
  328  docker push europe-west12-docker.pkg.dev/eng-hangar-343507/cloud-run-source-deploy/skiiapi:latest
  329  cd app/
  330  export SKIURI=postgresql://postgres:Gion.1982@10.35.144.19:5432/postgres
  331  fastapi dev main.py
  332  cd skiiapi/
  333  git pull
  334  git stash
  335  git pull
  336  export SKIURI=postgresql://postgres:Gion.1982@10.35.144.19:5432/postgres
  337  cd app/
  338  fastapi dev main.py
  339  cd ..
  340  docker build -t skiiapi .
  341  docker tag skiiapi:latest europe-west12-docker.pkg.dev/eng-hangar-343507/cloud-run-source-deploy/skiiapi:latest
  342  docker push europe-west12-docker.pkg.dev/eng-hangar-343507/cloud-run-source-deploy/skiiapi:latest
  343  cd app/
  344  fastapi dev main.py
  345  cd skiiapi/
  346  export SKIURI=postgresql://postgres:Gion.1982@10.35.144.19:5432/postgres
  347  git pull
  348  cd app/
  349  fastapi dev main.py
  350  fastapi dev main.py
  351  cd ..
  352  git push
  353  git push
  354  dit add app/main.py 
  355  git commit -m "aggiornamento"
  356  git push
  357  git status
  358  git add app/main.py 
  359  git commit -m "aggiornamento"
  360  git push
  361  cd skiiapi/
  362  git pull
  363  git pull
  364  cd app
  365  export SKIURI=postgresql://postgres:Gion.1982@10.35.144.19:5432/postgres
  366  fastapi dev main.py
  367  git pull
  368  fastapi dev main.py
  369  export SKIURI=postgresql://postgres:Gion.1982@10.35.144.3:5432/postgres
  370  cd skiiapi/app/
  371  fastapi dev main.py