# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit git-r3 xdg desktop

DESCRIPTION="Ship of Harkinian - PC port of The Legend of Zelda: Ocarina of Time"
HOMEPAGE="https://www.shipofharkinian.com https://github.com/HarbourMasters/Shipwright"

EGIT_REPO_URI="https://github.com/HarbourMasters/Shipwright.git"
EGIT_BRANCH="develop"
EGIT_SUBMODULES=( '*' )

LICENSE="public-domain"
SLOT="0"
KEYWORDS=""
RESTRICT="network-sandbox"

IUSE="clang"

RDEPEND="
	dev-cpp/nlohmann_json
	dev-libs/libzip
	dev-libs/spdlog
	dev-libs/tinyxml2
	media-libs/libpng:0=
	media-libs/libsdl2
	media-libs/libvorbis
	media-libs/opusfile
	media-libs/sdl2-net
	virtual/opengl
"

DEPEND="${RDEPEND}"

BDEPEND="
	>=dev-build/cmake-3.20
	dev-build/ninja
	clang? (
		llvm-core/clang
		llvm-core/lld
	)
"

src_configure() {
	local mycmakeargs=(
		-S .
		-B build-cmake
		-GNinja
		-DCMAKE_BUILD_TYPE=Release
		-DSUPPRESS_WARNINGS=1
	)

	use clang && mycmakeargs+=(
		-DCMAKE_C_COMPILER=clang
		-DCMAKE_CXX_COMPILER=clang++
	)

	cd "${S}" || die
	cmake "${mycmakeargs[@]}" || die "cmake configure failed"
}

src_compile() {
	cmake --build "${S}/build-cmake" || die "cmake build failed"
}

src_install() {
	exeinto /usr/libexec/shipwright
	doexe "${S}/build-cmake/soh/soh.elf"

	insinto /usr/libexec/shipwright
	doins "${S}/build-cmake/soh/soh.o2r"

	# Placeholders so Portage tracks these user-writable directories
	keepdir /usr/libexec/shipwright/assets
	keepdir /usr/libexec/shipwright/mods

	cat > "${T}/soh" <<-'EOF'
	#!/bin/sh
	cd /usr/libexec/shipwright || exit 1
	exec ./soh.elf "$@"
	EOF
	dobin "${T}/soh"

	insinto /usr/share/icons/hicolor/256x256/apps
	newins "${S}/build-cmake/sohIcon.png" soh.png
	domenu "${FILESDIR}/soh.desktop"

	dodoc README.md
}

pkg_postinst() {
	xdg_pkg_postinst

	elog "Ship of Harkinian does NOT include any copyrighted game data."
	elog ""
	elog "To generate your game archive (oot.o2r / oot-mq.o2r):"
	elog "  1. Place a supported Ocarina of Time ROM in a convenient location."
	elog "  2. On first launch, soh will prompt you to select your ROM"
	elog "     and will generate the archive automatically."
	elog ""
	elog "Check ROM compatibility at: https://ship.equipment/"
	elog ""
	elog "Mods (.otr files) can be placed in:"
	elog "  /usr/libexec/shipwright/mods/"
	elog "  or ~/.local/share/soh/mods/"
}
