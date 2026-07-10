ts      := "tree-sitter"
name    := "tree-sitter-kanata"
version := "0.1.0"
url     := "https://github.com/postsolar/tree-sitter-kanata"

PREFIX    := "/usr/local"
lib_dir   := PREFIX + "/lib"
inc_dir   := PREFIX + "/include"
pc_dir    := lib_dir + "/pkgconfig"
query_dir := PREFIX + "/share/tree-sitter/queries/kanata"

os  := `uname -s`
abi := `sed -n 's/#define LANGUAGE_VERSION //p' src/parser.c`

soext := if os == "Darwin" { "dylib" } else { "so" }
link_flags := if os == "Darwin" {
    "-dynamiclib -Wl,-install_name," + lib_dir + "/lib" + name + "." + abi + ".dylib"
} else {
    "-shared -Wl,-soname,lib" + name + ".so." + abi
}

# Regenerate parser from grammar.js
generate:
    {{ts}} generate

# Run corpus tests
test:
    {{ts}} test

# Build WASM binary for playground
build-wasm:
    {{ts}} build --wasm

# Launch tree-sitter playground
play:
    {{ts}} playground

# Remove build artifacts
clean:
    rm -rf target/ build/ .build/ *.wasm src/*.o lib{{name}}.* {{name}}.pc

# Build static and shared C library + pkg-config file
build: generate
    #!/usr/bin/env bash
    set -euo pipefail

    echo "==> Compiling parser..."
    cc -Isrc -std=c11 -fPIC -c src/parser.c -o src/parser.o
    OBJS="src/parser.o"

    if [ -f src/scanner.c ]; then
        echo "==> Compiling scanner..."
        cc -Isrc -std=c11 -fPIC -c src/scanner.c -o src/scanner.o
        OBJS="$OBJS src/scanner.o"
    fi

    echo "==> Archiving static library..."
    ar rcs lib{{name}}.a $OBJS

    echo "==> Linking shared library..."
    cc {{link_flags}} $OBJS -o lib{{name}}.{{abi}}.{{version}}.{{soext}}

    echo "==> Generating pkg-config..."
    sed -e 's|@PROJECT_VERSION@|{{version}}|' \
        -e 's|@CMAKE_INSTALL_LIBDIR@|lib|' \
        -e 's|@CMAKE_INSTALL_INCLUDEDIR@|include|' \
        -e 's|@PROJECT_DESCRIPTION@|Tree-sitter grammar for kanata|' \
        -e 's|@PROJECT_HOMEPAGE_URL@|{{url}}|' \
        -e 's|@CMAKE_INSTALL_PREFIX@|{{PREFIX}}|' \
        bindings/c/{{name}}.pc.in > {{name}}.pc

# Install C library system-wide
install: build
    #!/usr/bin/env bash
    set -euo pipefail

    echo "==> Creating directories..."
    install -d {{lib_dir}} {{inc_dir}}/tree_sitter {{pc_dir}} {{query_dir}}

    echo "==> Installing headers and pkg-config..."
    install -m644 bindings/c/{{name}}.h {{inc_dir}}/tree_sitter/{{name}}.h
    install -m644 {{name}}.pc {{pc_dir}}/{{name}}.pc

    echo "==> Installing libraries..."
    install -m644 lib{{name}}.a {{lib_dir}}/lib{{name}}.a
    install -m755 lib{{name}}.{{abi}}.{{version}}.{{soext}} {{lib_dir}}/lib{{name}}.{{abi}}.{{version}}.{{soext}}

    echo "==> Setting up symlinks..."
    ln -sf lib{{name}}.{{abi}}.{{version}}.{{soext}} {{lib_dir}}/lib{{name}}.{{abi}}.{{soext}}
    ln -sf lib{{name}}.{{abi}}.{{soext}} {{lib_dir}}/lib{{name}}.{{soext}}

    echo "==> Installing queries..."
    # Check if there are any .scm files to install to prevent bash errors
    if ls queries/*.scm >/dev/null 2>&1; then
        install -m644 queries/*.scm {{query_dir}}/
    fi

# Uninstall C library
uninstall:
    #!/usr/bin/env bash
    set -euo pipefail

    echo "==> Removing libraries..."
    rm -f {{lib_dir}}/lib{{name}}.a \
          {{lib_dir}}/lib{{name}}.{{abi}}.{{version}}.{{soext}} \
          {{lib_dir}}/lib{{name}}.{{abi}}.{{soext}} \
          {{lib_dir}}/lib{{name}}.{{soext}}

    echo "==> Removing headers and pkg-config..."
    rm -f {{inc_dir}}/tree_sitter/{{name}}.h \
          {{pc_dir}}/{{name}}.pc

    echo "==> Removing queries..."
    rm -rf {{query_dir}}

    echo "==> Uninstall complete."
