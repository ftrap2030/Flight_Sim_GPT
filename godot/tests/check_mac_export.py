"""Check packaging; this cannot establish that the app runs on an M1 Mac."""
import plistlib
import struct
import sys
import zipfile

with zipfile.ZipFile(sys.argv[1]) as archive:
    assert archive.testzip() is None, "Archive CRC check failed"
    names = archive.namelist()
    plist_name = next(name for name in names if name.endswith('/Contents/Info.plist'))
    info = plistlib.loads(archive.read(plist_name))
    assert info['CFBundleIdentifier'] == 'com.ftrap2030.flightsimgpt.miami'
    root = plist_name.removesuffix('Info.plist')
    executable_name = root + 'MacOS/' + info['CFBundleExecutable']
    executable = archive.getinfo(executable_name)
    assert (executable.external_attr >> 16) & 0o111, 'Missing executable permissions'
    binary = archive.read(executable_name)
    magic, count = struct.unpack_from('>II', binary)
    assert magic == 0xCAFEBABE, 'Expected a universal Mach-O binary'
    architectures = [struct.unpack_from('>I', binary, 8 + i * 20)[0] for i in range(count)]
    assert 0x0100000C in architectures, 'Missing Apple Silicon arm64 binary'
    assert 0x01000007 in architectures, 'Missing x86_64 binary'
    packs = [name for name in names if name.endswith('.pck')]
    assert len(packs) == 1, 'Missing or ambiguous project pack'
    assert archive.getinfo(packs[0]).file_size > 1000, 'Project pack is empty'
print('Mac package checks passed: bundle ID, permissions, arm64/x86_64, project pack, CRC')
