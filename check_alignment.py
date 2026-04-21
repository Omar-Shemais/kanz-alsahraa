import zipfile
import os

apk_path = r'build\app\outputs\flutter-apk\app-release.apk'

def check_alignment(apk_path):
    if not os.path.exists(apk_path):
        print(f"Error: {apk_path} not found.")
        return

    with open(apk_path, 'rb') as f:
        z = zipfile.ZipFile(f)
        print(f"{'Alignment':<10} {'Path'}")
        print("-" * 50)
        for info in z.infolist():
            if info.filename.endswith('.so'):
                # Header offset in the ZIP
                offset = info.header_offset
                # The data starts after the local header
                # We need to find the actual start of the compressed/stored data
                # A quick way is to read the local header size
                f.seek(offset)
                local_header = f.read(30)
                n = int.from_bytes(local_header[26:28], 'little') # name length
                m = int.from_bytes(local_header[28:30], 'little') # extra length
                data_offset = offset + 30 + n + m
                
                alignment = data_offset % 16384
                print(f"{data_offset:<10} {info.filename} (mod 16384 = {alignment})")

if __name__ == "__main__":
    check_alignment(apk_path)
