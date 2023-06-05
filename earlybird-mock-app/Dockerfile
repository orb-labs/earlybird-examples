FROM ghcr.io/foundry-rs/foundry:latest

COPY . /earlybird_evm_mock_app

WORKDIR /earlybird_evm_mock_app

# RUN forge build

# RUN forge test

COPY $PWD/entrypoint.sh /usr/local/bin

ENTRYPOINT ["/bin/sh", "/usr/local/bin/entrypoint.sh"]