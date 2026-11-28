# Optional PipeWire support.
#
# The PipeWire libraries are host libraries, reached through a wrap_elf()
# wrapper just like FFmpeg and PulseAudio. Detection is deliberately soft: a
# Darling tree can still be configured on hosts without PipeWire development
# files, in which case the PipeWire backend and the camera portal backend are
# not built.
#
# The backends are off by default: they are untested and known to be broken.
# The audio backend takes over from the PulseAudio one whenever a PipeWire
# server is reachable, but offers only three fixed default devices with no
# channels instead of the server's sinks and sources, so applications and the
# Darling preference pane find no usable audio device. The camera and
# screen-capture backends have not been tested against real devices either.
# PulseAudio (which PipeWire servers also offer through pipewire-pulse) stays
# the audio backend. Pass -DENABLE_PIPEWIRE=ON to build them anyway.

include(wrap_elf)

option(ENABLE_PIPEWIRE "Build the PipeWire audio, camera and screen-capture backends when available (untested, known broken)" OFF)

set(HAVE_PIPEWIRE 0)

if (ENABLE_PIPEWIRE)
	find_package(PkgConfig QUIET)
	if (PkgConfig_FOUND)
		pkg_check_modules(PC_PIPEWIRE QUIET libpipewire-0.3)
	endif ()

	if (PC_PIPEWIRE_FOUND)
		find_path(PIPEWIRE_INCLUDE_DIR
			NAMES pipewire/pipewire.h
			HINTS ${PC_PIPEWIRE_INCLUDE_DIRS}
		)
		string(REGEX REPLACE "(^|[ ;])-l" "\\1" _pipewire_link_libraries "${PC_PIPEWIRE_LIBRARIES}")
		find_library(PIPEWIRE_ELF_LIBRARY
			NAMES ${_pipewire_link_libraries} pipewire-0.3 pipewire
			HINTS ${PC_PIPEWIRE_LIBRARY_DIRS}
		)
	endif ()

	if (PIPEWIRE_INCLUDE_DIR AND PIPEWIRE_ELF_LIBRARY)
		set(HAVE_PIPEWIRE 1)
		wrap_elf(pipewire "${PIPEWIRE_ELF_LIBRARY}" OPTIONAL darling_pipewire_available)
		message(WARNING "PipeWire backends: enabled (${PIPEWIRE_ELF_LIBRARY}). They are untested and known to be broken; the audio backend lists no usable devices.")
	else ()
		message(STATUS "PipeWire backend: disabled (development files not found)")
	endif ()
else ()
	message(STATUS "PipeWire backends: disabled (untested and known to be broken; -DENABLE_PIPEWIRE=ON builds them)")
endif ()

# Components that use the PipeWire backends call this from their own directory: the
# compile definition and the host include directories are scoped to them instead of
# being added to every translation unit of the tree.
macro(darling_use_pipewire)
	if (HAVE_PIPEWIRE)
		include_directories(${PIPEWIRE_INCLUDE_DIR} ${PC_PIPEWIRE_INCLUDE_DIRS})
		add_compile_definitions(HAVE_PIPEWIRE=1)
	endif ()
endmacro()
