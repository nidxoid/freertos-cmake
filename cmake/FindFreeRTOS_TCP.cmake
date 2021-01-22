
set(FreeRTOS_TCP_BUFFER_ALLOCS 1 2)

if(NOT FreeRTOS_TCP_PATH)
    set(FreeRTOS_TCP_PATH ${CMAKE_CURRENT_LIST_DIR}/../opt/FreeRTOS-Plus-TCP CACHE PATH "Path to FreeRTOS_TCP")
    message(STATUS "No FreeRTOS_TCP_PATH specified using default: ${FreeRTOS_TCP_PATH}")
endif()

find_path(FreeRTOS_TCP_COMMON_INCLUDE
    NAMES FreeRTOS_IP.h
    PATHS "${FreeRTOS_TCP_PATH}/include"
    NO_DEFAULT_PATH
)
list(APPEND FreeRTOS_TCP_INCLUDE_DIRS "${FreeRTOS_TCP_COMMON_INCLUDE}")

find_path(FreeRTOS_TCP_SOURCE_DIR
    NAMES FreeRTOS_IP.c
    PATHS "${FreeRTOS_TCP_PATH}"
    NO_DEFAULT_PATH
)
if(NOT (TARGET FreeRTOS_TCP))
    add_library(FreeRTOS_TCP INTERFACE IMPORTED)
    target_sources(FreeRTOS_TCP INTERFACE
        "${FreeRTOS_TCP_SOURCE_DIR}/FreeRTOS_DHCP.c"
        "${FreeRTOS_TCP_SOURCE_DIR}/FreeRTOS_DNS.c"
        "${FreeRTOS_TCP_SOURCE_DIR}/FreeRTOS_IP.c"
        "${FreeRTOS_TCP_SOURCE_DIR}/FreeRTOS_Sockets.c"
        "${FreeRTOS_TCP_SOURCE_DIR}/FreeRTOS_Stream_Buffer.c"
        "${FreeRTOS_TCP_SOURCE_DIR}/FreeRTOS_TCP_IP.c"
        "${FreeRTOS_TCP_SOURCE_DIR}/FreeRTOS_TCP_WIN.c"
        "${FreeRTOS_TCP_SOURCE_DIR}/FreeRTOS_UDP_IP.c"
        "${FreeRTOS_TCP_SOURCE_DIR}/FreeRTOS_ARP.c"
    )
    target_include_directories(FreeRTOS_TCP INTERFACE
        "${FreeRTOS_TCP_COMMON_INCLUDE}"
        "${FreeRTOS_TCP_PATH}/portable/Compiler/GCC"
    )
    target_link_libraries(FreeRTOS_TCP INTERFACE FreeRTOS)
endif()


foreach(BUFFER_ALLOC ${FreeRTOS_TCP_BUFFER_ALLOCS})
    if(NOT (TARGET FreeRTOS_TCP::BufferAllocation::${BUFFER_ALLOC}))
        add_library(FreeRTOS_TCP::BufferAllocation::${BUFFER_ALLOC} INTERFACE IMPORTED)
        target_sources(FreeRTOS_TCP::BufferAllocation::${BUFFER_ALLOC} INTERFACE
            "${FreeRTOS_TCP_SOURCE_DIR}/portable/BufferManagement/BufferAllocation_${BUFFER_ALLOC}.c")
        target_link_libraries(FreeRTOS_TCP::BufferAllocation::${BUFFER_ALLOC} INTERFACE FreeRTOS_TCP)
    endif()
endforeach()

foreach(COMP ${FreeRTOS_TCP_FIND_COMPONENTS})
    string(TOLOWER ${COMP} COMP_L)
    string(TOUPPER ${COMP} COMP_U)

    string(REGEX MATCH "PHY_?HANDLING" PHY_HANDLING_MATCH ${COMP_U})
    if(PHY_HANDLING_MATCH)
        if(NOT (TARGET FreeRTOS_TCP::PhyHandling))
            add_library(FreeRTOS_TCP::PhyHandling INTERFACE IMPORTED)
            target_sources(FreeRTOS_TCP::PhyHandling INTERFACE
                "${FreeRTOS_TCP_SOURCE_DIR}/portable/NetworkInterface/Common/phyHandling.c")
            target_include_directories(FreeRTOS_TCP::PhyHandling INTERFACE
                "${FreeRTOS_TCP_SOURCE_DIR}/portable/NetworkInterface/include")
            target_link_libraries(FreeRTOS_TCP::PhyHandling INTERFACE FreeRTOS_TCP)
        endif()
        set(FreeRTOS_TCP_${COMP}_FOUND TRUE)
        list(APPEND FreeRTOS_TCP_INCLUDE_DIRS "${FreeRTOS_TCP_SOURCE_DIR}/portable/NetworkInterface/include")
        continue()
    endif()
    list(APPEND FreeRTOS_TCP_PORTS COMP)
endforeach()

foreach(PORT ${FreeRTOS_TCP_PORTS})
    find_path(FreeRTOS_TCP_${PORT}_PATH
        NAMES NetworkInterface.c
        PATHS "${FreeRTOS_TCP_PATH}/portable/NetworkInterface/${PORT}"
        NO_DEFAULT_PATH
    )
    list(APPEND FreeRTOS_TCP_INCLUDE_DIRS "${FreeRTOS_TCP_${PORT}_PATH")
    
    aux_source_directory(FreeRTOS_TCP_${PORT}_SOURCES
        "${FreeRTOS_TCP_${PORT}_PATH"
    )
    if(NOT (TARGET FreeRTOS_TCP::${PORT}))
        add_library(FreeRTOS_TCP::${PORT} INTERFACE IMPORTED)
        target_link_libraries(FreeRTOS_TCP::${PORT} INTERFACE FreeRTOS_TCP)
        target_sources(FreeRTOS_TCP::${PORT} INTERFACE "${FreeRTOS_TCP_${PORT}_SOURCES}")
        target_include_directories(FreeRTOS_TCP::${PORT} INTERFACE "${FreeRTOS_TCP_${PORT}_PATH}")
    endif()
    
    if(FreeRTOS_TCP_${PORT}_PATH
       FreeRTOS_TCP_COMMON_INCLUDE AND
       FreeRTOS_TCP_SOURCE_DIR)
       set(FreeRTOS_TCP_${PORT}_FOUND TRUE)
    else()
       set(FreeRTOS_TCP_${PORT}_FOUND FALSE)
    endif()
endforeach()

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(FreeRTOS_TCP
    REQUIRED_VARS FreeRTOS_TCP_INCLUDE_DIRS
    HANDLE_COMPONENTS
)
