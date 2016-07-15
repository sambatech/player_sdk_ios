#!/bin/sh

echo "Started merge task at $(date)" | tee -a setup.log

if [[ ! -n "${EXECUTABLE_PATH}" ]]; then
	SRCROOT=$(dirname "$0")
	PROJ_NAME="SambaPlayer"
	WRAPPER_NAME="${PROJ_NAME}.framework"
	EXECUTABLE_PATH="${WRAPPER_NAME}/${PROJ_NAME}"
	BUILD_DIR=$(xcodebuild -project "${PROJ_NAME}.xcodeproj" -target "${PROJ_NAME}" -showBuildSettings | grep -E '[ ]BUILD_DIR[ ]?\=' | sed 's/.*\=[ ]//')

	echo "BUILD_DIR = ${BUILD_DIR}"

	if [[ -z "${BUILD_DIR}" || "${BUILD_DIR}" =~ '=' ]]; then
		BUILD_DIR="${SRCROOT}/Build/Products"
		echo "BUILD_DIR (modified) = ${BUILD_DIR}" | tee -a setup.log
	fi
fi

# checking dependency builds
if [[ ! -f "${BUILD_DIR}/Release-iphoneos/${EXECUTABLE_PATH}" || ! -f "${BUILD_DIR}/Release-iphonesimulator/${EXECUTABLE_PATH}" ]]; then
	echo "Warning: No dependency builds found yet." | tee -a setup.log
	exit
fi

archsCount=$(lipo -info "${BUILD_DIR}/Release-iphoneos/${EXECUTABLE_PATH}" | rev | sed 's/[ ]\:.*//' | rev | sed -E -e 's/i386|arm64|x86_64|armv7/1/g' | grep -o '1' | wc -l 2>> setup.log)

# if binary supported archs are equal or greater than 4, consider already merged
if [[ "${archsCount}" -ge 4 ]]; then
	echo "Already merged, end task." | tee -a setup.log
	exit
fi

# checking Carthage build dir
if [[ ! -d "${SRCROOT}/../../../Carthage" ]]; then
	echo "Warning: No Carthage directory found, merges won't happen." | tee -a setup.log
	exit
fi

mkdir "${SRCROOT}/../../Build" 2> /dev/null
mkdir "${SRCROOT}/../../Build/iOS" 2> /dev/null

# merges modules to reach all archs
echo "merging modules: ${BUILD_DIR}/Release-iphonesimulator/${WRAPPER_NAME}/Modules/ => ${BUILD_DIR}/Release-iphoneos/${WRAPPER_NAME}/Modules/" | tee -a setup.log
cp -r "${BUILD_DIR}/Release-iphonesimulator/${WRAPPER_NAME}/Modules/" "${BUILD_DIR}/Release-iphoneos/${WRAPPER_NAME}/Modules/" 2>&1 | tee -a setup.log

# merges libs to reach all archs
echo "merging archs: ${BUILD_DIR}/Release-iphonesimulator/${EXECUTABLE_PATH} + ${BUILD_DIR}/Release-iphoneos/${EXECUTABLE_PATH} => ${BUILD_DIR}/Release-iphoneos/${EXECUTABLE_PATH}" | tee -a setup.log
lipo -create "${BUILD_DIR}/Release-iphonesimulator/${EXECUTABLE_PATH}" "${BUILD_DIR}/Release-iphoneos/${EXECUTABLE_PATH}" -output "${BUILD_DIR}/Release-iphoneos/${EXECUTABLE_PATH}" 2>> setup.log

# copies IMA framework to Carthage's build dir
echo "copying IMA: ${SRCROOT}/Frameworks/GoogleInteractiveMediaAds.framework => ${SRCROOT}/../../Build/iOS/GoogleInteractiveMediaAds.framework/" | tee -a setup.log
cp -r "${SRCROOT}/Frameworks/GoogleInteractiveMediaAds.framework" "${SRCROOT}/../../Build/iOS/" 2>&1 | tee -a setup.log
