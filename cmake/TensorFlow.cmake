function(TENSORFLOW_BUILD TARGET_NAME TF_DIR TOOLCHAIN_TYPE TF_TARGET_VAR TENSORFLOW_FRAMEWORK_SHARED_OBJECT)
    execute_process(COMMAND cat "${TF_DIR}/.bazelversion" OUTPUT_VARIABLE BAZEL_VERSION OUTPUT_STRIP_TRAILING_WHITESPACE)
    message(STATUS "Bazel version: ${BAZEL_VERSION}")

    function(join_list LIST_INPUT STR_OUTPUT)
        string(REPLACE ";" " " __tmp "${${LIST_INPUT}}")
        set(${STR_OUTPUT} "${__tmp}" PARENT_SCOPE)
    endfunction()

    if (NOT BAZEL_EXECUTABLE)
        set(BAZEL_EXECUTABLE "$ENV{HOME}/bin/bazel-${BAZEL_VERSION}/bazel")
        if (NOT EXISTS "${BAZEL_EXECUTABLE}")
            message(STATUS "Could not find bazel executable: ${BAZEL_EXECUTABLE}")
            if (EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/toolchain/sdk-x86_64/bin/bazel")
              set(BAZEL_EXECUTABLE "${CMAKE_CURRENT_SOURCE_DIR}/toolchain/sdk-x86_64/bin/bazel")
            else()
              set(BAZEL_EXECUTABLE bazel)
            endif()
        endif()
        message(STATUS "Using bazel executable: ${BAZEL_EXECUTABLE}")
    endif()

    #join_list("${TF_TARGET_VAR}" __tf_targets)
    set(__tf_targets ${${TF_TARGET_VAR}})
    message(STATUS "Tensorflow targets: ${TARGET_NAME} -> ${__tf_targets}")

    set(BAZEL_CACHE_DIR "/spare/$ENV{USER}/${CMAKE_CURRENT_LIST_DIR}/bazel-cache-${TOOLCHAIN_TYPE}")
    message(STATUS "BAZEL_CACHE_DIR=${BAZEL_CACHE_DIR}")

    if (TOOLCHAIN_TYPE STREQUAL "clang")
        set(CEREBRAS_TOOLCHAIN_ENV -E env "CC=clang-8" env "CXX=clang++-8")
        set(OTHER_TF_ARGS "--cxxopt='-Wno-c++11-narrowing'")
    elseif (USE_CEREBRAS_GCC_TOOLCHAIN)
        set(CEREBRAS_TOOLCHAIN_ENV -E env "CC=${CMAKE_C_COMPILER}" env "CXX=${CMAKE_CXX_COMPILER}")
    else()
        set(CEREBRAS_TOOLCHAIN_ENV -E env "CC=${CMAKE_C_COMPILER}" env "CXX=${CMAKE_CXX_COMPILER}")
    endif()

    # -Namespaces
        set(OTHER_TF_ARGS ${OTHER_TF_ARGS} "--copt='-Dtensorflow=ptxla_tf'")
        set(OTHER_TF_ARGS ${OTHER_TF_ARGS} "--cxxopt='-Dtensorflow=ptxla_tf'")

        set(OTHER_TF_ARGS ${OTHER_TF_ARGS} "--cxxopt='-DEigen=ptxla_Eigen'")

        set(OTHER_TF_ARGS ${OTHER_TF_ARGS} "--copt='-Dgrpc=ptxla_grpc'")
        set(OTHER_TF_ARGS ${OTHER_TF_ARGS} "--cxxopt='-Dgrpc=ptxla_grpc'")
        set(OTHER_TF_ARGS ${OTHER_TF_ARGS} "--cxxopt='-Dgrpc_impl=ptxla_grpc_impl'")

        set(OTHER_TF_ARGS ${OTHER_TF_ARGS} "--copt='-Dgoogle=ptxla_google'")
        set(OTHER_TF_ARGS ${OTHER_TF_ARGS} "--cxxopt='-Dgoogle=ptxla_google'")

        set(OTHER_TF_ARGS ${OTHER_TF_ARGS} "--cxxopt='-Dllvm=ptxla_llvm'")
        set(OTHER_TF_ARGS ${OTHER_TF_ARGS} "--cxxopt='-Dmlir=ptxla_mlir'")
    # Namespaces-

    message(STATUS "USE_CUDA=${USE_CUDA}")
    message(STATUS "TF_USE_CUDA=${TF_USE_CUDA}")
    if (USE_CUDA OR TF_USE_CUDA)
        set(OTHER_TF_ARGS ${OTHER_TF_ARGS} --config=cuda --cxxopt="-DXLA_CUDA=1")
        list(APPEND CEREBRAS_TOOLCHAIN_ENV env "TF_CUDA_COMPUTE_CAPABILITIES=6.1")
    endif()

    #if (NOT ${TENSORFLOW_FRAMEWORK_SHARED_OBJECT})
    set(OTHER_TF_ARGS ${OTHER_TF_ARGS} "--define" "framework_shared_object=false")
    #endif()

    message(STATUS "CEREBRAS_TOOLCHAIN_ENV: ${CEREBRAS_TOOLCHAIN_ENV}")
    message(STATUS "TOOLCHAIN_TYPE: ${TOOLCHAIN_TYPE}")
    message(STATUS "OTHER_TF_ARGS [${TARGET_NAME}] =${OTHER_TF_ARGS}")

    add_custom_target(
            ${TARGET_NAME}
            WORKING_DIRECTORY "${TF_DIR}"
            COMMAND
            ${CMAKE_COMMAND}
            ${CEREBRAS_TOOLCHAIN_ENV} ${TF_CUDA_ENV} ${BAZEL_EXECUTABLE}
            "--output_user_root=${BAZEL_CACHE_DIR}"
            "build"
            "--verbose_failures"
            "--cxxopt='-std=c++14'"
            ${OTHER_TF_ARGS}
            "--strip=never"
            "--copt=-fdiagnostics-color=always"
            "--copt=-fuse-ld=gold"
            "--copt=-Wl,--gdb-index"
            "--linkopt=-Wl,--gdb-index"
            ${__tf_targets}
    )
    add_custom_target(
            ${TARGET_NAME}_clean
            ${TARGET_NAME}
            WORKING_DIRECTORY "${TF_DIR}"
            COMMAND
            ${CMAKE_COMMAND}
            ${CEREBRAS_TOOLCHAIN_ENV} ${TF_CUDA_ENV} ${BAZEL_EXECUTABLE}
            "--output_user_root=${BAZEL_CACHE_DIR}"
            "clean"
    )
endfunction()


function(TENSORFLOW_MONOLITH_BUILD TARGET_NAME TF_DIR TOOLCHAIN_TYPE TF_TARGET_VAR TENSORFLOW_FRAMEWORK_SHARED_OBJECT)
    execute_process(COMMAND cat "${TF_DIR}/.bazelversion" OUTPUT_VARIABLE BAZEL_VERSION OUTPUT_STRIP_TRAILING_WHITESPACE)
    message(STATUS "Bazel version: ${BAZEL_VERSION}")

    function(join_list LIST_INPUT STR_OUTPUT)
        string(REPLACE ";" " " __tmp "${${LIST_INPUT}}")
        set(${STR_OUTPUT} "${__tmp}" PARENT_SCOPE)
    endfunction()

    if (NOT BAZEL_EXECUTABLE)
        set(BAZEL_EXECUTABLE "$ENV{HOME}/bin/bazel-${BAZEL_VERSION}/bazel")
        if (NOT EXISTS "${BAZEL_EXECUTABLE}")
            message(STATUS "Could not find bazel executable: ${BAZEL_EXECUTABLE}")
            if (EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/toolchain/sdk-x86_64/bin/bazel")
                set(BAZEL_EXECUTABLE "${CMAKE_CURRENT_SOURCE_DIR}/toolchain/sdk-x86_64/bin/bazel")
            else()
                set(BAZEL_EXECUTABLE bazel)
            endif()
        endif()
        message(STATUS "Using bazel executable: ${BAZEL_EXECUTABLE}")
    endif()

    #join_list("${TF_TARGET_VAR}" __tf_targets)
    set(__tf_targets ${${TF_TARGET_VAR}})
    message(STATUS "Tensorflow targets: ${TARGET_NAME} -> ${__tf_targets}")

    set(BAZEL_CACHE_DIR "/spare/$ENV{USER}/tf_monolith/${CMAKE_CURRENT_LIST_DIR}/bazel-cache-monolith-${TOOLCHAIN_TYPE}")
    message(STATUS "BAZEL_CACHE_DIR=${BAZEL_CACHE_DIR}")

    if (TOOLCHAIN_TYPE STREQUAL "clang")
        set(CEREBRAS_TOOLCHAIN_ENV -E env "CC=clang-8" env "CXX=clang++-8")
        set(OTHER_TF_ARGS "--cxxopt='-Wno-c++11-narrowing'")
    elseif (USE_CEREBRAS_GCC_TOOLCHAIN)
        set(CEREBRAS_TOOLCHAIN_ENV -E env "CC=${CMAKE_C_COMPILER}" env "CXX=${CMAKE_CXX_COMPILER}")
    else()
        set(CEREBRAS_TOOLCHAIN_ENV -E env "CC=${CMAKE_C_COMPILER}" env "CXX=${CMAKE_CXX_COMPILER}")
    endif()

    message(STATUS "USE_CUDA=${USE_CUDA}")
    message(STATUS "TF_USE_CUDA=${TF_USE_CUDA}")
    if (USE_CUDA OR TF_USE_CUDA)
        set(OTHER_TF_ARGS ${OTHER_TF_ARGS} --config=cuda --cxxopt="-DXLA_CUDA=1")
        list(APPEND CEREBRAS_TOOLCHAIN_ENV env "TF_CUDA_COMPUTE_CAPABILITIES=6.1")
    endif()

    # -Namespaces
    #set(OTHER_TF_ARGS ${OTHER_TF_ARGS} "--copt='-Dtensorflow=ptxla_tf'")
    #set(OTHER_TF_ARGS ${OTHER_TF_ARGS} "--cxxopt='-Dtensorflow=ptxla_tf'")

    #set(OTHER_TF_ARGS ${OTHER_TF_ARGS} "--cxxopt='-DEigen=ptxla_Eigen'")

    set(OTHER_TF_ARGS ${OTHER_TF_ARGS} "--copt='-Dgrpc=cerebras_grpc'")
    set(OTHER_TF_ARGS ${OTHER_TF_ARGS} "--cxxopt='-Dgrpc=cerebras_grpc'")
    set(OTHER_TF_ARGS ${OTHER_TF_ARGS} "--cxxopt='-Dgrpc_impl=cerebras_grpc_impl'")

    #set(OTHER_TF_ARGS ${OTHER_TF_ARGS} "--copt='-Dgoogle=cerebras_google'")
    #set(OTHER_TF_ARGS ${OTHER_TF_ARGS} "--cxxopt='-Dgoogle=cerebras_google'")

    set(OTHER_TF_ARGS ${OTHER_TF_ARGS} "--cxxopt='-Dllvm=cerebras_llvm'")
    # Namespaces-

    # No framework shared object
    set(OTHER_TF_ARGS ${OTHER_TF_ARGS} "--define" "framework_shared_object=false")

    message(STATUS "CEREBRAS_TOOLCHAIN_ENV: ${CEREBRAS_TOOLCHAIN_ENV}")
    message(STATUS "TOOLCHAIN_TYPE: ${TOOLCHAIN_TYPE}")
    message(STATUS "OTHER_TF_ARGS [${TARGET_NAME}] =${OTHER_TF_ARGS}")

    # bazel build --action_env TF_SYSTEM_LIBS="protobuf,grpc"
    add_custom_target(
            ${TARGET_NAME}
            WORKING_DIRECTORY "${TF_DIR}"
            COMMAND
            ${CMAKE_COMMAND}
            ${CEREBRAS_TOOLCHAIN_ENV} ${TF_CUDA_ENV} ${BAZEL_EXECUTABLE}
            "--output_user_root=${BAZEL_CACHE_DIR}"
            "build"
            "--verbose_failures"
            "--cxxopt='-std=c++14'"
            ${OTHER_TF_ARGS}
            "--strip=never"
            "--copt=-fdiagnostics-color=always"
            "--copt=-fuse-ld=gold"
            "--copt=-Wl,--gdb-index"
            "--linkopt=-Wl,--gdb-index"
            ${__tf_targets}
    )
    add_custom_target(
            ${TARGET_NAME}_clean
            WORKING_DIRECTORY "${TF_DIR}"
            COMMAND
            ${CMAKE_COMMAND}
            ${CEREBRAS_TOOLCHAIN_ENV} ${TF_CUDA_ENV} ${BAZEL_EXECUTABLE}
            "--output_user_root=${BAZEL_CACHE_DIR}"
            "clean"
            "--expunge"
    )
endfunction()
