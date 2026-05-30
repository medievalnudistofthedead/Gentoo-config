# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit cmake git-r3 xdg-utils toolchain-funcs

DESCRIPTION="A decompiled and recompiled version of The Legend of Zelda: Majora's Mask"
HOMEPAGE="https://github.com/HarbourMasters/2ship2harkinian"
EGIT_REPO_URI="https://github.com/HarbourMasters/2ship2harkinian.git"
EGIT_BRANCH="develop"
EGIT_SUBMODULES=( "libultraship" "OTRExporter" "ZAPDTR" )

LICENSE="CC0-1.0"
SLOT="0"
KEYWORDS=""
IUSE="debug doc lto +opengl vulkan test"

REQUIRED_USE="
	?? ( opengl vulkan )
"

RDEPEND="
	media-libs/libsdl2[opengl,video,sound,joystick]
	media-libs/libpng:0=
	media-libs/glew:0=
	dev-libs/nlohmann-json
	app-arch/libzip:0=
	media-libs/glm
	x11-libs/libxcb
	x11-libs/libxrandr
	x11-libs/libxinerama
	x11-libs/libxcursor
	x11-libs/libxi
	x11-libs/libxext
	opengl? ( virtual/opengl )
	vulkan? ( media-libs/vulkan-loader )
"

DEPEND="
	${RDEPEND}
	dev-util/ninja
	dev-build/cmake:>=3.26.0
	dev-lang/python:3
	x11-base/xorg-proto
	opengl? ( media-libs/glew:0= )
	vulkan? ( dev-util/vulkan-headers )
"

BDEPEND="
	doc? ( app-doc/doxygen[dot] )
	test? ( dev-cpp/gtest )
"

CMAKE_MIN_VERSION="3.26.0"

src_unpack() {
	git-r3_src_unpack
}

src_prepare() {
	cmake_src_prepare
	
	# Ensure submodules are properly initialized
	git submodule update --init --recursive || die "Failed to update git submodules"
	
	eapply_user
}

src_configure() {
	local mycmakeargs=(
		-DCMAKE_BUILD_TYPE="$(usex debug Debug Release)"
		-DBUILD_TESTING="$(usex test ON OFF)"
		-DCMAKE_INSTALL_PREFIX="${EPREFIX}/usr"
		-DCMAKE_INSTALL_LIBDIR="$(get_libdir)"
		-DCMAKE_SKIP_RPATH=ON
		-DCMAKE_C_COMPILER_LAUNCHER=""
		-DCMAKE_CXX_COMPILER_LAUNCHER=""
	)
	
	# Use LTO if requested and compiler supports it
	if use lto; then
		if tc-is-gcc; then
			append-ldflags -flto
			append-cflags -flto
			append-cxxflags -flto
		elif tc-is-clang; then
			append-ldflags "-flto=thin"
			append-cflags "-flto=thin"
			append-cxxflags "-flto=thin"
		fi
	fi
	
	# Graphics backend selection
	if use vulkan; then
		mycmakeargs+=( -DUSE_VULKAN=ON )
	else
		# OpenGL is the default
		mycmakeargs+=( -DUSE_VULKAN=OFF )
	fi
	
	cmake_src_configure
}

src_compile() {
	cmake_src_compile
	
	if use doc; then
		cmake_src_compile doxygen 2>/dev/null || ewarn "Doxygen documentation build failed (optional)"
	fi
}

src_install() {
	cmake_src_install
	
	# Install the main executable
	dobin "${BUILD_DIR}/2ship" || die "Failed to install executable"
	
	# Install documentation if available
	if use doc; then
		if [[ -d "${BUILD_DIR}/docs/html" ]]; then
			docinto html
			dodoc -r "${BUILD_DIR}/docs/html"/*
		fi
	fi
	
	# Install license
	dodoc "${S}/LICENSE" || die "Failed to install license"
	
	# Create config directory
	keepdir "/usr/share/${PN}"
}

pkg_postinst() {
	xdg_desktop_database_update
	xdg_mimeinfo_database_update
	
	elog ""
	elog "=========================================="
	elog "2 Ship 2 Harkinian has been installed!"
	elog "=========================================="
	elog ""
	elog "IMPORTANT: You must provide your own ROM!"
	elog ""
	elog "2ship2harkinian requires a legally obtained"
	elog "copy of The Legend of Zelda: Majora's Mask."
	elog ""
	elog "Supported ROM versions:"
	elog "  - Majora's Mask (USA) v1.0"
	elog "  - Majora's Mask (USA) v1.1"
	elog "  - Majora's Mask (EUR)"
	elog "  - Majora's Mask (JPN)"
	elog ""
	elog "To verify your ROM:"
	elog "  - Online: https://2ship.equipment/"
	elog "  - SHA1 list: https://github.com/HarbourMasters/2ship2harkinian/blob/develop/docs/supportedHashes.json"
	elog ""
	elog "Usage:"
	elog "  $ 2ship"
	elog ""
	elog "On first run, you'll be prompted to select your ROM file."
	elog "Place it in the same directory as the executable, or select it manually."
	elog ""
	elog "Default Controls:"
	elog "  A Button: X          Start: Space"
	elog "  B Button: C          D-Pad: TFGH"
	elog "  Z Button: Z          Analog: WASD"
	elog "  C-Buttons: Arrow Keys"
	elog ""
	elog "Shortcuts:"
	elog "  F1: Toggle menubar    F11: Toggle fullscreen"
	elog "  Tab: Alternate assets Ctrl+R: Reset"
	elog ""
	elog "For more information and community support:"
	elog "  GitHub: https://github.com/HarbourMasters/2ship2harkinian"
	elog "  Discord: https://discord.com/invite/shipofharkinian"
	elog ""
	elog "=========================================="
	elog ""
}

pkg_postrm() {
	xdg_desktop_database_update
	xdg_mimeinfo_database_update
}
