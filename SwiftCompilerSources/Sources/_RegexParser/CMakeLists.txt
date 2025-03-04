# This source file is part of the Swift.org open source project
#
# Copyright (c) 2014 - 2021 Apple Inc. and the Swift project authors
# Licensed under Apache License v2.0 with Runtime Library Exception
#
# See http://swift.org/LICENSE.txt for license information
# See http://swift.org/CONTRIBUTORS.txt for Swift project authors

file(GLOB_RECURSE _LIBSWIFT_REGEX_PARSER_SOURCES
  "${EXPERIMENTAL_STRING_PROCESSING_SOURCE_DIR}/Sources/_RegexParser/*.swift")
set(LIBSWIFT_REGEX_PARSER_SOURCES)
foreach(source ${_LIBSWIFT_REGEX_PARSER_SOURCES})
  file(TO_CMAKE_PATH "${source}" source)
  list(APPEND LIBSWIFT_REGEX_PARSER_SOURCES ${source})
endforeach()
message(STATUS "Using Experimental String Processing library for libswift _RegexParser (${EXPERIMENTAL_STRING_PROCESSING_SOURCE_DIR}).")

add_swift_compiler_module(_RegexParser
  "${LIBSWIFT_REGEX_PARSER_SOURCES}"
  Regex.swift)
