# install Rust programming language
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
# source the cargo environment
export PATH="$HOME/.cargo/bin:$PATH" # add cargo to PATH
cargo install cargo-binutils cargo-make just cross flamegraph cargo-audit cargo-machete

# install dependencies for building Windows binaries on a Fedora system
sudo dnf install mingw64-gcc mingw32-gcc
