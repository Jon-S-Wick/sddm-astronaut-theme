{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  kdePackages,
  formats,
  themeConfig ? null,
  embeddedTheme ? "astronaut",
}:

{
  description = "Custom sddm theme";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      inherit (nixpkgs.lib) genAttrs optional;
      eachSystem =
        f:
        genAttrs [
          "aarch64-darwin"
          "aarch64-linux"
          "x86_64-darwin"
          "x86_64-linux"
        ] (system: f nixpkgs.legacyPackages.${system});

      custom-sddm =
        {
          pkgs,
          splash ? "",
          background ? "",
          customSplash ? splash != "",
          boot-options-count,
          ...
        }:
        pkgs.stdenv.mkDerivation {
          name = "custom-sddm";
          src = "${self}";

          buildInputs =
            with pkgs;
            optional customSplash [
              fastfetch
              (python3.withPackages (p: [ p.pillow ]))
            ];

          installPhase =
            let
              iniFormat = formats.ini { };
              configFile = iniFormat.generate "" { General = themeConfig; };

              basePath = "$out/share/sddm/themes/sddm-astronaut-theme";
              sedString = "ConfigFile=Themes/";
            in
            ''
              mkdir -p ${basePath}
              cp -r $src/* ${basePath}
            ''
            + lib.optionalString (embeddedTheme != "astronaut") ''

              # Replaces astronaut.conf with embedded theme in metadata.desktop on line 9.
              # ConfigFile=Themes/astronaut.conf.
              sed -i "s|^${sedString}.*\\.conf$|${sedString}${embeddedTheme}.conf|" ${basePath}/metadata.desktop
            ''
            + lib.optionalString (themeConfig != null) ''
              chmod u+w ${basePath}/Themes/
              ln -sf ${configFile} ${basePath}/Themes/${embeddedTheme}.conf.user
            '';
        };
    in
    {

      packages = eachSystem (pkgs: {
        default = custom-sddm {
          inherit pkgs;
          # splash = "custom splash text";
        };
      });
    };
}
