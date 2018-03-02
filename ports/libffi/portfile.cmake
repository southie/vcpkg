if(NOT VCPKG_TARGET_ARCHITECTURE STREQUAL x86 AND NOT VCPKG_TARGET_ARCHITECTURE STREQUAL x64)
    message(FATAL_ERROR "Architecture not supported")
endif()

include(vcpkg_common_functions)
vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO libffi/libffi
    REF v3.2.1
    SHA512 e947ff66a9f3bc77c05dd2d4b7c6edc1c607374922879d0099bbef144a16c612eb283f6d067ed6c7e1ee39f98c8be0d41856e91234d810218fc7ae439d73d10f
    HEAD_REF master
)

file(COPY ${CMAKE_CURRENT_LIST_DIR}/CMakeLists.txt DESTINATION ${SOURCE_PATH})

vcpkg_apply_patches(
    SOURCE_PATH ${SOURCE_PATH}
    PATCHES
        ${CMAKE_CURRENT_LIST_DIR}/export-global-data.patch)

vcpkg_configure_cmake(
    SOURCE_PATH ${SOURCE_PATH}
    OPTIONS
        -DFFI_CONFIG_FILE=${CMAKE_CURRENT_LIST_DIR}/fficonfig.h
    OPTIONS_DEBUG
        -DFFI_SKIP_HEADERS=ON)

vcpkg_install_cmake()
vcpkg_copy_pdbs()

if(VCPKG_LIBRARY_LINKAGE STREQUAL static)
    vcpkg_apply_patches(
        SOURCE_PATH ${CURRENT_PACKAGES_DIR}/include
        PATCHES
            ${CMAKE_CURRENT_LIST_DIR}/auto-define-static-macro.patch)
endif()

file(COPY ${SOURCE_PATH}/LICENSE DESTINATION ${CURRENT_PACKAGES_DIR}/share/libffi)
file(RENAME ${CURRENT_PACKAGES_DIR}/share/libffi/LICENSE ${CURRENT_PACKAGES_DIR}/share/libffi/copyright)
