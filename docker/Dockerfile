FROM swift:bionic

# install lapack
RUN apt update && apt install -y liblapacke-dev

# copy the repository
COPY . $HOME/SymbolLab/

WORKDIR $HOME/SymbolLab
