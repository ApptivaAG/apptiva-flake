{lib}: let
    inherit (lib.types) nullOr oneOf bool int float str path attrsOf listOf;
in
lib.types.submodule {
    freeformType = let
    type = nullOr (oneOf [
        bool
        int
        float
        str
        path
        (attrsOf type)
        (listOf type)
    ]) // {
        description = "JSON value";
    };
    in type;
}
