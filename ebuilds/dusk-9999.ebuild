# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{10..13} )

inherit git-r3 python-any-r1 xdg desktop

DESCRIPTION="Reimplementation of The Legend of Zelda: Twilight Princess"
HOMEPAGE="https://twilitrealm.dev https://github.com/TwilitRealm/dusk"

EGIT_REPO_URI="https://github.com/TwilitRealm/dusk.git"
EGIT_BRANCH="main"
EGIT_SUBMODULES=( '*' )

LICENSE="CC0-1.0"
SLOT="0"
KEYWORDS=""
RESTRICT="network-sandbox"

IUSE="clang"

RDEPEND="
	media-libs/alsa-lib
	media-libs/freetype:2
	media-libs/libpng:0=
	media-libs/mesa[opengl]
	media-video/pipewire
	net-misc/curl
	sys-apps/dbus
	sys-libs/ncurses:0=
	sys-libs/zlib:0=
	virtual/udev
	x11-libs/gtk+:3
	x11-libs/libX11
	x11-libs/libXcursor
	x11-libs/libXi
	x11-libs/libXinerama
	x11-libs/libXrandr
	x11-libs/libXScrnSaver
	x11-libs/libXtst
"

DEPEND="
	${RDEPEND}
	dev-util/vulkan-headers
"

BDEPEND="
	${PYTHON_DEPS}
	dev-build/cmake
	dev-build/ninja
	clang? (
		llvm-core/clang
		llvm-core/lld
	)
"

readonly _PRESET="linux-default-relwithdebinfo"
readonly _PRESET_CLANG="linux-clang-relwithdebinfo"

pkg_setup() {
	python-any-r1_pkg_setup
}

src_configure() {
	local preset
	use clang && preset="${_PRESET_CLANG}" || preset="${_PRESET}"

	cd "${S}" || die

	cmake --preset "${preset}" \
		-DCMAKE_INSTALL_PREFIX="${EPREFIX}/usr" \
		|| die "cmake configure failed"

	echo "${preset}" > "${T}/active_preset" || die
}

src_compile() {
	local preset
	preset="$(<"${T}/active_preset")" || die

	cmake --build "${S}/build/${preset}" || die "cmake build failed"
}

src_install() {
	local preset build_dir
	preset="$(<"${T}/active_preset")" || die
	build_dir="${S}/build/${preset}"

	# Explicitly create /opt/dusk with world-traversable permissions
	diropts -m 0755
	dodir /opt/dusk

	exeinto /opt/dusk
	doexe "${build_dir}/dusk"

	insinto /opt/dusk/res
	doins -r "${S}/res/."

	# Ensure all subdirs under res/ are also traversable by regular users
	fperms -R a+rX /opt/dusk

	cat > "${T}/dusk" <<-'EOF'
	#!/bin/sh
	exec /opt/dusk/dusk "$@"
	EOF
	dobin "${T}/dusk"

	insinto /usr/share/icons/hicolor/256x256/apps
	newins "${S}/res/logo-mascot.png" dusk.png
	domenu "${FILESDIR}/dusk.desktop"

	dodoc README.md
}

pkg_postinst() {
	xdg_pkg_postinst

	elog "Dusk does NOT include any game data."
	elog "You must supply your own supported disc image (GCM/ISO, RVZ, etc.)."
	elog ""
	elog "Supported dumps (SHA-1):"
	elog "  GameCube USA: 75edd3ddff41f125d1b4ce1a40378f1b565519e7"
	elog "  GameCube EUR: 2601822a488eeb86fb89db16ca8f29c2c953e1ca"
	elog ""
	elog "Usage: dusk /path/to/game.rvz"
}
