FROM swift:bionic

# install miniconda
RUN apt update && apt install -y liblapacke-dev

# copy the wrapper
COPY . $HOME/SymbolLab/

WORKDIR $HOME/SymbolLab