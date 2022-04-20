{ compiler ? "ghc884" }:

let
  sources = import ./nix/sources.nix {};
  pkgs = import sources.nixpkgs {};  
  ghc = pkgs.haskell.compiler.${compiler};
in
  pkgs.mkShell {
    buildInputs = with pkgs; [
      ghc
      haskell-language-server
      hlint
      stack
      zlib
    ];
  }