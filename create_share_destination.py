#!/usr/bin/env python3
"""
Create a Final Cut Pro Share Destination (.fcpxdest) for Moplug Send Motion
This script creates a binary plist that FCP uses to register the share destination,
following the structure used by Xsend Motion.
"""

import plistlib
import sys
import uuid

def create_fcpxdest():
    """
    Create .fcpxdest file following Xsend Motion's NSKeyedArchiver structure
    """

    # Generate a unique UUID for this destination
    dest_uuid = str(uuid.uuid4()).upper()

    # NSKeyedArchiver format matching Xsend Motion's structure
    # This tells Final Cut Pro to launch our .app with the FCPXML file
    dest_data = {
        '$archiver': 'NSKeyedArchiver',
        '$version': 100000,
        '$objects': [
            '$null',
            # Root object (index 1)
            {
                '$class': {'CF$UID': 29},
                'exportOption': {'CF$UID': 26},
                'FFShareDestinationVideoResolution': {'CF$UID': 24},
                'includesChapterMarkers': {'CF$UID': 13},
                'jobActionUsesHelperApp': {'CF$UID': 13},
                'name': {'CF$UID': 3},
                'selectedAudioStompSettingName': {'CF$UID': 28},
                'selectedRolePresetName': {'CF$UID': 0},
                'selectedVideoStompSettingName': {'CF$UID': 27},
                'setting': {'CF$UID': 4},
                'storepassword': {'CF$UID': 23},
                'type': {'CF$UID': 2},
                'userHasChangedTheName': {'CF$UID': 23},
                'uuid': {'CF$UID': 25},
            },
            # Strings and values
            'Export Media',  # index 2
            'Moplug Send Motion',  # index 3
            # Setting object (index 4)
            {
                '$class': {'CF$UID': 22},
                'action': {'CF$UID': 16},
                'description': {'CF$UID': 21},
                'name': {'CF$UID': 5},
                'settingsInfo': {'CF$UID': 6},
                'shouldPerformPostProcessingAction': True,
                'version': 1
            },
            'ExportMovieRoles',  # index 5
            # Settings info array (index 6)
            {
                '$class': {'CF$UID': 15},
                'NS.objects': [{'CF$UID': 7}]
            },
            # Settings info dict (index 7)
            {
                '$class': {'CF$UID': 14},
                'NS.keys': [{'CF$UID': 8}, {'CF$UID': 9}],
                'NS.objects': [{'CF$UID': 10}, {'CF$UID': 13}]
            },
            'CKStompSetting',  # index 8
            'CKStompSettingEnabled',  # index 9
            # CKStompSetting object (index 10)
            {
                '$class': {'CF$UID': 12},
                'classVersion': 1,
                'container': {'CF$UID': 0},
                'editable': True,
                'xml': {'CF$UID': 11}
            },
            '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><setting name="Same%20as%20Source"><version>327680</version><description>Export%20a%20movie%20in%20the%20same%20format%20as%20the%20original%20project</description><default-destination></default-destination><nameKey>ExportMovieNameKey</nameKey><descriptionKey>ExportMovieDescKey</descriptionKey><encoder name="EUSSEncoder"><audio-encode isEnabled="no"/><video-encode isEnabled="no"/><audio-video-encode isEnabled="no"/><file-extension>mov</file-extension><job-can-be-segmented>no</job-can-be-segmented><duration-change factor="100" new-duration="" source-at-output="no"/><marker-image width="0" height="0"/><encode-cc>yes</encode-cc><encode-chapters>yes</encode-chapters><family-name>USE_SOURCE_SETTINGS</family-name></encoder><filter-set/></setting>',  # index 11
            # Class definitions
            {'$classes': ['Setting', 'NSObject'], '$classname': 'Setting'},  # index 12
            True,  # index 13 - boolean
            {'$classes': ['NSMutableDictionary', 'NSDictionary', 'NSObject'], '$classname': 'NSMutableDictionary'},  # index 14
            {'$classes': ['NSArray', 'NSObject'], '$classname': 'NSArray'},  # index 15
            # Action object (index 16)
            {
                '$class': {'CF$UID': 20},
                'jobAction': {'CF$UID': 17}
            },
            # Job action (index 17)
            {
                '$class': {'CF$UID': 19},
                'jobAction': {'CF$UID': 18}
            },
            # Job action XML - THIS IS THE KEY PART that points to our app (index 18)
            '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><jobAction kind="open" name="Open" flags="1" job-count="1" default-title="" appName="/Applications/Moplug%20Send%20Motion.app"/>',
            {'$classes': ['OpenJobAction', 'JobAction', 'NSObject'], '$classname': 'OpenJobAction'},  # index 19
            {'$classes': ['CKOpenJobAction', 'CKJobAction', 'CKAction', 'NSObject'], '$classname': 'CKOpenJobAction'},  # index 20
            'Export a movie in the same format as the original project',  # index 21 - description
            {'$classes': ['CKMovieRolesSetting', 'CKSetting', 'NSObject'], '$classname': 'CKMovieRolesSetting'},  # index 22
            False,  # index 23
            '{0, 0}',  # index 24 - video resolution
            dest_uuid,  # index 25 - UUID
            1,  # index 26 - export option
            'Same as Source',  # index 27 - video stomp setting
            'AAC',  # index 28 - audio stomp setting
            {'$classes': ['FFShareExportMediaDestination', 'FFShareDestination', 'NSObject'], '$classname': 'FFShareExportMediaDestination'},  # index 29
        ],
        '$top': {
            'root': {'CF$UID': 1}
        }
    }

    output_path = '/tmp/Moplug-Send-Motion.fcpxdest'

    try:
        # Write as binary plist (same format as Xsend Motion)
        with open(output_path, 'wb') as f:
            plistlib.dump(dest_data, f, fmt=plistlib.FMT_BINARY)

        print(f"✓ Created {output_path}")
        print("\nNext steps:")
        print("1. Build the .app:")
        print("   xcodebuild -project Moplug-Send-Motion.xcodeproj -configuration Release")
        print("\n2. Copy .app to /Applications:")
        print("   sudo cp -R build/Release/Moplug\\ Send\\ Motion.app /Applications/")
        print("\n3. Copy .fcpxdest to share destinations:")
        print("   sudo cp /tmp/Moplug-Send-Motion.fcpxdest '/Library/Application Support/ProApps/Share Destinations/'")
        print("\n4. Restart Final Cut Pro")
        print("\n5. Look for 'Moplug Send Motion' in File > Share menu")

        return 0

    except Exception as e:
        print(f"Error creating .fcpxdest: {e}", file=sys.stderr)
        return 1

if __name__ == '__main__':
    sys.exit(create_fcpxdest())
