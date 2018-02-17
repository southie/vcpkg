if(VCPKG_LIBRARY_LINKAGE STREQUAL "dynamic")
    message(STATUS "Warning: Dynamic building not supported. Building static.")
    set(VCPKG_LIBRARY_LINKAGE static)
endif()

if(VCPKG_CRT_LINKAGE STREQUAL "dynamic")
    message(FATAL_ERROR "libmupdf can only be built with static CRT linkage")
    set(VCPKG_CRT_LINKAGE static)
endif()

if(NOT VCPKG_TARGET_ARCHITECTURE STREQUAL "x86" AND NOT VCPKG_TARGET_ARCHITECTURE STREQUAL "x64")
    message(FATAL_ERROR "libmupdf can only build for x86 and x64")
endif()

if(VCPKG_CMAKE_SYSTEM_NAME AND NOT VCPKG_CMAKE_SYSTEM_NAME STREQUAL "Windows")
    message(FATAL_ERROR "libmupdf can only build for Windows Desktop")
endif()

if(NOT VCPKG_CRT_LINKAGE STREQUAL "dynamic")
    message(FATAL_ERROR "libmupdf can only build for dynamic CRT linkage")
endif()

message(STATUS "=== Libmupdf has internal, binary incompatible forks of several third party libraries. ===")
message(STATUS "=== For this reason, it will not be linked automatically into your MSBuild projects. ===")
message(STATUS "=== You must explicitly link libthirdparty.lib, libmuthreads.lib, and libmupdf.lib ===")

include(vcpkg_common_functions)
set (MUPDF_VERSION 1.12.0)
set(SOURCE_PATH ${CURRENT_BUILDTREES_DIR}/src/mupdf-${MUPDF_VERSION}-source)
vcpkg_download_distfile(ARCHIVE
    URLS "https://mupdf.com/downloads/archive/mupdf-${MUPDF_VERSION}-source.tar.gz"
    FILENAME "mupdf-${MUPDF_VERSION}-source.tar.gz"
    SHA512 11ae620e55e9ebd5844abd7decacc0dafc90dd1f4907ba6ed12f5c725d3920187fc730a7fc33979bf3ff9451da7dbb51f34480a878083e2064f3455555f47d96
)
vcpkg_extract_source_archive(${ARCHIVE})

vcpkg_apply_patches(
    SOURCE_PATH ${SOURCE_PATH}
    PATCHES "${CMAKE_CURRENT_LIST_DIR}/missing-includes.patch"
)

find_program(DEVENV devenv.exe)
if(NOT DEVENV)
    message(FATAL_ERROR "libmupdf requires a full installation of Visual Studio to build.")
endif()

vcpkg_execute_required_process(
    COMMAND "${DEVENV}" /upgrade "${SOURCE_PATH}/platform/win32/mupdf.sln"
    WORKING_DIRECTORY "${SOURCE_PATH}/platform/win32"
    LOGNAME upgrade-${TARGET_TRIPLET}
)

vcpkg_build_msbuild(
    PROJECT_PATH ${SOURCE_PATH}/platform/win32/mupdf.sln
    TARGET generated
    RELEASE_CONFIGURATION Debug
    PLATFORM Win32
)

# Clone the sources into a separate directory to prevent build cross-contamination
set(TEMP_SOURCE_PATH "${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}/mupdf-${MUPDF_VERSION}-source")
if(EXISTS "${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}")
    file(REMOVE_RECURSE ${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET})
endif()

file(MAKE_DIRECTORY "${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}")
file(COPY ${SOURCE_PATH} DESTINATION "${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}")

set(PLATFORM ${VCPKG_TARGET_ARCHITECTURE})
if(VCPKG_TARGET_ARCHITECTURE STREQUAL "x86")
    set(PLATFORM Win32)
endif()

set(ENV{__CL__} /MP)

vcpkg_build_msbuild(
    PROJECT_PATH "${TEMP_SOURCE_PATH}/platform/win32/mupdf.sln"
    TARGET "libthirdparty\\\\\\\\\\\\\\;libresources\\\\\\\\\\\\\\;libmupdf"
    PLATFORM ${PLATFORM}
)

file(COPY ${SOURCE_PATH}/include/mupdf DESTINATION ${CURRENT_PACKAGES_DIR}/include)
file(MAKE_DIRECTORY
    ${CURRENT_PACKAGES_DIR}/lib/manual-link
    ${CURRENT_PACKAGES_DIR}/debug/lib/manual-link
)
file(COPY
    ${TEMP_SOURCE_PATH}/platform/win32/Debug/libthirdparty.lib
    ${TEMP_SOURCE_PATH}/platform/win32/Debug/libmuthreads.lib
    ${TEMP_SOURCE_PATH}/platform/win32/Debug/libmupdf.lib
    DESTINATION ${CURRENT_PACKAGES_DIR}/debug/lib/manual-link
)
file(COPY
    ${TEMP_SOURCE_PATH}/platform/win32/Release/libthirdparty.lib
    ${TEMP_SOURCE_PATH}/platform/win32/Release/libmuthreads.lib
    ${TEMP_SOURCE_PATH}/platform/win32/Release/libmupdf.lib
    DESTINATION ${CURRENT_PACKAGES_DIR}/lib/manual-link
)

vcpkg_copy_pdbs()

#copyright
file(COPY ${SOURCE_PATH}/COPYING DESTINATION ${CURRENT_PACKAGES_DIR}/share/${PORT})
file(RENAME ${CURRENT_PACKAGES_DIR}/share/${PORT}/COPYING ${CURRENT_PACKAGES_DIR}/share/${PORT}/COPYRIGHT)
