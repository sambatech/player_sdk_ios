#!/bin/sh

if [[ ! -n "${EXECUTABLE_PATH}" ]]; then
	SRCROOT=$(dirname "$0")
	PROJ_NAME="SambaPlayer"
	WRAPPER_NAME="${PROJ_NAME}.framework"
	EXECUTABLE_PATH="${WRAPPER_NAME}/${PROJ_NAME}"
	BUILD_DIR=$(xcodebuild -project "${PROJ_NAME}.xcodeproj" -target "${PROJ_NAME}" -showBuildSettings | grep -E '[ ]BUILD_DIR[ ]?\=' | sed 's/.*\=[ ]//')

	echo "BUILD_DIR = ${BUILD_DIR}"

	if [[ -z "${BUILD_DIR}" || "${BUILD_DIR}" =~ '=' ]]; then
		BUILD_DIR="${SRCROOT}/Build/Products"
		echo "BUILD_DIR (changed) = ${BUILD_DIR}"
	fi
fi

# checking dependency build dir
if [[ ! -d "${BUILD_DIR}" ]]; then
	echo "Warning: No dependency build found, merges won't happen." | tee setup.log
	exit
fi

# checking Carthage build dir
if [[ ! -d "${SRCROOT}/../../../Carthage" ]]; then
	echo "Warning: No Carthage directory found, merges won't happen." | tee setup.log
	exit
fi

mkdir "${SRCROOT}/../../Build" 2> /dev/null
mkdir "${SRCROOT}/../../Build/iOS" 2> /dev/null

# merges lib to reach all archs
echo "merging modules: ${BUILD_DIR}/Release-iphonesimulator/${WRAPPER_NAME}/Modules/ => ${BUILD_DIR}/Release-iphoneos/Build/iOS/${WRAPPER_NAME}/Modules/" | tee setup.log
cp -r "${BUILD_DIR}/Release-iphonesimulator/${WRAPPER_NAME}/Modules/" "${BUILD_DIR}/Release-iphoneos/Build/iOS/${WRAPPER_NAME}/Modules/" 2> | tee -a setup.log

echo "merging archs: ${BUILD_DIR}/Release-iphonesimulator/${EXECUTABLE_PATH} + ${BUILD_DIR}/Release-iphoneos/${EXECUTABLE_PATH} => ${BUILD_DIR}/Release-iphoneos/${EXECUTABLE_PATH}" | tee -a setup.log
lipo -create "${BUILD_DIR}/Release-iphonesimulator/${EXECUTABLE_PATH}" "${BUILD_DIR}/Release-iphoneos/${EXECUTABLE_PATH}" -output "${BUILD_DIR}/Release-iphoneos/${EXECUTABLE_PATH}" 2> | tee -a setup.log

# copies IMA framework to Carthage's build dir
echo "copying IMA: ${SRCROOT}/Frameworks/GoogleInteractiveMediaAds.framework/ => ${SRCROOT}/../../Build/iOS/GoogleInteractiveMediaAds.framework/" | tee -a setup.log
cp -r "${SRCROOT}/Frameworks/GoogleInteractiveMediaAds.framework/" "${SRCROOT}/../../Build/iOS/GoogleInteractiveMediaAds.framework/" 2> | tee -a setup.log
