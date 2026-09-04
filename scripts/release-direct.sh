#!/bin/zsh

set -euo pipefail

script_dir="${0:A:h}"
project_root="${script_dir:h}"
scheme="ApexUninstaller-Direct"
project="${project_root}/ApexUninstaller.xcodeproj"
export_options="${project_root}/ExportOptions-DeveloperID.plist"
notarize_options="${project_root}/ExportOptions-Notarize.plist"
notary_profile="${NOTARY_KEYCHAIN_PROFILE:-}"

version="${VERSION:-$(xcodebuild -project "${project}" -scheme "${scheme}" -configuration DirectRelease -showBuildSettings | awk '/MARKETING_VERSION =/ { print $3; exit }')}"
if [[ -z "${version}" ]]; then
    print -u2 "Could not determine MARKETING_VERSION."
    exit 2
fi

release_root="${project_root}/build/direct/${version}"
archive_path="${release_root}/ApexUninstaller.xcarchive"
export_path="${release_root}/Export"
artifact_path="${release_root}/ApexUninstaller-${version}.zip"
checksum_path="${artifact_path}.sha256"

if [[ -e "${release_root}" ]]; then
    print -u2 "Release directory already exists: ${release_root}"
    print -u2 "Move it aside before creating another release."
    exit 2
fi

temporary_dir="$(mktemp -d)"
trap 'rm -rf "${temporary_dir}"' EXIT

cd "${project_root}"
xcodegen generate

xcodebuild archive \
    -project "${project}" \
    -scheme "${scheme}" \
    -configuration DirectRelease \
    -archivePath "${archive_path}"

if [[ -n "${notary_profile}" ]]; then
    xcodebuild -exportArchive \
        -archivePath "${archive_path}" \
        -exportPath "${export_path}" \
        -exportOptionsPlist "${export_options}"

    app_path="${export_path}/ApexUninstaller.app"
    codesign --verify --deep --strict --verbose=2 "${app_path}"

    submission_zip="${temporary_dir}/ApexUninstaller-${version}-submission.zip"
    ditto -c -k --sequesterRsrc --keepParent "${app_path}" "${submission_zip}"
    xcrun notarytool submit "${submission_zip}" --keychain-profile "${notary_profile}" --wait
    xcrun stapler staple "${app_path}"
else
    print "NOTARY_KEYCHAIN_PROFILE is not set; using the Apple account signed in to Xcode."
    xcodebuild -exportArchive \
        -archivePath "${archive_path}" \
        -exportPath "${release_root}/NotarizationUpload" \
        -exportOptionsPlist "${notarize_options}" \
        -allowProvisioningUpdates

    app_path="${export_path}/ApexUninstaller.app"
    exported=0
    for attempt in {1..20}; do
        if xcodebuild -exportNotarizedApp -archivePath "${archive_path}" -exportPath "${export_path}"; then
            exported=1
            break
        fi
        print "Notarization is still processing (attempt ${attempt}/20)."
        sleep 30
    done

    if [[ "${exported}" != "1" ]]; then
        print -u2 "Notarization did not finish within 10 minutes."
        print -u2 "Run xcodebuild -exportNotarizedApp for archive: ${archive_path}"
        exit 3
    fi
fi

if [[ ! -d "${app_path}" ]]; then
    print -u2 "Exported app not found: ${app_path}"
    exit 2
fi

codesign --verify --deep --strict --verbose=2 "${app_path}"
xcrun stapler validate "${app_path}"
spctl --assess --type execute --verbose=2 "${app_path}"

ditto -c -k --sequesterRsrc --keepParent "${app_path}" "${artifact_path}"
(
    cd "${release_root}"
    shasum -a 256 "${artifact_path:t}" > "${checksum_path:t}"
)

print "Release artifact: ${artifact_path}"
print "Checksum: ${checksum_path}"

if [[ "${PUBLISH_GITHUB:-0}" == "1" ]]; then
    gh release create "v${version}" \
        "${artifact_path}" \
        "${checksum_path}" \
        --repo "dangvanhai13091989/ApexUninstaller" \
        --title "ApexUninstaller ${version}" \
        --generate-notes
fi
