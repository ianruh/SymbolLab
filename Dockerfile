FROM swift:bionic

# install lapack
RUN apt update && apt install -y liblapacke-dev

# install python3 and some dependencies
RUN apt install -y python3 python3-pip
RUN pip3 install numpy matplotlib

# copy the repository
COPY . $HOME/SymbolLab/

WORKDIR $HOME/SymbolLab
