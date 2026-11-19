/*
  Pi (pi.dev), packaged ourselves from the npm registry instead of upstream's
  flake. Upstream's own flake build fetches a model catalog from pi.dev at
  build time (fixed-output derivation), which this network blocks (TLS reset
  on connect, confirmed outside Nix too). The npm-published package ships a
  prebuilt dist/bundle/cli.js - no network, no build step, needed at all.

  package.json/package-lock.json here are a thin wrapper depending on
  @earendil-works/pi-coding-agent; upstream does not publish a lockfile for
  it, so this generates one against the real package instead of vendoring
  upstream's monorepo workspace build.
*/
{
  lib,
  buildNpmPackage,
}:
buildNpmPackage (finalAttrs: {
  pname = "pi";
  version = "1.5.2";

  src = ./.;
  npmDepsHash = "sha256-yj1Mw8X4/1cBK9aTMxxoRsYMJ0OVl3BbisPHDmFBANE=";

  # dist/bundle/cli.js ships prebuilt in the published package - nothing to
  # build. The default installPhase already links $out/bin/pi correctly from
  # package.json's "bin" field.
  dontNpmBuild = true;

  meta = {
    description = "Pi, the AI coding agent harness (pi.dev), packaged from npm";
    homepage = "https://pi.dev";
    license = lib.licenses.mit;
    mainProgram = "pi";
  };
})
