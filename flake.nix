{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
    relic.url = "github:abueide/relic/flake";
    bls-signatures.url = "github:abueide/bls-signatures/flake";
  };

  outputs = { self, nixpkgs, flake-utils, relic, bls-signatures }:
  flake-utils.lib.eachDefaultSystem (system:
     let pkgs = nixpkgs.legacyPackages.${system};
         chia-relic = relic.defaultPackage.${system};
         bls = bls-signatures.defaultPackage.${system};
         deps = with pkgs; [ cmake gmp gmp.dev libsodium chia-relic bls-signatures ];
         platform_deps = if(pkgs.lib.strings.hasSuffix "linux" system) then [ pkgs.numactl ] else [];
     in rec {
     devShells.default = pkgs.mkShell {
         packages = deps;
     };
     defaultPackage = with pkgs; stdenv.mkDerivation {
         pname = "bladebit";
         version = "develop";

         src = self;

         nativeBuildInputs = [ cmake gmp gmp.dev libsodium chia-relic bls ] ++ platform_deps;

         buildPhase = ''
             cmake . -DBUILD_BLADEBIT_TESTS=false
             cmake --build . --target bladebit --config Release
         '';

         installPhase = ''
             runHook preInstall
             install -D -m 755 bladebit $out/bin/bladebit
             runHook postInstall
         '';

         enableParallelBuilding = true;
         cmakeFlags = [
            "-DBUILD_BLADEBIT_TESTS=false"
            "-DBUILD_LOCAL=true"
         ];
  };
}
);
}