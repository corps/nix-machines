FROM nixos/nix:latest

RUN echo 'sandbox = true' >> /etc/nix/nix.conf
RUN echo 'filter-syscalls = false' >> /etc/nix/nix.conf
RUN echo 'max-jobs = 1' >> /etc/nix/nix.conf
RUN echo 'experimental-features = nix-command flakes' >> /etc/nix/nix.conf
RUN echo 'system-features = nixos-test benchmark big-parallel kvm' >> /etc/nix/nix.conf
RUN nix-channel --remove nixpkgs
RUN nix-channel --add https://nixos.org/channels/nixos-23.05 nixpkgs
RUN nix-channel --update
RUN nix-env -i docker
